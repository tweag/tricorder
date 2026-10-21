module Tricorder.API.Daemon.Command (Command (..), toArgs) where

import Tricorder.API.OutputFormat (OutputFormat)

import Tricorder.API.OutputFormat qualified as OutputFormat


data Command
    = Info OutputFormat


toArgs :: Command -> [String]
toArgs = \case
    Info format -> "info" : OutputFormat.toArgs format
