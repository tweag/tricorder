module Tricorder.API.JsonSchema (document) where

import Autodocodec (ValueCodec)
import Autodocodec.Schema (jsonSchemaVia)
import Data.Aeson (Value (..), toJSON)
import Data.Aeson.Text (encodeToLazyText)

import Data.Aeson.KeyMap qualified as KeyMap


-- | The JSON Schema (draft 2020-12) of what a codec encodes, as a document
-- with a title, rendered as JSON.
document :: Text -> ValueCodec input output -> Text
document title codec =
    toStrict $ encodeToLazyText $ case toJSON $ jsonSchemaVia codec of
        Object fields -> Object $ KeyMap.union header fields
        schema -> schema
  where
    header =
        KeyMap.fromList
            [ ("$schema", toJSON @Text "https://json-schema.org/draft/2020-12/schema")
            , ("title", toJSON title)
            ]
