module Tricorder.CLI.Command.OutputFormat
    ( OutputFormat (..)
    , toArgs
    )
where


data OutputFormat
    = TextOutput
    | JsonOutput
    deriving stock (Eq)


toArgs :: OutputFormat -> [String]
toArgs JsonOutput = ["--json"]
toArgs TextOutput = []
