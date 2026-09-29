module Tricorder.CLI.Arguments.Daemon (parser) where

import Options.Applicative (Parser, command, hsubparser, info, progDesc)
import Tricorder.CLI.Command.Daemon (DaemonCommand (..))

import Tricorder.CLI.Arguments.OutputFormat qualified as OutputFormat


parser :: Parser DaemonCommand
parser = hsubparser (command "info" (info infoParser (progDesc "Information about the daemon")))


infoParser :: Parser DaemonCommand
infoParser = Info <$> OutputFormat.parser
