module Atelier.Types.JSON.ReadShow (ReadShow (..)) where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), withText)
import Data.Typeable (typeRep)


-- | Derive 'FromJSON' and 'ToJSON' for a type from its 'Read' and 'Show'
-- instances, encoding each value as a JSON string.
--
-- A value is stored as its 'Show' output and parsed back with 'readMaybe'. On
-- failure the error message names the type (via 'Typeable'), e.g.
-- @Failed to read Mode@.
--
-- @
-- data Mode = Fast | Slow
--     deriving stock (Read, Show)
--     deriving (FromJSON, ToJSON) via (ReadShow Mode)
-- @
--
-- Here @Fast@ serialises to the JSON string @\"Fast\"@.
newtype ReadShow a = ReadShow {getReadShow :: a}


instance forall a. (Read a, Typeable a) => FromJSON (ReadShow a) where
    parseJSON =
        let
            typeName = show $ typeRep $ Proxy @a
        in
            withText typeName
                $ maybe
                    (fail $ "Failed to read " <> typeName)
                    (pure . ReadShow)
                    . readMaybe
                    . toString


instance (Show a) => ToJSON (ReadShow a) where
    toJSON = String . show . getReadShow
