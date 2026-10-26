module Tricorder.API.IfThereArePendingQueries.Args
    ( parser
    )
where

import Options.Applicative (Parser, help, long)

import Atelier.Effects.Arguments.Switch qualified as Switch

import Tricorder.API.IfThereArePendingQueries (IfThereArePendingQueries (..), dontWaitFlagName)


parser :: Parser IfThereArePendingQueries
parser =
    fmap (bool Wait DontWait)
        $ Switch.parser
        $ long dontWaitFlagName <> help "Do not wait for queries and clients with pending requests."
