module Tricorder.CLI.Arguments.OutputFormat (parser) where

import Options.Applicative (Parser, flag, help, long, short, showDefaultWith)
import Tricorder.CLI.Command.OutputFormat (OutputFormat (..), jsonOutputFlagName)


parser :: Parser OutputFormat
parser =
    flag
        TextOutput
        JsonOutput
        $ long jsonOutputFlagName
            <> short 'j'
            <> help "Output full build state as JSON"
