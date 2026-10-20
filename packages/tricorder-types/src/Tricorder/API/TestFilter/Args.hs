module Tricorder.API.TestFilter.Args (parser) where

import Options.Applicative (FlagFields, Mod, Parser, flag, long, short)

import Tricorder.API.TestFilter
    ( TestFilter (..)
    , failedOnlyFlagName
    , failedOnlyFlagShortName
    )

import Tricorder.API.TestFilter qualified as TestFilter


parser :: Mod FlagFields TestFilter -> Parser TestFilter
parser extraMods =
    flag TestFilter.All TestFilter.FailedOnly
        $ long failedOnlyFlagName
            <> short failedOnlyFlagShortName
            <> extraMods
