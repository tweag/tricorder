module Tricorder.CLI.Command.Daemon (DaemonCommand (..), toArgs) where

import Tricorder.CLI.Command.OutputFormat (OutputFormat)

import Tricorder.CLI.Command.OutputFormat qualified as OutputFormat


data DaemonCommand
    = Info OutputFormat


toArgs :: DaemonCommand -> [String]
toArgs = \case
    Info format -> "info" : OutputFormat.toArgs format
