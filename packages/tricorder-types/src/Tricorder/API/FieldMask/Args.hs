module Tricorder.API.FieldMask.Args (parser, parse) where

import Options.Applicative (Mod, OptionFields, Parser, eitherReader, long, metavar, option)
import Text.Megaparsec (Parsec, between, eof, errorBundlePretty, takeWhile1P)
import Text.Megaparsec.Char (space)

import Data.Char qualified as Char
import Text.Megaparsec qualified as Megaparsec
import Text.Megaparsec.Char.Lexer qualified as Lexer

import Tricorder.API.FieldMask (Field (..), FieldMask (..), fieldsFlagName)


parser :: Mod OptionFields FieldMask -> Parser (Maybe FieldMask)
parser extraMods =
    optional
        $ option (eitherReader $ first toString . parse . toText)
        $ long fieldsFlagName
            <> metavar "FIELDS"
            <> extraMods


-- | Parse a field mask such as @name,status,cases(description,failure)@.
parse :: Text -> Either Text FieldMask
parse =
    first (toText . errorBundlePretty)
        . Megaparsec.parse (space *> fieldMask <* eof) "fields"
  where
    fieldMask :: TParser FieldMask
    fieldMask = FieldMask <$> ((:|) <$> field <*> many (symbol "," *> field))

    field :: TParser Field
    field = Field <$> lexeme fieldName <*> optional (between (symbol "(") (symbol ")") fieldMask)

    fieldName = takeWhile1P (Just "field name") \c -> Char.isAlphaNum c || c == '_'

    lexeme = Lexer.lexeme space
    symbol = Lexer.symbol space


type TParser = Parsec Void Text
