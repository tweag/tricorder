module Tricorder.Daemon.Ghci.Position
    ( Position (..)
    , parser
    )
where

import Text.Megaparsec (Parsec, choice)
import Text.Megaparsec.Char (char)
import Prelude hiding (many)

import Text.Megaparsec.Char.Lexer qualified as L


-- | A source position (1-based line and column). @(0, 0)@ when unavailable.
data Position = Position
    { line :: Int
    , col :: Int
    }
    deriving stock (Eq, Show)


-- | Parse a GHCi position in one of the formats:
--   @(L1,C1)-(L2,C2):@, @L:C:@, or @L:C-C2:@.
-- Consumes the trailing colon.
parser :: Parsec Void Text (Position, Position)
parser = parenForm <|> simpleForm
  where
    parenForm = do
        _ <- char '('
        l1 <- L.decimal
        _ <- char ','
        c1 <- L.decimal
        _ <- char ')'
        _ <- char '-'
        _ <- char '('
        _ <- optional (char '(') -- some GHCi versions emit "(L1,C1)-((L2,C2):"
        l2 <- L.decimal
        _ <- char ','
        c2 <- L.decimal
        _ <- char ')'
        _ <- char ':'
        pure (Position l1 c1, Position l2 c2)
    simpleForm = do
        l <- L.decimal
        _ <- char ':'
        c <- L.decimal
        choice
            [ do
                _ <- char ':'
                pure (Position l c, Position l c)
            , do
                _ <- char '-'
                c2 <- L.decimal
                _ <- char ':'
                pure (Position l c, Position l c2)
            ]
