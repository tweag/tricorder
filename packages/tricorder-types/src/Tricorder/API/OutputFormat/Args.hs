module Tricorder.API.OutputFormat.Args (parser) where

import Options.Applicative (Parser, flag, help, long, short)

import Tricorder.API.OutputFormat (OutputFormat (..), jsonOutputFlagName)


parser :: Parser OutputFormat
parser =
    flag
        TextOutput
        JsonOutput
        $ long jsonOutputFlagName
            <> short 'j'
            <> help "Output full build state as JSON"
