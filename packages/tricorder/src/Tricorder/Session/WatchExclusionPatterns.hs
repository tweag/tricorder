module Tricorder.Session.WatchExclusionPatterns
    ( WatchExclusionPatterns (..)
    , Pattern (..)
    , resolveWatchExclusionPatterns
    )
where

import Data.Aeson (ToJSON (..))
import Data.Default (Default (..))
import Text.Regex.TDFA.Pattern (showPattern)
import Text.Regex.TDFA.ReadRegex (parseRegex)

import Text.Regex.TDFA.Pattern qualified as Regex


newtype WatchExclusionPatterns = WatchExclusionPatterns {getWatchExclusionPatterns :: [Pattern]}
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via [Pattern]


instance Default WatchExclusionPatterns where
    def = WatchExclusionPatterns []


newtype Pattern = Pattern
    { getPattern :: (Regex.Pattern, (Regex.GroupIndex, Regex.DoPa))
    }
    deriving stock (Eq, Show)


instance ToJSON Pattern where
    toJSON (Pattern (pat, _)) = toJSON $ showPattern pat
    toEncoding (Pattern (pat, _)) = toEncoding $ showPattern pat


resolveWatchExclusionPatterns :: [Text] -> Either Text WatchExclusionPatterns
resolveWatchExclusionPatterns rawPatterns = do
    bimap show WatchExclusionPatterns
        $ traverse (fmap Pattern . parseRegex . toString) rawPatterns
