module Tricorder.Session.WatchExclusionPatterns
    ( WatchExclusionPatterns (..)
    , Pattern
    , resolveWatchExclusionPatterns
    )
where

import Data.Default (Default (..))
import Text.Regex.TDFA.ReadRegex (parseRegex)

import Text.Regex.TDFA.Pattern qualified as Regex


newtype WatchExclusionPatterns = WatchExclusionPatterns {getWatchExclusionPatterns :: [Pattern]}
    deriving stock (Eq, Generic, Show)


instance Default WatchExclusionPatterns where
    def = WatchExclusionPatterns []


type Pattern = (Regex.Pattern, (Regex.GroupIndex, Regex.DoPa))


resolveWatchExclusionPatterns :: [Text] -> Either Text WatchExclusionPatterns
resolveWatchExclusionPatterns rawPatterns = do
    bimap show WatchExclusionPatterns
        $ traverse (parseRegex . toString) rawPatterns
