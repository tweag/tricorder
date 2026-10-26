module Tricorder.API.FieldMask.Schema
    ( Schema (..)
    , leaf
    , nested
    , fromCodec
    , select
    , render
    )
where

import Autodocodec (ValueCodec)
import Autodocodec.Schema (JSONSchema (..), ObjectSchema (..), jsonSchemaVia)
import Options.Applicative.Help (Doc)

import Data.List qualified as List
import Data.Text qualified as T
import Options.Applicative.Help qualified as Doc

import Tricorder.API.FieldMask (Field (..), FieldMask (..))


-- | The fields available in a response, in the order they are shown by
-- default. Fields without a nested 'Schema' are shown as-is.
--
-- A 'Schema' narrowed down by 'select' describes exactly what to show.
newtype Schema = Schema [(Text, Maybe Schema)]
    deriving stock (Eq, Show)


leaf :: Text -> (Text, Maybe Schema)
leaf name = (name, Nothing)


nested :: Text -> [(Text, Maybe Schema)] -> (Text, Maybe Schema)
nested name fields = (name, Just $ Schema fields)


-- | The fields of the objects a codec encodes, in the order the codec encodes
-- them. Fields holding objects, or lists of objects, get a nested 'Schema'.
--
-- Codecs that do not encode objects have no fields.
fromCodec :: ValueCodec input output -> Schema
fromCodec = fromMaybe (Schema []) . fromJsonSchema . jsonSchemaVia
  where
    fromJsonSchema = \case
        CommentSchema _ schema -> fromJsonSchema schema
        ArraySchema schema -> fromJsonSchema schema
        ObjectSchema schema -> Just $ Schema $ objectFields schema
        _ -> Nothing

    objectFields = \case
        ObjectKeySchema name _ schema _ -> [(name, fromJsonSchema schema)]
        ObjectAllOfSchema schemas -> concatMap objectFields schemas
        _ -> []


-- | Narrow a 'Schema' down to the fields of a 'FieldMask', keeping the order
-- the fields were requested in. Fails on fields the schema does not have.
select :: Schema -> FieldMask -> Either Text Schema
select = go []
  where
    go path (Schema available) (FieldMask requested) =
        Schema <$> traverse (selectField path available) (toList requested)

    selectField path available field =
        case (field.subFields, List.lookup field.name available) of
            (_, Nothing) ->
                Left
                    $ "unknown field "
                        <> quote (fieldPath path field.name)
                        <> ", expected one of: "
                        <> T.intercalate ", " (fst <$> available)
            (Nothing, Just schema) -> Right (field.name, schema)
            (Just mask, Just (Just schema)) -> (field.name,) . Just <$> go (field.name : path) schema mask
            (Just _, Just Nothing) ->
                Left $ "field " <> quote (fieldPath path field.name) <> " has no sub-fields"

    fieldPath path name = T.intercalate "." $ reverse $ name : path
    quote name = "'" <> name <> "'"


render :: Schema -> [Doc]
render (Schema fields) = renderField <$> fields


renderField :: (Text, Maybe Schema) -> Doc
renderField (name, sub) =
    Doc.pretty name
        <> maybe
            Doc.emptyDoc
            ( \nestedSchema ->
                Doc.enclose
                    "("
                    ")"
                    $ Doc.sep
                    $ Doc.punctuate ","
                    $ render nestedSchema
            )
            sub
