module Tricorder.API.IfBuildIsPending.Args (parser) where

import Options.Applicative (Parser, help, long, short)

import Atelier.Effects.Arguments.Switch qualified as Switch

import Tricorder.API.IfBuildIsPending
    ( IfBuildIsPending (..)
    , useCurrentFlagName
    , useCurrentShortFlagName
    )


parser :: Parser IfBuildIsPending
parser =
    fmap (bool WaitForBuild UseCurrent)
        $ Switch.parser
        $ long useCurrentFlagName
            <> short useCurrentShortFlagName
            <> help "Skip waiting for the pending build and use the current (potentially incomplete) build status."
