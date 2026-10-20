module Tricorder.API.Daemon.Command (DaemonCommand (..), toArgs) where

import Tricorder.API.OutputFormat (OutputFormat)

import Tricorder.API.OutputFormat qualified as OutputFormat


data DaemonCommand
    = Info OutputFormat


toArgs :: DaemonCommand -> [String]
toArgs = \case
    Info format -> "info" : OutputFormat.toArgs format
