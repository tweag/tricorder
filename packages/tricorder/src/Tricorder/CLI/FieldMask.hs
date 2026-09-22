-- | Parsing field masks, checking them against the shape of a response, and
-- projecting response values down to the selected fields.
module Tricorder.CLI.FieldMask
    ( parse
    , Schema (..)
    , leaf
    , nested
    , select
    , Projected (..)
    , project
    , renderYaml
    )
where

import Data.Aeson (ToJSON (..), Value (..), object, pairs, (.=))
import Text.Megaparsec (Parsec, between, eof, errorBundlePretty, takeWhile1P)
import Text.Megaparsec.Char (space)
import Tricorder.CLI.Command.FieldMask (Field (..), FieldMask (..))

import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KeyMap
import Data.Char qualified as Char
import Data.List qualified as List
import Data.Text qualified as T
import Data.Yaml.Builder qualified as Yaml
import Text.Megaparsec qualified as Megaparsec
import Text.Megaparsec.Char.Lexer qualified as Lexer


type Parser = Parsec Void Text


-- | Parse a field mask such as @name,status,cases(description,failure)@.
parse :: Text -> Either Text FieldMask
parse =
    first (toText . errorBundlePretty)
        . Megaparsec.parse (space *> fieldMask <* eof) "fields"
  where
    fieldMask :: Parser FieldMask
    fieldMask = FieldMask <$> ((:|) <$> field <*> many (symbol "," *> field))

    field :: Parser Field
    field = Field <$> lexeme fieldName <*> optional (between (symbol "(") (symbol ")") fieldMask)

    fieldName = takeWhile1P (Just "field name") \c -> Char.isAlphaNum c || c == '_'

    lexeme = Lexer.lexeme space
    symbol = Lexer.symbol space


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


-- | A JSON value cut down to the fields of a 'Schema', with its fields in
-- schema order.
data Projected
    = PObject [(Text, Projected)]
    | PArray [Projected]
    | PScalar Value
    deriving stock (Eq, Show)


instance ToJSON Projected where
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
project :: Schema -> Value -> Projected
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


renderYaml :: Projected -> Text
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
