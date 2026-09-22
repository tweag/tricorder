module Tricorder.CLI.Command.TestFilter
    ( TestFilter (..)
    , toArgs
    , failedOnlyFlagName
    , failedOnlyFlagShortName
    )
where

import Prelude hiding (All (..))


data TestFilter = All | FailedOnly


toArgs :: TestFilter -> [String]
toArgs All = []
toArgs FailedOnly = ["--" <> failedOnlyFlagName]


failedOnlyFlagName :: String
failedOnlyFlagName = "failed-only"


failedOnlyFlagShortName :: Char
failedOnlyFlagShortName = 'f'
