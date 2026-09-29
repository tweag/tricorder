module Tricorder.CLI.Arguments.OutputFormat (parser) where

import Options.Applicative (Parser, flag, help, long)
import Tricorder.CLI.Command.OutputFormat (OutputFormat (..))


parser :: Parser OutputFormat
parser =
    flag
        TextOutput
        JsonOutput
        $ long "json" <> help "Output full build state as JSON"
