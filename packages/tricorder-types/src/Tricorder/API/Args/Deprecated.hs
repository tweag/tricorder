module Tricorder.API.Args.Deprecated (parser) where

import Options.Applicative (Parser, commandGroup, hidden, hsubparser)

import Tricorder.API.Command (Command (..))


parser :: Parser Command
parser =
    hsubparser
        $ mconcat
            [ hidden
            , commandGroup "Deprecated:"
            ]
