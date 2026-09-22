module Tricorder.CLI.Command.OutputFormat
    ( OutputFormat (..)
    , toArgs
    , jsonOutputFlagName
    )
where


data OutputFormat
    = TextOutput
    | JsonOutput
    deriving stock (Eq, Show)


toArgs :: OutputFormat -> [String]
toArgs JsonOutput = ["--" <> jsonOutputFlagName]
toArgs TextOutput = []


jsonOutputFlagName :: String
jsonOutputFlagName = "json"
