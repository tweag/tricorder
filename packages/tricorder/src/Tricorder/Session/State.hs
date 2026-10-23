module Tricorder.Session.State
    ( State
    , currentSession
    , withSession
    , asInput
    , eval
    )
where

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.FileWatcher (FileWatcher)
import Atelier.Effects.Input (Input)
import Atelier.Effects.Log (Log)
import Atelier.Effects.PubSub.Pub (Pub)
import Atelier.Effects.PubSub.Sub (Sub)
import Effectful (Effect, Limit (..), Persistence (..), UnliftStrategy (..), inject)
import Effectful.Concurrent.STM (Concurrent, TVar)
import Effectful.Dispatch.Dynamic (interpretWith, localUnlift)
import Effectful.Reader.Static (Reader)
import Effectful.TH (makeEffect)
import System.FilePath ((</>))

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.FileSystem qualified as FileSystem
import Atelier.Effects.FileWatcher qualified as FileWatcher
import Atelier.Effects.FileWatcher.Watch qualified as Watch
import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.PubSub qualified as PubSub
import Atelier.Effects.PubSub.Pub qualified as Pub
import Atelier.Effects.PubSub.Sub qualified as Sub
import Data.List qualified as List
import Data.Text qualified as T
import Effectful.Concurrent.STM qualified as STM
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.CabalFile (CabalFile)
import Tricorder.Session.State.Invalid (Invalid (..))
import Tricorder.Session.State.Result (Result)
import Tricorder.Session.Util (indent)
import Tricorder.Waiters (Waiters)

import Tricorder.Config qualified as Tricorder
import Tricorder.Config.LoadedConfig qualified as LoadedConfig
import Tricorder.Session qualified as Session
import Tricorder.Session.State.Result qualified as Result
import Tricorder.Waiters qualified as Waiters


data State :: Effect where
    -- | Returns the current session record.
    CurrentSession :: State m Result
    -- | Cancels and reruns the passed action with a new session every time the
    -- session record changes.
    WithSession :: (Result -> m a) -> State m Void


makeEffect ''State


asInput :: (State :> es) => Eff (Input Result : es) a -> Eff es a
asInput = Input.withEff currentSession


eval
    :: ( Chan :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce FilePath :> es
       , FileSystem :> es
       , FileWatcher :> es
       , Input (Either Text Tricorder.Config) :> es
       , Input [CabalFile] :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , Waiters :> es
       )
    => Eff (State : es) a -> Eff es a
eval action = PubSub.run @Reloaded $ PubSub.run @Reload do
    session0 <- Result.fromEither <$> Session.load

    logSession session0
    var <- STM.newTVarIO session0
    Conc.fork_ watchConfigFile
    conditionallyWatchStackYaml
    Conc.fork_ $ Sub.listen_ @Reload $ const $ updateSession var
    interpretWith (inject action) \env -> \case
        CurrentSession -> STM.readTVarIO var
        WithSession act -> do
            localUnlift env (ConcUnlift Persistent Unlimited) \unlift ->
                Conc.restartableFork waitForReloadedSession do
                    unlift . act =<< STM.readTVarIO var


waitForReloadedSession :: (Sub Reloaded :> es, Waiters :> es) => Eff es Reloaded
waitForReloadedSession = Waiters.wait $ Sub.listenOnce_ @Reloaded


updateSession
    :: ( Concurrent :> es
       , FileSystem :> es
       , Input (Either Text Tricorder.Config) :> es
       , Input [CabalFile] :> es
       , Log :> es
       , Pub Reloaded :> es
       , Reader ProjectRoot :> es
       )
    => TVar Result -> Eff es ()
updateSession var = do
    oldSession <- STM.readTVarIO var
    newSession <- Result.fromEither <$> Session.load
    when (oldSession /= newSession) do
        STM.atomically $ STM.writeTVar var newSession
        logSession newSession
        Pub.publish Reloaded


data Reload = Reload


data Reloaded = Reloaded


watchConfigFile
    :: ( Debounce FilePath :> es
       , FileWatcher :> es
       , Pub Reload :> es
       , Reader ProjectRoot :> es
       )
    => Eff es Void
watchConfigFile = do
    root <- Reader.ask
    FileWatcher.watchFilePathsDebounced
        [Watch.dirWhere root.getProjectRoot (LoadedConfig.configFileName `List.isSuffixOf`)]
        \_ _ -> Pub.publish Reload


conditionallyWatchStackYaml
    :: ( Conc :> es
       , Debounce FilePath :> es
       , FileSystem :> es
       , FileWatcher :> es
       , Pub Reload :> es
       , Reader ProjectRoot :> es
       )
    => Eff es ()
conditionallyWatchStackYaml = do
    root <- Reader.ask
    exists <- FileSystem.doesFileExist $ root.getProjectRoot </> "stack.yaml"
    when exists do
        Conc.fork_ $ FileWatcher.watchFilePathsDebounced
            [Watch.dirWhere root.getProjectRoot ("stack.yaml" `List.isSuffixOf`)]
            \_ _ -> Pub.publish Reload


logSession :: (Log :> es) => Result -> Eff es ()
logSession = \case
    Result.Invalid invalid ->
        Log.err
            $ T.intercalate
                "\n"
                [ "Invalid session:"
                , indent $ "reason: " <> invalid.reason
                , indent $ "fallback:"
                , indent $ indent $ Session.display invalid.fallback
                ]
    Result.Ok session ->
        Log.info . (<> "\n") $ Session.display session
