-- | Strongly-typed time units and conversions.
--
-- @
-- nominalDiffTime 1.5 :: Millisecond        -- 1.5s rounded to 1500ms
-- convertUnit (5 :: Minute) :: Second       -- 300
-- toMicroseconds (2 :: Second)              -- 2000000
-- @
module Atelier.Time
    ( -- * Time units
      TimeUnit
    , Microsecond
    , Millisecond
    , Second
    , Minute
    , Hour

      -- * Conversions
    , nominalDiffTime
    , fromMicroseconds
    , toMicroseconds
    , convertUnit

      -- * Utility newtypes for converting time to and from JSON
    , AsJsonMicrosecond (..)
    , AsRawUnit (..)
    )
where

import Data.Aeson (FromJSON (..), ToJSON (..))
import Data.Time (NominalDiffTime)
import Data.Time.Units
    ( Hour
    , Microsecond
    , Millisecond
    , Minute
    , Second
    , TimeUnit (..)
    , convertUnit
    )


-- | Convert a 'NominalDiffTime' to any 'TimeUnit', rounding to the nearest
-- whole unit (the conversion goes through microsecond precision).
nominalDiffTime :: (TimeUnit t) => NominalDiffTime -> t
nominalDiffTime = fromMicroseconds . round @Double . (* 1_000_000) . realToFrac


newtype AsJsonMicrosecond unit = AsJsonMicrosecond {getAsJsonMicroseconds :: unit}
    deriving stock (Eq, Generic, Show)


instance (TimeUnit unit) => ToJSON (AsJsonMicrosecond unit) where
    toJSON = toJSON . toMicroseconds . getAsJsonMicroseconds


instance (TimeUnit unit) => FromJSON (AsJsonMicrosecond unit) where
    parseJSON = fmap (AsJsonMicrosecond . fromMicroseconds) . parseJSON


newtype AsRawUnit unit = AsRawUnit {getAsRawUnit :: unit}
    deriving stock (Eq, Generic, Show)


instance (Integral unit) => ToJSON (AsRawUnit unit) where
    toJSON = toJSON . toInteger . getAsRawUnit


instance (Integral unit) => FromJSON (AsRawUnit unit) where
    parseJSON = fmap (AsRawUnit . fromInteger) . parseJSON
