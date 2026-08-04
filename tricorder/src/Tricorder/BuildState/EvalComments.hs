module Tricorder.BuildState.EvalComments
    ( Phase (..)
    , Comments (..)
    , anyRunningComments
    , Evaluation (..)
    , Comment (..)
    , findComments
    , evalCommentP
    , singleLineEvalCommentP
    , multiLineEvalCommentP
    , blockCommentEvalP
    , State (..)
    ) where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), withObject, (.:))
import GHC.Generics (Generically (..))
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

import Data.Aeson.KeyMap qualified as KM
import Data.Text qualified as T


data Phase
    = Looking
    | Found Comments
    | NoneFound
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically Phase


data Comments = Comments {getComments :: NonEmpty Evaluation}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically Comments


anyRunningComments :: Phase -> Bool
anyRunningComments = \case
    Looking -> True
    Found comments -> any ((== Pending) . (.state)) $ comments.getComments
    NoneFound -> False


data Evaluation = Evaluation
    { file :: FilePath
    , comment :: Comment
    , state :: State
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically Evaluation


-- | An eval comment found in a source file: a @-- $> \<expr\>@ annotation.
data Comment = Comment
    { lineNumber :: Int
    , expression :: Text
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically Comment


-- | Scan source file content for eval comments.
-- Returns one 'Comment' per match, in source order.
findComments :: Text -> [Comment]
findComments content =
    case parse fileP "" content of
        Left _ -> []
        Right comments -> comments
  where
    fileP = catMaybes <$> manyTill lineP eof
    lineP = hspace *> ((Just <$> try evalCommentP) <|> (Nothing <$ skipRestOfLine))
    skipRestOfLine = void $ takeWhileP Nothing (/= '\n') *> optional (char '\n')


evalCommentP :: Parser Comment
evalCommentP = singleLineEvalCommentP <|> multiLineEvalCommentP <|> blockCommentEvalP


-- | @-- $> \<expr\>@ on a single line.
singleLineEvalCommentP :: Parser Comment
singleLineEvalCommentP = do
    _ <- string "-- $>"
    space
    SourcePos {sourceLine} <- getSourcePos
    expression <- takeWhile1P (Just "eval comment character") (/= '\n')
    pure
        Comment
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
multiLineEvalCommentP :: Parser Comment
multiLineEvalCommentP = do
    SourcePos {sourceLine} <- getSourcePos
    _ <- string "-- $$>"
    expression <- try multiLineExpr <|> inlineExpr
    pure
        Comment
            { expression
            , lineNumber = unPos sourceLine
            }
  where
    multiLineExpr = do
        _ <- optional (char '\n')
        lineContents <- manyTill commentLineP (try (string "-- <$$"))
        pure $ T.intercalate "\n" lineContents
    inlineExpr = do
        chars <- manyTill anySingle (string "<$$")
        pure $ T.strip (toText chars)
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
blockCommentEvalP :: Parser Comment
blockCommentEvalP = do
    SourcePos {sourceLine} <- getSourcePos
    _ <- string "{- $$>"
    _ <- optional (char '\n')
    chars <- manyTill anySingle (string "<$$ -}")
    pure
        Comment
            { expression = T.strip (toText chars)
            , lineNumber = unPos sourceLine
            }


type Parser = Parsec Void Text


data State
    = -- | The eval comment has yet to complete evaluation.
      Pending
    | -- | Combined stdout+stderr from GHCi, or an error message.
      Completed Text
    deriving stock (Eq, Generic, Show)


instance ToJSON State where
    toJSON = \case
        Pending ->
            toJSON
                $ KM.fromList
                    [ ("state", String "pending")
                    ]
        Completed output ->
            toJSON
                $ KM.fromList
                    [ ("state", String "completed")
                    , ("output", String output)
                    ]


instance FromJSON State where
    parseJSON = withObject "State" \o -> do
        state :: Text <- o .: "state"
        case state of
            "pending" -> pure $ Pending
            "completed" -> do
                output <- o .: "output"
                pure $ Completed output
            _ -> fail "invalid 'state' property"
