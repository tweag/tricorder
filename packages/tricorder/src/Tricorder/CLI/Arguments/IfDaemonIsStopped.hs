module Tricorder.CLI.Arguments.IfDaemonIsStopped (parser) where

import Options.Applicative (Parser, flag, help, long, short)
import Tricorder.CLI.Command.IfDaemonIsStopped (IfDaemonIsStopped (..), startDaemonFlagName)


parser :: Parser IfDaemonIsStopped
parser =
    flag
        Fail
        StartDaemon
        $ long startDaemonFlagName
            <> short 'd'
            <> help "Start the daemon if it is not already running."
