module Tricorder.API.Daemon.Command (Command (..), toArgs) where

import Tricorder.API.IfThereArePendingQueries (IfThereArePendingQueries)
import Tricorder.API.OutputFormat (OutputFormat)

import Tricorder.API.IfThereArePendingQueries qualified as IfThereArePendingQueries
import Tricorder.API.OutputFormat qualified as OutputFormat


data Command
    = Start
    | Stop IfThereArePendingQueries
    | Restart IfThereArePendingQueries
    | Info OutputFormat


toArgs :: Command -> [String]
toArgs = \case
    Start -> ["start"]
    Stop force' -> "stop" : IfThereArePendingQueries.toArgs force'
    Restart force' -> "restart" : IfThereArePendingQueries.toArgs force'
    Info format -> "info" : OutputFormat.toArgs format
