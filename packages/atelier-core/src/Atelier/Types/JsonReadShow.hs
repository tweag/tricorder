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
--     deriving (FromJSON, ToJSON) via (JsonReadShow Mode)
-- @
--
-- Here @Fast@ serialises to the JSON string @\"Fast\"@.
module Atelier.Types.JsonReadShow (JsonReadShow (..)) where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), withText)
import Data.Typeable (typeRep)


-- | Carrier for deriving JSON instances via 'Read' and 'Show'.
newtype JsonReadShow a = JsonReadShow {getJsonReadShow :: a}


instance forall a. (Read a, Typeable a) => FromJSON (JsonReadShow a) where
    parseJSON =
        let
            typeName = show $ typeRep $ Proxy @a
        in
            withText typeName
                $ maybe
                    (fail $ "Failed to read " <> typeName)
                    (pure . JsonReadShow)
                    . readMaybe
                    . toString


instance (Show a) => ToJSON (JsonReadShow a) where
    toJSON = String . show . getJsonReadShow
