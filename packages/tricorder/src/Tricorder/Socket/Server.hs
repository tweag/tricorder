module Tricorder.Socket.Server (main, SocketRemoved (..)) where

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Exit (Exit)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Input (Input, input)
import Atelier.Effects.Log (Log)
import Atelier.Effects.PubSub.Sub (Sub)
import Data.Aeson (ToJSON, decode, encode)
import Effectful.Exception (IOException, finally, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State)
import System.IO (Handle)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Exit qualified as Exit
import Atelier.Effects.File qualified as File
import Atelier.Effects.FileSystem qualified as FileSystem
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.PubSub.Sub qualified as Sub
import Data.ByteString.Lazy qualified as BSL
import Effectful.State.Static.Shared qualified as State

import Tricorder.Build (BuildId, BuildPhase, BuildState (..), Diagnostic)
import Tricorder.Daemon.IdleTimer (IdleTimer)
import Tricorder.Runtime.SocketPath (SocketPath (..))
import Tricorder.Socket.Protocol
    ( ClientMessage (..)
    , DiagnosticQuery (..)
    , ErrorResponse (..)
    , Query (..)
    , StatusQuery (..)
    )
import Tricorder.Socket.UnixSocket (UnixSocket)
import Tricorder.Version (VersionMismatch (..), checkVersion)
import Tricorder.Waiters (Waiters)

import Tricorder.Build qualified as Build
import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Test qualified as Test
import Tricorder.Daemon.IdleTimer qualified as IdleTimer
import Tricorder.Socket.Protocol qualified as Protocol
import Tricorder.Socket.UnixSocket qualified as UnixSocket
import Tricorder.Waiters qualified as Waiters


data SocketRemoved = SocketRemoved
    deriving stock (Eq, Show)


main
    :: ( Conc :> es
       , Exit :> es
       , File :> es
       , FileSystem :> es
       , IdleTimer :> es
       , Input BuildId :> es
       , Log :> es
       , Reader SocketPath :> es
       , Sub BuildPhase :> es
       , UnixSocket :> es
       , Waiters :> es
       )
    => Eff es Void
main = State.evalState Build.Starting do
    Conc.fork_ $ Sub.listen_ @BuildPhase State.put

    SocketPath sockPath <- ask
    void $ trySync $ FileSystem.removeFile sockPath
    acceptTrigger


acceptTrigger
    :: ( Conc :> es
       , Exit :> es
       , File :> es
       , IdleTimer :> es
       , Input BuildId :> es
       , Log :> es
       , Reader SocketPath :> es
       , State BuildPhase :> es
       , Sub BuildPhase :> es
       , UnixSocket :> es
       , Waiters :> es
       )
    => Eff es Void
acceptTrigger = do
    SocketPath sockPath <- ask
    sock <- UnixSocket.bind sockPath
    forever do
        h <- UnixSocket.accept sock
        void $ Conc.forkTry @IOException do
            handleConnection h `finally` File.hClose h


handleConnection
    :: ( Conc :> es
       , Exit :> es
       , File :> es
       , IdleTimer :> es
       , Input BuildId :> es
       , Log :> es
       , State BuildPhase :> es
       , Sub BuildPhase :> es
       , Waiters :> es
       )
    => Handle
    -> Eff es ()
handleConnection h = IdleTimer.withActivity do
    line <- File.hGetLine h
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
    :: ( Conc :> es
       , Exit :> es
       , File :> es
       , Input BuildId :> es
       , Log :> es
       , State BuildPhase :> es
       , Sub BuildPhase :> es
       , Waiters :> es
       )
    => Query
    -> Handle
    -> Eff es ()
dispatch query h = case query of
    Status (StatusQuery False) -> respondOnce h
    Status (StatusQuery True) -> respondWhenDone h
    Watch -> watchStream h
    DiagnosticAt dq -> respondDiagnostic dq.index h
    Quit waiters -> quit h waiters


quit
    :: ( Exit :> es
       , File :> es
       , Log :> es
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
        Exit.success


respondOnce
    :: ( File :> es
       , Input BuildId :> es
       , State BuildPhase :> es
       )
    => Handle -> Eff es ()
respondOnce h = do
    progress <- State.get
    mkBuildState progress >>= sendJson h


respondWhenDone
    :: ( Conc :> es
       , File :> es
       , Input BuildId :> es
       , State BuildPhase :> es
       , Sub BuildPhase :> es
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
    :: ( File :> es
       , Input BuildId :> es
       , State BuildPhase :> es
       , Sub BuildPhase :> es
       )
    => Handle -> Eff es ()
watchStream h = do
    progress0 <- State.get
    mkBuildState progress0 >>= sendJson h
    vacuous $ Sub.listen_ \progress ->
        mkBuildState progress >>= sendJson h


respondDiagnostic :: (File :> es, State BuildPhase :> es) => Int -> Handle -> Eff es ()
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


sendJson :: (File :> es, ToJSON a) => Handle -> a -> Eff es ()
sendJson h val = File.hPutTextLn h (decodeUtf8 (BSL.toStrict (encode val))) >> File.hFlush h


mkBuildState :: (Input BuildId :> es) => BuildPhase -> Eff es BuildState
mkBuildState phase = do
    buildId <- input
    pure $ BuildState {buildId, phase}
