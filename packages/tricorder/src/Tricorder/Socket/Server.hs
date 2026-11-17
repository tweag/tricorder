module Tricorder.Socket.Server (main, SocketRemoved (..)) where

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Exit (Exit)
import Atelier.Effects.Handles (Handles)
import Atelier.Effects.Input (Input, input)
import Atelier.Effects.Log (Log)
import Atelier.Effects.PubSub.Sub (Sub)
import Data.Aeson (ToJSON, decode, encode)
import Effectful.Exception (IOException, finally, trySync)
import Effectful.FileSystem (FileSystem)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State)
import System.IO (Handle)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Exit qualified as Exit
import Atelier.Effects.Handles qualified as Handles
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.PubSub.Sub qualified as Sub
import Atelier.FileSystem.File qualified as File
import Data.ByteString.Lazy qualified as BSL
import Effectful.State.Static.Shared qualified as State

import Tricorder.Build.PostBuild (PostBuild (..))
import Tricorder.Build.Result (Result (..))
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

import Tricorder.Build.Diagnostic qualified as Build (Diagnostic)
import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Id qualified as Build (Id)
import Tricorder.Build.Phase qualified as Build (Phase)
import Tricorder.Build.Phase qualified as Build.Phase
import Tricorder.Build.State qualified as Build (State (..))
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
       , FileSystem :> es
       , Handles :> es
       , IdleTimer :> es
       , Input Build.Id :> es
       , Log :> es
       , Reader SocketPath :> es
       , Sub Build.Phase :> es
       , UnixSocket :> es
       , Waiters :> es
       )
    => Eff es Void
main = State.evalState Build.Phase.Starting do
    Conc.fork_ $ Sub.listen_ @Build.Phase State.put

    SocketPath sockPath <- ask
    void $ trySync $ File.remove sockPath
    acceptTrigger


acceptTrigger
    :: ( Conc :> es
       , Exit :> es
       , Handles :> es
       , IdleTimer :> es
       , Input Build.Id :> es
       , Log :> es
       , Reader SocketPath :> es
       , State Build.Phase :> es
       , Sub Build.Phase :> es
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
            handleConnection h `finally` Handles.hClose h


handleConnection
    :: ( Conc :> es
       , Exit :> es
       , Handles :> es
       , IdleTimer :> es
       , Input Build.Id :> es
       , Log :> es
       , State Build.Phase :> es
       , Sub Build.Phase :> es
       , Waiters :> es
       )
    => Handle
    -> Eff es ()
handleConnection h = IdleTimer.withActivity do
    line <- Handles.hGetLine h
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
       , Handles :> es
       , Input Build.Id :> es
       , Log :> es
       , State Build.Phase :> es
       , Sub Build.Phase :> es
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
       , Handles :> es
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
    :: ( Handles :> es
       , Input Build.Id :> es
       , State Build.Phase :> es
       )
    => Handle -> Eff es ()
respondOnce h = do
    progress <- State.get
    mkBuildState progress >>= sendJson h


respondWhenDone
    :: ( Conc :> es
       , Handles :> es
       , Input Build.Id :> es
       , State Build.Phase :> es
       , Sub Build.Phase :> es
       )
    => Handle -> Eff es ()
respondWhenDone h = awaitResult >>= mkBuildState >>= sendJson h
  where
    awaitResult = Conc.scoped do
        progressP <- Conc.fork $ Sub.listenUntil_ \case
            failed@(Build.Phase.Failed _) -> Just failed
            finished@(Build.Phase.Finished _ _) -> Just finished
            _ -> Nothing
        s <- State.get
        waitOrStart progressP s

    waitOrStart p = \case
        finished@(Build.Phase.Finished _ _) -> pure finished
        failed@(Build.Phase.Failed _) -> pure failed
        _ -> Conc.await p


-- | Stream a JSON object after each state change event.
watchStream
    :: ( Handles :> es
       , Input Build.Id :> es
       , State Build.Phase :> es
       , Sub Build.Phase :> es
       )
    => Handle -> Eff es ()
watchStream h = do
    progress0 <- State.get
    mkBuildState progress0 >>= sendJson h
    vacuous $ Sub.listen_ \progress ->
        mkBuildState progress >>= sendJson h


respondDiagnostic :: (Handles :> es, State Build.Phase :> es) => Int -> Handle -> Eff es ()
respondDiagnostic idx h = do
    progress <- State.get
    case progress of
        Build.Phase.Finished result postBuild
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
                    Just d -> sendJson h (d :: Build.Diagnostic)
            | otherwise -> sendJson h $ ErrorResponse "Build in progress"
        Build.Phase.Failed msg -> sendJson h $ ErrorResponse $ "Build command failed:\n" <> msg
        _ -> sendJson h $ ErrorResponse "Build in progress"


sendJson :: (Handles :> es, ToJSON a) => Handle -> a -> Eff es ()
sendJson h val = Handles.hPutTextLn h (decodeUtf8 (BSL.toStrict (encode val))) >> Handles.hFlush h


mkBuildState :: (Input Build.Id :> es) => Build.Phase -> Eff es Build.State
mkBuildState phase = do
    buildId <- input
    pure $ Build.State {buildId, phase}
