-- | Parsing field masks, checking them against the shape of a response, and
-- projecting response values down to the selected fields.
module Tricorder.FieldMask.Projection
    ( Projection (..)
    , project
    , renderYaml
    )
where

import Data.Aeson (ToJSON (..), Value (..), object, pairs, (.=))

import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KeyMap
import Data.Yaml.Builder qualified as Yaml

import Tricorder.FieldMask.Schema (Schema (..))


-- | A JSON value cut down to the fields of a 'Schema', with its fields in
-- schema order.
data Projection
    = PObject [(Text, Projection)]
    | PArray [Projection]
    | PScalar Value
    deriving stock (Eq, Show)


instance ToJSON Projection where
    toJSON = \case
        PObject fields -> object [Key.fromText name .= value | (name, value) <- fields]
        PArray values -> toJSON values
        PScalar value -> value
    toEncoding = \case
        PObject fields -> pairs $ foldMap (\(name, value) -> Key.fromText name .= value) fields
        PArray values -> toEncoding values
        PScalar value -> toEncoding value


-- | Keep only the fields in the 'Schema'. Arrays are projected element-wise,
-- and fields that are missing or @null@ are left out.
project :: Schema -> Value -> Projection
project schema@(Schema fields) = \case
    Array values -> PArray $ project schema <$> toList values
    Object obj ->
        PObject
            [ (name, maybe PScalar project sub value)
            | (name, sub) <- fields
            , Just value <- [KeyMap.lookup (Key.fromText name) obj]
            , value /= Null
            ]
    value -> PScalar value


renderYaml :: Projection -> Text
renderYaml = decodeUtf8 . Yaml.toByteString . toYaml
  where
    toYaml = \case
        PObject fields -> Yaml.mapping $ second toYaml <$> fields
        PArray values -> Yaml.array $ toYaml <$> values
        PScalar value -> valueToYaml value

    valueToYaml = \case
        Object obj -> Yaml.mapping $ bimap Key.toText valueToYaml <$> KeyMap.toList obj
        Array values -> Yaml.array $ valueToYaml <$> toList values
        String text -> Yaml.string text
        Number number -> Yaml.scientific number
        Bool b -> Yaml.bool b
        Null -> Yaml.null
