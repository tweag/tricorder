module Tricorder.EvalComment
    ( EvalComment (..)
    , findEvalComments
    , evalCommentP
    , singleLineEvalCommentP
    , multiLineEvalCommentP
    , blockCommentEvalP
    ) where

import Text.Megaparsec
    ( MonadParsec (takeWhile1P, takeWhileP)
    , Parsec
    , SourcePos (..)
    , anySingle
    , eof
    , getSourcePos
    , manyTill
    , parse
    , try
    , unPos
    )
import Text.Megaparsec.Char (char, hspace, space, string)

import Data.Text qualified as T


-- | An eval comment found in a source file: a @-- $> \<expr\>@ annotation.
data EvalComment = EvalComment
    { lineNumber :: Int
    , expression :: Text
    }
    deriving stock (Eq, Show)


-- | Scan source file content for eval comments.
-- Returns one 'EvalComment' per match, in source order.
findEvalComments :: Text -> [EvalComment]
findEvalComments content =
    case parse fileP "" content of
        Left _ -> []
        Right comments -> comments
  where
    fileP = catMaybes <$> manyTill lineP eof
    lineP = hspace *> ((Just <$> try evalCommentP) <|> (Nothing <$ skipRestOfLine))
    skipRestOfLine = void $ takeWhileP Nothing (/= '\n') *> optional (char '\n')


evalCommentP :: Parser EvalComment
evalCommentP = singleLineEvalCommentP <|> multiLineEvalCommentP <|> blockCommentEvalP


-- | @-- $> \<expr\>@ on a single line.
singleLineEvalCommentP :: Parser EvalComment
singleLineEvalCommentP = do
    _ <- string "-- $>"
    space
    SourcePos {sourceLine} <- getSourcePos
    expression <- takeWhile1P (Just "eval comment character") (/= '\n')
    pure
        EvalComment
            { lineNumber = unPos sourceLine
            , expression
            }


-- | Multi-line line-comment block:
--
-- @
-- -- $$>
-- -- line one
-- -- line two
-- -- \<$$
-- @
--
-- Each content line must start with @--@ (optionally followed by a space).
-- The leading @-- @ is stripped; relative indentation within the block is
-- preserved.
multiLineEvalCommentP :: Parser EvalComment
multiLineEvalCommentP = do
    SourcePos {sourceLine} <- getSourcePos
    _ <- string "-- $$>"
    _ <- optional (char '\n')
    lineContents <- manyTill commentLineP (try (string "-- <$$"))
    pure
        EvalComment
            { expression = T.intercalate "\n" lineContents
            , lineNumber = unPos sourceLine
            }
  where
    commentLineP = do
        _ <- string "--"
        _ <- optional (char ' ')
        content <- takeWhileP Nothing (/= '\n')
        _ <- optional (char '\n')
        pure content


-- | Block-comment eval:
--
-- @
-- {- $$>
-- expr
-- \<$$ -}
-- @
--
-- Content between the markers is stripped of leading\/trailing whitespace.
-- For multi-line expressions use the layout that GHCi expects; do not indent
-- the body relative to the opening @{- $>@ marker.
blockCommentEvalP :: Parser EvalComment
blockCommentEvalP = do
    SourcePos {sourceLine} <- getSourcePos
    _ <- string "{- $$>"
    _ <- optional (char '\n')
    chars <- manyTill anySingle (string "<$$ -}")
    pure
        EvalComment
            { expression = T.strip (toText chars)
            , lineNumber = unPos sourceLine
            }


type Parser = Parsec Void Text
