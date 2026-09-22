module Tricorder.CLI.Command.FieldMask
    ( FieldMask (..)
    , Field (..)
    , render
    , toArgs
    , fieldsFlagName
    )
where

import Data.Text qualified as T


-- | A selection of fields to include in a response, in the style of Google's
-- partial-response @fields@ parameter:
--
-- @
-- name,status,cases(description,failure)
-- @
newtype FieldMask = FieldMask {getFields :: NonEmpty Field}
    deriving stock (Eq, Show)


data Field = Field
    { name :: Text
    , subFields :: Maybe FieldMask
    -- ^ 'Nothing' selects the field's whole value.
    }
    deriving stock (Eq, Show)


render :: FieldMask -> Text
render (FieldMask fields) = T.intercalate "," $ renderField <$> toList fields
  where
    renderField field = field.name <> maybe "" (\sub -> "(" <> render sub <> ")") field.subFields


toArgs :: Maybe FieldMask -> [String]
toArgs = maybe [] \mask -> ["--" <> fieldsFlagName, toString $ render mask]


fieldsFlagName :: String
fieldsFlagName = "fields"
