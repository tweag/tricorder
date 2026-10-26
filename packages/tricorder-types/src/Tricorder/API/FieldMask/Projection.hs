module Tricorder.API.FieldMask.Projection
    ( Projection (..)
    , project
    , codec
    , optionalKeys
    , renderYaml
    )
where

import Autodocodec
    ( Codec (..)
    , ObjectCodec
    , ValueCodec
    , bimapCodec
    , eitherCodec
    , listCodec
    , named
    , object
    , optionalFieldWith'
    , optionalKeyCodec
    , valueCodec
    , (.=)
    )
import Data.Aeson (Value (..))

import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KeyMap
import Data.List qualified as List
import Data.Yaml.Builder qualified as Yaml

import Tricorder.API.FieldMask.Schema (Schema (..))


-- | Parts of a JSON value.
data Projection
    = PObject [(Text, Projection)]
    | PArray [Projection]
    | PScalar Value
    deriving stock (Eq, Show)


-- | Encodes a projection with just the fields defined in the given 'Schema'.
-- This is effectively just an encoder, though, hence the 'Void' decoding type.
codec :: Schema -> ValueCodec Projection Void
codec schema =
    named "Projection"
        $ bimapCodec (const $ Left "projections can only be encoded") split
        $ eitherCodec (listCodec $ codec schema)
        $ eitherCodec (object "Projection" $ fieldsCodec schema)
        $ valueCodec
  where
    split = \case
        PArray values -> Left values
        PObject fields -> Right $ Left fields
        PScalar value -> Right $ Right value


fieldsCodec :: Schema -> ObjectCodec [(Text, Projection)] ()
fieldsCodec (Schema fields) =
    for_ fields \(name, sub) ->
        optionalFieldWith' name (codec $ fromMaybe (Schema []) sub) .= List.lookup name


-- | Mark every field as optional. Discriminated unions are kept as-is, as they
-- need their discriminator.
optionalKeys :: Codec context input output -> Codec context input output
optionalKeys = \case
    RequiredKeyCodec key valueCodec' doc ->
        BimapCodec (maybe (Left $ "missing key " <> toString key) (Right . coerce)) (Just . coerce)
            $ optionalKeyCodec key (optionalKeys valueCodec') doc
    OptionalKeyCodec key valueCodec' doc -> OptionalKeyCodec key (optionalKeys valueCodec') doc
    OptionalKeyWithDefaultCodec key valueCodec' def doc ->
        OptionalKeyWithDefaultCodec key (optionalKeys valueCodec') def doc
    OptionalKeyWithOmittedDefaultCodec key valueCodec' def doc ->
        OptionalKeyWithOmittedDefaultCodec key (optionalKeys valueCodec') def doc
    ObjectOfCodec name objectCodec -> ObjectOfCodec name (optionalKeys objectCodec)
    ArrayOfCodec name element -> ArrayOfCodec name (optionalKeys element)
    HashMapCodec element -> HashMapCodec (optionalKeys element)
    MapCodec element -> MapCodec (optionalKeys element)
    BimapCodec from to inner -> BimapCodec from to (optionalKeys inner)
    EitherCodec union left right -> EitherCodec union (optionalKeys left) (optionalKeys right)
    CommentCodec comment inner -> CommentCodec comment (optionalKeys inner)
    ReferenceCodec name inner -> ReferenceCodec name (optionalKeys inner)
    ApCodec function argument -> ApCodec (optionalKeys function) (optionalKeys argument)
    other -> other


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
