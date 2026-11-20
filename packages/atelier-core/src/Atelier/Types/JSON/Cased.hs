{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Derive 'FromJSON' and 'ToJSON' for a type so its Haskell field names and
-- constructor tags map to JSON in a chosen casing convention.
--
-- The casing is selected at the type level with a promoted 'Casing'
-- constructor. Derive via this wrapper to keep idiomatic Haskell names while
-- exposing whichever convention the wire format requires:
--
-- @
-- data Settings = Settings { maxRetries :: Int, dryRun :: Bool }
--     deriving stock (Generic)
--     deriving (FromJSON, ToJSON) via (Cased 'KebabCase Settings)
-- @
--
-- This encodes @Settings 3 True@ as @{\"max-retries\": 3, \"dry-run\": true}@.
module Atelier.Types.JSON.Cased
    ( Cased (..)
    , Casing (..)
    , KnownCasing (..)
    , casedOptions
    , casingOptions
    , applyCasing
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

import Text.Casing qualified as Casing


-- | Casing conventions for JSON field names and constructor tags.
data Casing
    = -- | @camelCase@
      CamelCase
    | -- | @PascalCase@
      PascalCase
    | -- | @quiet_snake_case@, keeping any leading underscore (as in
      -- "Atelier.Types.JSON.QuietSnake"); the other casings drop it.
      QuietSnakeCase
    | -- | @SCREAMING_SNAKE_CASE@
      ScreamingSnakeCase
    | -- | @kebab-case@
      KebabCase
    deriving stock (Bounded, Enum, Eq, Show)


-- | Carrier for deriving JSON instances generically in the casing @c@.
newtype Cased (c :: Casing) a = Cased {getCased :: a}


instance (Default a) => Default (Cased c a) where
    def = Cased def


instance (GFromJSON Zero (Rep a), Generic a, KnownCasing c) => FromJSON (Cased c a) where
    parseJSON = fmap Cased . genericParseJSON (casedOptions @c)


instance (GToJSON Zero (Rep a), Generic a, KnownCasing c) => ToJSON (Cased c a) where
    toJSON = genericToJSON (casedOptions @c) . getCased


-- | Reflect a type-level 'Casing' to its term-level value.
class KnownCasing (c :: Casing) where
    casingVal :: Casing


instance KnownCasing 'CamelCase where casingVal = CamelCase


instance KnownCasing 'PascalCase where casingVal = PascalCase


instance KnownCasing 'QuietSnakeCase where casingVal = QuietSnakeCase


instance KnownCasing 'ScreamingSnakeCase where casingVal = ScreamingSnakeCase


instance KnownCasing 'KebabCase where casingVal = KebabCase


-- | Aeson 'Options' for the type-level casing @c@.
casedOptions :: forall c. (KnownCasing c) => Options
casedOptions = casingOptions (casingVal @c)


-- | Aeson 'Options' that apply the given casing to both field labels and
-- constructor tags.
casingOptions :: Casing -> Options
casingOptions casing =
    defaultOptions
        { constructorTagModifier = applyCasing casing
        , fieldLabelModifier = applyCasing casing
        }


-- | Convert a Haskell identifier (camelCase or PascalCase) to the given casing.
applyCasing :: Casing -> String -> String
applyCasing = \case
    CamelCase -> Casing.camel
    PascalCase -> Casing.pascal
    QuietSnakeCase -> camelTo2 '_'
    ScreamingSnakeCase -> Casing.screamingSnake
    KebabCase -> Casing.kebab
