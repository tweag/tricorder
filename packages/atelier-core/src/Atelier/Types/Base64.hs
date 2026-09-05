-- | A 'ByteString' that serialises to and from JSON as a Base64-encoded string.
--
-- Use it directly as a field type, or derive the JSON instances for a
-- @ByteString@ newtype via it, to carry binary data through JSON without
-- tripping over non-UTF-8 bytes:
--
-- @
-- newtype Token = Token ByteString
--     deriving (ToJSON, FromJSON) via Base64
-- @
module Atelier.Types.Base64
    ( Base64 (..)
    )
where

import Data.Aeson (FromJSON (..), ToJSON (..), withText)

import Data.ByteString.Base64 qualified as Base64


-- | A 'ByteString' whose JSON representation is Base64-encoded text.
newtype Base64 = Base64 {getBase64 :: ByteString}


instance ToJSON Base64 where
    toJSON = toJSON . decodeUtf8 @Text . Base64.encode . getBase64


instance FromJSON Base64 where
    parseJSON = withText "Base64" $ \t ->
        case Base64.decode (encodeUtf8 t) of
            Left err -> fail err
            Right b -> pure (Base64 b)
