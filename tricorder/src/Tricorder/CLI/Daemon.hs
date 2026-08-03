module Tricorder.CLI.Daemon
    ( startDaemon
    , stopDaemon
    , restartDaemon
    , waitForDaemon
    ) where

import Atelier.Effects.Delay (Delay)
import Atelier.Effects.File (File)
import Atelier.Effects.Posix.Daemons (Daemons)
import Atelier.Effects.Timeout (Timeout, timeout)
import Atelier.Time (Millisecond, Second)
import Effectful (IOE)
import Effectful.NonDet (OnEmptyPolicy (..), emptyEff, runNonDet)
import Effectful.Reader.Static (Reader, ask)
import Effectful.Writer.Static.Local (runWriter, tell)
import Prelude hiding (force)

import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.Posix.Daemons qualified as Daemons

import Tricorder.Runtime (PidFile, SocketPath (..))
import Tricorder.Socket.Client (isDaemonReady, isDaemonRunning, requestShutdown)
import Tricorder.Socket.Protocol (Force (..))
import Tricorder.Socket.UnixSocket (UnixSocket)

import Tricorder.Daemon.Main qualified as Daemon.Main


startDaemon
    :: ( Daemons :> es
       , IOE :> es
       , Reader PidFile :> es
       )
    => Eff es ()
startDaemon = do
    pidFile <- ask
    Daemons.daemonize pidFile $ liftIO Daemon.Main.main


-- | Attempts to stop the daemon in progressively more forceful ways.
-- 1. First attempts to make the daemon stop using the API.
-- 2. Then attempts to stop the daemon by sending `SIGKILL` to its process.
stopDaemon
    :: ( Daemons :> es
       , Delay :> es
       , File :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , Timeout :> es
       , UnixSocket :> es
       )
    => Force -> Eff es (Either [Text] Text)
stopDaemon force = do
    SocketPath sockPath <- ask
    pidFile <- ask
    res <-
        runWriter @[Text]
            $ fmap rightToMaybe
            $ runNonDet OnEmptyKeep
            $ requestStop sockPath pidFile
                <|> sendKill pidFile
    case res of
        (Just r, _) -> pure $ Right r
        (Nothing, es) -> pure $ Left es
  where
    timeoutDelay :: Second = case force of
        Force -> 3
        NoForce -> 6
    requestStop sockPath pidFile = do
        timeout1second (requestShutdown force sockPath) >>= \_ -> do
            didStop <- fmap isJust $ timeout timeoutDelay $ waitForStop pidFile
            if didStop then
                pure "Daemon stopped."
            else do
                tell ["Daemon did not stop as requested."]
                emptyEff

    sendKill pidFile = do
        timeout1second (Daemons.forceKillAndWait pidFile) >>= \case
            Nothing -> pure "Daemon stopped with SIGKILL."
            Just ex -> do
                tell ["Daemon did not respond to SIGKILL: " <> show ex]
                emptyEff

    timeout1second = fmap (join . fmap rightToMaybe) . timeout (1 :: Second)

    waitForStop :: forall es'. (Daemons :> es', Delay :> es') => PidFile -> Eff es' ()
    waitForStop pidFile = fix \rec -> do
        running <- Daemons.isRunning pidFile
        if running then do
            Delay.wait (500 :: Millisecond)
            rec
        else
            pure ()


-- | Restart the daemon: stop it (if running) and then start a fresh instance.
-- Returns the outcome of the stop attempt, or 'Nothing' if the daemon was not
-- running. The daemon is started unconditionally afterwards, mirroring the
-- @restart@ subcommand.
restartDaemon
    :: ( Daemons :> es
       , Delay :> es
       , File :> es
       , IOE :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , Timeout :> es
       , UnixSocket :> es
       )
    => Force
    -> Eff es (Maybe (Either [Text] Text))
restartDaemon force = do
    running <- isDaemonRunning
    res <- if running then Just <$> stopDaemon force else pure Nothing
    startDaemon
    pure res


-- | Poll until the daemon binds to the socket, giving up after roughly
-- ten seconds. Returns 'True' once the socket is accepting connections.
--
-- We poll the socket rather than the PID file for two reasons: the daemon
-- writes its PID /before/ it binds the socket (a client connecting in that
-- window gets a "connection refused" error), and right after forking the PID
-- file may not exist yet — so the PID is not a reliable readiness signal either
-- way.
waitForDaemon
    :: ( Delay :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Eff es Bool
waitForDaemon = do
    SocketPath sockPath <- ask
    go sockPath maxAttempts
  where
    -- 50 attempts × 200ms ≈ 10s
    maxAttempts = 50 :: Int
    go _ 0 = pure False
    go sockPath n = do
        ready <- isDaemonReady sockPath
        if ready then
            pure True
        else do
            Delay.wait (200 :: Millisecond)
            go sockPath (n - 1)
