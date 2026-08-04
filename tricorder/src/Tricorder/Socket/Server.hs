module Tricorder.Socket.Server (main, SocketRemoved (..)) where

import Atelier.Effects.Cache (Cache)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Env (Env)
import Atelier.Effects.Exit (Exit, exitSuccess)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Input (Input, input)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Publishing.Sub (Sub)
import Data.Aeson (ToJSON, decode, encode)
import Effectful.Exception (IOException, finally)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State)
import System.IO (Handle)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Publishing.Sub qualified as Sub
import Data.ByteString.Lazy qualified as BSL
import Effectful.State.Static.Shared qualified as State

import Tricorder.BuildState
    ( BuildId
    , BuildResult (..)
    , Diagnostic
    , PostBuild (..)
    )
import Tricorder.Daemon.BuildState (BuildState (..))
import Tricorder.Daemon.DaemonInfo (DaemonInfo)
import Tricorder.Daemon.Progress (Progress)
import Tricorder.Effects.Cabal (Cabal)
import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.Effects.UnixSocket
    ( UnixSocket
    , acceptHandle
    , bindSocket
    , closeHandle
    , readLine
    , removeSocketFile
    , sendLine
    )
import Tricorder.Effects.Waiters (Waiters)
import Tricorder.GhcPkg.Types (SourceQuery (..))
import Tricorder.Runtime (SocketPath (..))
import Tricorder.Socket.Protocol
    ( ClientMessage (..)
    , DiagnosticQuery (..)
    , ErrorResponse (..)
    , Query (..)
    , StatusQuery (..)
    )
import Tricorder.SourceLookup (ModuleName, ModuleSourceResult, PackageId, lookupModuleSource)
import Tricorder.Version (VersionMismatch (..), checkVersion)

import Tricorder.BuildState.EvalComments qualified as Eval
import Tricorder.BuildState.Test qualified as Test
import Tricorder.Daemon.Progress qualified as Progress
import Tricorder.Effects.Waiters qualified as Waiters
import Tricorder.Socket.Protocol qualified as Protocol


data SocketRemoved = SocketRemoved
    deriving stock (Eq, Show)


main
    :: ( Cabal :> es
       , Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Conc :> es
       , Env :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Input BuildId :> es
       , Input DaemonInfo :> es
       , Log :> es
       , Reader SocketPath :> es
       , Sub Progress :> es
       , UnixSocket :> es
       , Waiters :> es
       )
    => Eff es Void
main = State.evalState Progress.Starting do
    Conc.fork_ $ Sub.listen_ @Progress State.put

    SocketPath sockPath <- ask
    removeSocketFile sockPath
    acceptTrigger


acceptTrigger
    :: ( Cabal :> es
       , Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Conc :> es
       , Env :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Input BuildId :> es
       , Input DaemonInfo :> es
       , Log :> es
       , Reader SocketPath :> es
       , State Progress :> es
       , Sub Progress :> es
       , UnixSocket :> es
       , Waiters :> es
       )
    => Eff es Void
acceptTrigger = do
    SocketPath sockPath <- ask
    sock <- bindSocket sockPath
    forever do
        h <- acceptHandle sock
        void $ Conc.forkTry @IOException do
            handleConnection h `finally` closeHandle h


handleConnection
    :: ( Cabal :> es
       , Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Conc :> es
       , Env :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Input BuildId :> es
       , Input DaemonInfo :> es
       , Log :> es
       , State Progress :> es
       , Sub Progress :> es
       , UnixSocket :> es
       , Waiters :> es
       )
    => Handle
    -> Eff es ()
handleConnection h = do
    line <- readLine h
    case decode (BSL.fromStrict (encodeUtf8 line)) of
        Nothing -> sendJson h (ErrorResponse "invalid request")
        Just ClientMessage {clientVersion, payload} -> do
            let result = checkVersion clientVersion
            case result of
                Left VersionMismatch {expected, received} -> do
                    Log.warn $ "Version mismatch: server=" <> expected <> " client=" <> received
                    dispatch payload h
                Right () -> dispatch payload h


dispatch
    :: ( Cabal :> es
       , Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Conc :> es
       , Env :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Input BuildId :> es
       , Input DaemonInfo :> es
       , Log :> es
       , State Progress :> es
       , Sub Progress :> es
       , UnixSocket :> es
       , Waiters :> es
       )
    => Query
    -> Handle
    -> Eff es ()
dispatch query h = case query of
    Status (StatusQuery False) -> respondOnce h
    Status (StatusQuery True) -> respondWhenDone h
    Watch -> watchStream h
    Source moduleNames -> respondSource moduleNames h
    DiagnosticAt dq -> respondDiagnostic dq.index h
    Quit waiters -> quit h waiters


quit
    :: ( Exit :> es
       , Log :> es
       , UnixSocket :> es
       , Waiters :> es
       )
    => Handle -> Protocol.Waiters -> Eff es ()
quit h = \case
    Protocol.WaitForWaiters -> Waiters.wait doQuit
    Protocol.IgnoreWaiters -> doQuit
  where
    doQuit = do
        sendJson h True
        Log.info "Shutting down."
        exitSuccess


respondOnce
    :: ( Input BuildId :> es
       , Input DaemonInfo :> es
       , State Progress :> es
       , UnixSocket :> es
       )
    => Handle -> Eff es ()
respondOnce h = do
    progress <- State.get
    mkBuildState progress >>= sendJson h


respondWhenDone
    :: ( Conc :> es
       , Input BuildId :> es
       , Input DaemonInfo :> es
       , State Progress :> es
       , Sub Progress :> es
       , UnixSocket :> es
       )
    => Handle -> Eff es ()
respondWhenDone h = awaitResult >>= mkBuildState >>= sendJson h
  where
    awaitResult = Conc.scoped do
        progressP <- Conc.fork $ Sub.listenUntil_ \case
            failed@(Progress.Failed _) -> Just failed
            finished@(Progress.Finished _ _) -> Just finished
            _ -> Nothing
        s <- State.get
        waitOrStart progressP s

    waitOrStart p = \case
        finished@(Progress.Finished _ _) -> pure finished
        failed@(Progress.Failed _) -> pure failed
        _ -> Conc.await p


-- | Stream a JSON object after each state change event.
watchStream
    :: ( Input BuildId :> es
       , Input DaemonInfo :> es
       , State Progress :> es
       , Sub Progress :> es
       , UnixSocket :> es
       )
    => Handle -> Eff es ()
watchStream h = do
    progress0 <- State.get
    mkBuildState progress0 >>= sendJson h
    vacuous $ Sub.listen_ \progress ->
        mkBuildState progress >>= sendJson h


respondDiagnostic :: (State Progress :> es, UnixSocket :> es) => Int -> Handle -> Eff es ()
respondDiagnostic idx h = do
    progress <- State.get
    case progress of
        Progress.Finished result postBuild
            | not $ Test.anyRunningTests postBuild.testSuites && Eval.anyRunningComments postBuild.evalComments ->
                case result.diagnostics !!? (idx - 1) of
                    Nothing ->
                        sendJson h
                            $ ErrorResponse
                            $ "No diagnostic #"
                                <> show idx
                                <> " (current build has "
                                <> show (length result.diagnostics)
                                <> ")"
                    Just d -> sendJson h (d :: Diagnostic)
            | otherwise -> sendJson h $ ErrorResponse "Build in progress"
        Progress.Failed msg -> sendJson h $ ErrorResponse $ "Build command failed:\n" <> msg
        _ -> sendJson h $ ErrorResponse "Build in progress"


-- | Look up source for each requested module and send the results as a JSON array.
respondSource
    :: ( Cabal :> es
       , Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Env :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       , UnixSocket :> es
       )
    => [SourceQuery]
    -> Handle
    -> Eff es ()
respondSource queries h = do
    results <- mapM lookupModuleSource queries
    sendJson h results


sendJson :: (ToJSON a, UnixSocket :> es) => Handle -> a -> Eff es ()
sendJson h val = sendLine h (decodeUtf8 (BSL.toStrict (encode val)))


mkBuildState :: (Input BuildId :> es, Input DaemonInfo :> es) => Progress -> Eff es BuildState
mkBuildState progress = do
    daemonInfo <- input
    buildId <- input
    pure $ BuildState {daemonInfo, buildId, progress}
