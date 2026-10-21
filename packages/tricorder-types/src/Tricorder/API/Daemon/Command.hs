module Tricorder.API.Daemon.Command (Command (..), toArgs) where

import Tricorder.API.Force (Force)
import Tricorder.API.OutputFormat (OutputFormat)

import Tricorder.API.Force qualified as Force
import Tricorder.API.OutputFormat qualified as OutputFormat


data Command
    = Start
    | Stop Force
    | Restart Force
    | Info OutputFormat


toArgs :: Command -> [String]
toArgs = \case
    Start -> ["start"]
    Stop force' -> "stop" : Force.toArgs force'
    Restart force' -> "restart" : Force.toArgs force'
    Info format -> "info" : OutputFormat.toArgs format
