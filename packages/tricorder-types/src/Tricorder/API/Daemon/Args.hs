module Tricorder.API.Daemon.Args (parser) where

import Options.Applicative (Parser, command, hsubparser, info, progDesc)

import Tricorder.API.Daemon.Command (Command (..))

import Tricorder.API.OutputFormat.Args qualified as OutputFormat.Args


parser :: Parser Command
parser = hsubparser (command "info" (info infoParser (progDesc "Information about the daemon")))


infoParser :: Parser Command
infoParser = Info <$> OutputFormat.Args.parser
