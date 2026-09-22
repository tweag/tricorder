module Tricorder.CLI.Arguments.TestFilter (parser) where

import Options.Applicative (FlagFields, Mod, Parser, flag, long, short)
import Tricorder.CLI.Command.TestFilter
    ( TestFilter (..)
    , failedOnlyFlagName
    , failedOnlyFlagShortName
    )
import Prelude hiding (All (..))


parser :: Mod FlagFields TestFilter -> Parser TestFilter
parser extraMods =
    flag All FailedOnly
        $ long failedOnlyFlagName
            <> short failedOnlyFlagShortName
            <> extraMods
