module Tricorder.CLI.App.Daemon (run) where

import Atelier.Effects.Console (Console)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.File (File)
import Atelier.Effects.Input (Input, input)
import Atelier.Effects.Posix.Daemons (Daemons)
import Atelier.Effects.Timeout (Timeout)
import Effectful (IOE)
import Effectful.Reader.Static (Reader)
import Tricorder.API.Daemon.Command (Command (..))
import Prelude hiding (force)

import Atelier.Effects.Console qualified as Console
import Data.Text qualified as T

import Tricorder.CLI.Daemon (restartDaemon, startDaemon, stopDaemon, waitForDaemon)
import Tricorder.CLI.Operations (showDaemonInfo)
import Tricorder.Daemon.DaemonInfo (DaemonInfo)
import Tricorder.Runtime.PidFile (PidFile)
import Tricorder.Runtime.SocketPath (SocketPath)
import Tricorder.Socket.Client (isDaemonRunning)
import Tricorder.Socket.UnixSocket (UnixSocket)


run
    :: ( Console :> es
       , Daemons :> es
       , Delay :> es
       , File :> es
       , IOE :> es
       , Input DaemonInfo :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , Timeout :> es
       , UnixSocket :> es
       )
    => Command -> Eff es ()
run = \case
    Start -> do
        running <- isDaemonRunning
        if running
            then
                Console.putStrLn "Daemon already running."
            else do
                startDaemon
                ready <- waitForDaemon
                if ready
                    then
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
    Restart force ->
        restartDaemon force >>= \case
            Just (Left reasons) -> traverse_ Console.putTextLn reasons
            _ -> pass
    Info format -> do
        daemonInfo <- input
        showDaemonInfo format daemonInfo
