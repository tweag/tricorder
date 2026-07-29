module Tricorder (run) where

import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Console (Console)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Exit (Exit)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Posix.Daemons (Daemons)
import Atelier.Effects.Process (Process)
import Atelier.Effects.Timeout (Timeout)
import Effectful (IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Reader.Static (Reader, ask, asks)
import Prelude hiding (force)

import Atelier.Effects.Console qualified as Console
import Data.Text qualified as T

import Tricorder.Arguments (Command (..), LogMode (..))
import Tricorder.CLI (showLog, showSource, showStatus, showTests)
import Tricorder.Daemon (restartDaemon, startDaemon, stopDaemon, waitForDaemon)
import Tricorder.Daemon.BuildState (BuildState (..))
import Tricorder.Daemon.DaemonInfo (DaemonInfo (..))
import Tricorder.Effects.Brick (Brick)
import Tricorder.Effects.BrickChan (BrickChan)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.Runtime (LogPath (..), PidFile (..), SocketPath (..))
import Tricorder.Socket.Client (isDaemonRunning, queryStatus)
import Tricorder.UI (viewUi)

import Tricorder.UI.Keys qualified as Keys


run
    :: ( Brick :> es
       , BrickChan :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Console :> es
       , Daemons :> es
       , Delay :> es
       , Exit :> es
       , File :> es
       , FileSystem :> es
       , IOE :> es
       , Process :> es
       , Reader Command :> es
       , Reader Keys.Config :> es
       , Reader LogPath :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , Timeout :> es
       , UnixSocket :> es
       )
    => Eff es ()
run =
    ask >>= \case
        Start -> do
            running <- isDaemonRunning
            if running then
                Console.putStrLn "Daemon already running."
            else do
                startDaemon
                ready <- waitForDaemon
                if ready then
                    Console.putStrLn "Daemon started."
                else
                    Console.putStrLn "Daemon started, but the socket is not responding yet."
        Stop force -> do
            running <- isDaemonRunning
            when running
                $ stopDaemon force >>= \case
                    Left reasons ->
                        Console.putTextLn
                            $ T.intercalate "\n"
                            $ "Was unable to stop the daemon:" : reasons
                    Right result -> do
                        Console.putTextLn result
        Status opts -> do
            running <- isDaemonRunning
            if not running then
                Console.putStrLn "Stopped."
            else
                showStatus opts
        Test opts -> do
            running <- isDaemonRunning
            if not running then
                Console.putStrLn "Stopped."
            else
                showTests opts
        Log logMode -> do
            running <- isDaemonRunning
            logFile <-
                if running then do
                    SocketPath sp <- ask
                    result <- queryStatus sp
                    LogPath fallback <- ask
                    pure $ case result of
                        Right state -> state.daemonInfo.logFile
                        Left _ -> fallback
                else
                    asks @LogPath (.getLogPath)
            case logMode of
                ShowLog followMode -> showLog logFile followMode
                ShowLogPath -> Console.putTextLn (toText logFile)
        UI -> do
            running <- isDaemonRunning
            unless running do
                startDaemon
                void waitForDaemon
            viewUi
        Source moduleNames -> do
            running <- isDaemonRunning
            unless running $ do
                startDaemon
                void waitForDaemon
            showSource moduleNames
        Restart force ->
            restartDaemon force >>= \case
                Just (Left reasons) -> traverse_ Console.putTextLn reasons
                _ -> pass
