module Tricorder.API.Daemon.Args (parser) where

import Options.Applicative (Parser, command, hsubparser, info, progDesc)

import Tricorder.API.Daemon.Command (DaemonCommand (..))

import Tricorder.API.OutputFormat.Args qualified as OutputFormat.Args


parser :: Parser DaemonCommand
parser = hsubparser (command "info" (info infoParser (progDesc "Information about the daemon")))


infoParser :: Parser DaemonCommand
infoParser = Info <$> OutputFormat.Args.parser
