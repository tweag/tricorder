module Tricorder.Daemon.Ghci.LineParser
    ( LineStream (..)
    , LineParser
    , satisfyStripped
    , stripAnsi
    )
where

import Text.Megaparsec (Parsec, Stream (..), token)
import Prelude hiding (many)

import Data.Char qualified as Char
import Data.Text qualified as T


-- ---------------------------------------------------------------------------
-- LineStream: a Stream instance for [Text] where Token = Text
-- ---------------------------------------------------------------------------

-- | Wrapper so we can define Stream / VisualStream / TraversableStream for
--   a list of 'Text' lines without orphan-instance conflicts.
newtype LineStream = LineStream [Text]


instance Stream LineStream where
    type Token LineStream = Text
    type Tokens LineStream = [Text]
    tokenToChunk Proxy = pure
    tokensToChunk Proxy = id
    chunkToTokens Proxy = id
    chunkLength Proxy = length
    chunkEmpty Proxy = null
    take1_ (LineStream []) = Nothing
    take1_ (LineStream (t : ts)) = Just (t, LineStream ts)
    takeN_ n (LineStream s)
        | n <= 0 = Just ([], LineStream s)
        | null s = Nothing
        | otherwise = let (a, b) = splitAt n s in Just (a, LineStream b)
    takeWhile_ p (LineStream s) =
        let (a, b) = span p s in (a, LineStream b)


-- | Parser over a stream of 'Text' lines.
type LineParser = Parsec Void LineStream


-- | Consume a line whose stripped form satisfies the predicate.
-- Returns @(originalLine, strippedLine)@.
satisfyStripped :: (Text -> Bool) -> LineParser (Text, Text)
satisfyStripped p = token testLine mempty
  where
    testLine line =
        let stripped = stripAnsi line
        in  if p stripped then Just (line, stripped) else Nothing


-- | Strip ANSI escape sequences of the form @ESC [ \<params\> \<letter\>@.
stripAnsi :: Text -> Text
stripAnsi t = case T.uncons t of
    Nothing -> t
    Just ('\ESC', rest) -> case T.uncons rest of
        Just ('[', rest') ->
            let afterParams = T.dropWhile (not . Char.isAlpha) rest'
            in  stripAnsi (T.drop 1 afterParams)
        _ -> T.cons '\ESC' (stripAnsi rest)
    Just (c, rest) -> T.cons c (stripAnsi rest)
