module Tricorder.Socket.Server (main, SocketRemoved (..)) where

import Atelier.Effects.Cache (Cache)
import Atelier.Effects.Conc (Conc)
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
import Tricorder.SourceLookup.SourceQuery (ModuleName, SourceQuery)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Publishing.Sub qualified as Sub
import Data.ByteString.Lazy qualified as BSL
import Effectful.State.Static.Shared qualified as State

import Tricorder.Build (BuildId, BuildPhase, BuildState (..), Diagnostic)
import Tricorder.Daemon.DaemonInfo (DaemonInfo)
import Tricorder.Daemon.IdleTimer (IdleTimer)
import Tricorder.Runtime (SocketPath (..))
import Tricorder.Session.Command (Repl)
import Tricorder.Socket.Protocol
    ( ClientMessage (..)
    , DiagnosticQuery (..)
    , ErrorResponse (..)
    , Query (..)
    , StatusQuery (..)
    )
import Tricorder.Socket.UnixSocket
    ( UnixSocket
    , acceptHandle
    , bindSocket
    , closeHandle
    , readLine
    , removeSocketFile
    , sendLine
    )
import Tricorder.SourceLookup (ModuleSourceResult, lookupModuleSource)
import Tricorder.SourceLookup.GhcPkg (GhcPkg)
import Tricorder.SourceLookup.Hackage (Hackage)
import Tricorder.SourceLookup.PackageId (PackageId)
import Tricorder.SourceLookup.PackageStore (PackageStore)
import Tricorder.Version (VersionMismatch (..), checkVersion)
import Tricorder.Waiters (Waiters)

import Tricorder.Build qualified as Build
import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Test qualified as Test
import Tricorder.Daemon.IdleTimer qualified as IdleTimer
import Tricorder.Socket.Protocol qualified as Protocol
import Tricorder.Waiters qualified as Waiters


data SocketRemoved = SocketRemoved
    deriving stock (Eq, Show)


main
    :: ( Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Conc :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Hackage :> es
       , IdleTimer :> es
       , Input BuildId :> es
       , Input DaemonInfo :> es
       , Input Repl :> es
       , Log :> es
       , PackageStore :> es
       , Reader SocketPath :> es
       , Sub BuildPhase :> es
       , UnixSocket :> es
       , Waiters :> es
       )
    => Eff es Void
main = State.evalState Build.Starting do
    Conc.fork_ $ Sub.listen_ @BuildPhase State.put

    SocketPath sockPath <- ask
    removeSocketFile sockPath
    acceptTrigger


acceptTrigger
    :: ( Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Conc :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Hackage :> es
       , IdleTimer :> es
       , Input BuildId :> es
       , Input DaemonInfo :> es
       , Input Repl :> es
       , Log :> es
       , PackageStore :> es
       , Reader SocketPath :> es
       , State BuildPhase :> es
       , Sub BuildPhase :> es
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
    :: ( Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Conc :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Hackage :> es
       , IdleTimer :> es
       , Input BuildId :> es
       , Input DaemonInfo :> es
       , Input Repl :> es
       , Log :> es
       , PackageStore :> es
       , State BuildPhase :> es
       , Sub BuildPhase :> es
       , UnixSocket :> es
       , Waiters :> es
       )
    => Handle
    -> Eff es ()
handleConnection h = IdleTimer.withActivity do
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
    :: ( Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , Conc :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Hackage :> es
       , Input BuildId :> es
       , Input DaemonInfo :> es
       , Input Repl :> es
       , Log :> es
       , PackageStore :> es
       , State BuildPhase :> es
       , Sub BuildPhase :> es
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
       , State BuildPhase :> es
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
       , State BuildPhase :> es
       , Sub BuildPhase :> es
       , UnixSocket :> es
       )
    => Handle -> Eff es ()
respondWhenDone h = awaitResult >>= mkBuildState >>= sendJson h
  where
    awaitResult = Conc.scoped do
        progressP <- Conc.fork $ Sub.listenUntil_ \case
            failed@(Build.Failed _) -> Just failed
            finished@(Build.Finished _ _) -> Just finished
            _ -> Nothing
        s <- State.get
        waitOrStart progressP s

    waitOrStart p = \case
        finished@(Build.Finished _ _) -> pure finished
        failed@(Build.Failed _) -> pure failed
        _ -> Conc.await p


-- | Stream a JSON object after each state change event.
watchStream
    :: ( Input BuildId :> es
       , Input DaemonInfo :> es
       , State BuildPhase :> es
       , Sub BuildPhase :> es
       , UnixSocket :> es
       )
    => Handle -> Eff es ()
watchStream h = do
    progress0 <- State.get
    mkBuildState progress0 >>= sendJson h
    vacuous $ Sub.listen_ \progress ->
        mkBuildState progress >>= sendJson h


respondDiagnostic :: (State BuildPhase :> es, UnixSocket :> es) => Int -> Handle -> Eff es ()
respondDiagnostic idx h = do
    progress <- State.get
    case progress of
        Build.Finished result postBuild
            | not $ Test.anyRunningTests postBuild.testSuites && Eval.phasePending postBuild.evalComments ->
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
        Build.Failed msg -> sendJson h $ ErrorResponse $ "Build command failed:\n" <> msg
        _ -> sendJson h $ ErrorResponse "Build in progress"


-- | Look up source for each requested module and send the results as a JSON array.
respondSource
    :: ( Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Hackage :> es
       , Input Repl :> es
       , Log :> es
       , PackageStore :> es
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


mkBuildState :: (Input BuildId :> es, Input DaemonInfo :> es) => BuildPhase -> Eff es BuildState
mkBuildState phase = do
    daemonInfo <- input
    buildId <- input
    pure $ BuildState {daemonInfo, buildId, phase}
