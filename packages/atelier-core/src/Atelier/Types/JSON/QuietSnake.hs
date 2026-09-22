{-# LANGUAGE UndecidableInstances #-}

-- | Derive 'FromJSON' and 'ToJSON' for a record so its Haskell field names map
-- to @quiet_snake_case@ JSON keys.
--
-- \"Quiet\" snake case lowercases and underscore-separates words without an
-- extra leading underscore, so the field @maxRetries@ becomes the JSON key
-- @max_retries@. Derive via this wrapper to keep idiomatic Haskell field names
-- while exposing snake-case JSON:
--
-- @
-- data Settings = Settings { maxRetries :: Int, dryRun :: Bool }
--     deriving stock (Generic)
--     deriving (FromJSON, ToJSON) via (QuietSnake Settings)
-- @
module Atelier.Types.JSON.QuietSnake
    ( QuietSnake (..)
    , options
    )
where

import Data.Aeson
    ( FromJSON (..)
    , GFromJSON
    , GToJSON
    , Options (..)
    , ToJSON (..)
    , Zero
    , camelTo2
    , defaultOptions
    , genericParseJSON
    , genericToJSON
    )
import Data.Default (Default (..))
import GHC.Generics (Rep)


-- | Carrier for deriving @quiet_snake_case@ JSON instances generically.
newtype QuietSnake a = QuietSnake {getQuietSnake :: a}


instance (Default a) => Default (QuietSnake a) where
    def = QuietSnake def


instance (GFromJSON Zero (Rep a), Generic a) => FromJSON (QuietSnake a) where
    parseJSON = fmap QuietSnake . genericParseJSON options


instance (GToJSON Zero (Rep a), Generic a) => ToJSON (QuietSnake a) where
    toJSON = genericToJSON options . getQuietSnake


options :: Options
options =
    defaultOptions
        { constructorTagModifier = camelTo2 '_'
        , fieldLabelModifier = camelTo2 '_'
        }
