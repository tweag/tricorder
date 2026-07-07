module Tricorder.Socket.Server (component, SocketRemoved (..)) where

import Atelier.Component (Component (..), Trigger, defaultComponent)
import Atelier.Effects.Cache (Cache)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay, wait)
import Atelier.Effects.Env (Env)
import Atelier.Effects.Exit (Exit, exitSuccess)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Log (Log)
import Atelier.Time (Millisecond)
import Data.Aeson (ToJSON, decode, encode)
import Effectful.Exception (IOException, finally)
import Effectful.Reader.Static (Reader, ask)
import System.IO (Handle)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Log qualified as Log
import Data.ByteString.Lazy qualified as BSL

import Tricorder.BuildState
    ( BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , Diagnostic
    , PostBuild (..)
    )
import Tricorder.Effects.BuildStore (BuildStore, getState, waitForAnyChange, waitUntilDone)
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
import Tricorder.GhcPkg.Types (SourceQuery (..))
import Tricorder.Runtime (SocketPath (..))
import Tricorder.Socket.Protocol
    ( ClientMessage (..)
    , DiagnosticQuery (..)
    , ErrorResponse (..)
    , Query (..)
    , StatusQuery (..)
    , Waiters (..)
    )
import Tricorder.SourceLookup (ModuleName, ModuleSourceResult, PackageId, lookupModuleSource)
import Tricorder.Version (VersionMismatch (..), checkVersion)

import Tricorder.BuildState.Tests qualified as Test
import Tricorder.Effects.BuildStore qualified as BuildStore


data SocketRemoved = SocketRemoved
    deriving stock (Eq, Show)
    deriving anyclass (Exception)


-- | SocketServer component.
-- Listens on a Unix socket and responds to status/watch/source queries.
component
    :: ( BuildStore :> es
       , Cabal :> es
       , Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Conc :> es
       , Delay :> es
       , Env :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Component es
component =
    defaultComponent
        { name = "SocketServer"
        , setup = do
            SocketPath sockPath <- ask
            removeSocketFile sockPath
        , triggers = pure [acceptTrigger]
        }


acceptTrigger
    :: ( BuildStore :> es
       , Cabal :> es
       , Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Conc :> es
       , Delay :> es
       , Env :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Trigger es
acceptTrigger = do
    SocketPath sockPath <- ask
    sock <- bindSocket sockPath
    forever do
        h <- acceptHandle sock
        void $ Conc.forkTry @IOException do
            handleConnection h `finally` closeHandle h


handleConnection
    :: ( BuildStore :> es
       , Cabal :> es
       , Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Delay :> es
       , Env :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       , UnixSocket :> es
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
    :: ( BuildStore :> es
       , Cabal :> es
       , Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Delay :> es
       , Env :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       , UnixSocket :> es
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
    :: ( BuildStore :> es
       , Delay :> es
       , Exit :> es
       , Log :> es
       , UnixSocket :> es
       )
    => Handle -> Waiters -> Eff es ()
quit h = \case
    WaitForWaiters -> waitBeforeQuit
    IgnoreWaiters -> doQuit
  where
    doQuit = do
        sendJson h True
        Log.info "Shutting down."
        exitSuccess

    waitBeforeQuit = do
        hasWaiters <- BuildStore.hasWaiters
        if hasWaiters then do
            wait (500 :: Millisecond)
            waitBeforeQuit
        else
            doQuit


respondOnce :: (BuildStore :> es, UnixSocket :> es) => Handle -> Eff es ()
respondOnce h = getState >>= sendJson h


-- | Wait for a completed build, then respond.
--
-- If the build is already done when this is called, we may be racing the file
-- watcher's debounce: a file was just changed but the reload hasn't been
-- dispatched yet (default debounce is 100ms). Poll for up to 250ms to let
-- any in-flight debounce fire before falling back to the current result.
respondWhenDone :: (BuildStore :> es, Delay :> es, UnixSocket :> es) => Handle -> Eff es ()
respondWhenDone h = awaitResult >>= sendJson h
  where
    awaitResult = do
        s <- getState
        case s.phase of
            Building _ -> waitUntilDone
            Restarting -> waitUntilDone
            BuildComplete _ pb
                | Test.anyRunningTests pb.testSuites -> waitUntilDone
                | otherwise -> awaitBuildStart (5 :: Int) s
            BuildFailed _ -> pure s

    -- Poll up to n × 50ms for a build to start, then wait for it to finish.
    awaitBuildStart 0 s = pure s
    awaitBuildStart n _ = do
        wait (50 :: Millisecond)
        s' <- getState
        case s'.phase of
            Building _ -> waitUntilDone
            Restarting -> waitUntilDone
            BuildComplete _ pb
                | Test.anyRunningTests pb.testSuites -> waitUntilDone
                | otherwise -> awaitBuildStart (n - 1) s'
            BuildFailed _ -> pure s'


-- | Stream a JSON object after each state change (loops until handle closes or error).
watchStream :: (BuildStore :> es, UnixSocket :> es) => Handle -> Eff es ()
watchStream h = do
    state0 <- getState
    sendJson h state0
    loop state0
  where
    loop prev = do
        newState <- waitForAnyChange prev
        sendJson h newState
        loop newState


respondDiagnostic :: (BuildStore :> es, UnixSocket :> es) => Int -> Handle -> Eff es ()
respondDiagnostic idx h = do
    state <- getState
    case state.phase of
        BuildComplete r pb
            | not $ Test.anyRunningTests pb.testSuites -> case r.diagnostics !!? (idx - 1) of
                Nothing ->
                    sendJson h
                        $ ErrorResponse
                        $ "No diagnostic #"
                            <> show idx
                            <> " (current build has "
                            <> show (length r.diagnostics)
                            <> ")"
                Just d -> sendJson h (d :: Diagnostic)
            | otherwise -> sendJson h $ ErrorResponse "Build in progress"
        BuildFailed msg -> sendJson h $ ErrorResponse $ "Build command failed:\n" <> msg
        Building _ -> sendJson h $ ErrorResponse "Build in progress"
        Restarting -> sendJson h $ ErrorResponse "Build in progress"


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
