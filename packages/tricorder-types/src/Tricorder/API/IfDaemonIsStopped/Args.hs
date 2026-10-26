module Tricorder.API.IfDaemonIsStopped.Args (parser) where

import Options.Applicative (Parser, help, long)

import Atelier.Effects.Arguments.Switch qualified as Switch

import Tricorder.API.IfDaemonIsStopped
    ( IfDaemonIsStopped (..)
    , doNothingFlagName
    )


parser :: Parser IfDaemonIsStopped
parser =
    fmap (bool StartDaemon DoNothing)
        $ Switch.parser
        $ long doNothingFlagName
            <> help
                "Normally, the daemon will be started if it is not already running. This flag prevents that, and instead will make Tricorder produce an error if the daemon is not running."
