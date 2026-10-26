module Tricorder.API.Daemon.Args
    ( parser
    , infoParser
    , startParser
    , stopParser
    , restartParser
    )
where

import Options.Applicative (Parser, ParserInfo, command, hsubparser, info, progDesc)

import Tricorder.API.Daemon.Command (Command (..))

import Tricorder.API.IfThereArePendingQueries.Args qualified as IfThereArePendingQueries.Args
import Tricorder.API.OutputFormat.Args qualified as OutputFormat.Args


parser :: ParserInfo Command
parser = info subParser $ progDesc "Manage the daemon itself."


subParser :: Parser Command
subParser =
    hsubparser
        $ mconcat
            [ command "info"
                $ info infoParser
                $ progDesc "Information about the daemon."
            , command "start"
                $ info startParser
                $ progDesc "Start the daemon (no-op if already running.)"
            , command "stop"
                $ info stopParser
                $ progDesc "Stop the daemon."
            , command "restart"
                $ info restartParser
                $ progDesc "Restart the daemon."
            ]


infoParser :: Parser Command
infoParser = Info <$> OutputFormat.Args.parser


startParser :: Parser Command
startParser = pure Start


stopParser :: Parser Command
stopParser = Stop <$> IfThereArePendingQueries.Args.parser


restartParser :: Parser Command
restartParser = Restart <$> IfThereArePendingQueries.Args.parser
