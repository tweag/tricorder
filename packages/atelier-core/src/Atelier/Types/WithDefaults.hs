-- | Merge a type's 'Default' value into incoming JSON before parsing, so fields
-- absent from the input fall back to their defaults instead of failing.
--
-- Derive 'FromJSON' via this wrapper when partial JSON should be completed from
-- a 'Default' instance. Missing non-'Maybe' fields then take their default
-- value rather than causing a parse error:
--
-- @
-- data Config = Config { retries :: Int, verbose :: Bool }
--     deriving stock (Generic)
--     deriving (FromJSON) via (WithDefaults Config)
--
-- instance Default Config where
--     def = Config { retries = 3, verbose = False }
-- @
--
-- Parsing @{\"verbose\": true}@ then yields @Config { retries = 3, verbose = True }@.
module Atelier.Types.WithDefaults
    ( WithDefaults (..)
    )
where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..))
import Data.Default (Default (..))

import Data.Aeson.KeyMap qualified as KM


-- | Carrier that fills missing JSON fields from a type's 'Default' instance
-- before parsing.
newtype WithDefaults a = WithDefaults {getWithDefaults :: a}


instance (Default a, FromJSON a, ToJSON a) => FromJSON (WithDefaults a) where
    parseJSON v = WithDefaults <$> parseJSON merged
      where
        merged = mergeLeft (toJSON (def :: a)) v

        mergeLeft (Object l) (Object r) = Object $ KM.unionWith mergeLeft l r
        mergeLeft _ r = r
