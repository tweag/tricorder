module Tricorder.API.TestFilter
    ( TestFilter (..)
    , toArgs
    , failedOnlyFlagName
    , failedOnlyFlagShortName
    )
where

import Prelude hiding (All (..))


data TestFilter = All | FailedOnly
    deriving stock (Bounded, Enum, Eq)


toArgs :: TestFilter -> [String]
toArgs All = []
toArgs FailedOnly = ["--" <> failedOnlyFlagName]


failedOnlyFlagName :: String
failedOnlyFlagName = "failed-only"


failedOnlyFlagShortName :: Char
failedOnlyFlagShortName = 'f'
