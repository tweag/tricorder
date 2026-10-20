module Tricorder.API.IfDaemonIsStopped.Args (parser) where

import Options.Applicative (Parser, flag, help, long, short)

import Tricorder.API.IfDaemonIsStopped (IfDaemonIsStopped (..), startDaemonFlagName)


parser :: Parser IfDaemonIsStopped
parser =
    flag
        Fail
        StartDaemon
        $ long startDaemonFlagName
            <> short 'd'
            <> help "Start the daemon if it is not already running."
