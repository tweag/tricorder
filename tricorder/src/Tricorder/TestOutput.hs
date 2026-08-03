module Tricorder.TestOutput (parseHspecOutput, parseHspecDuration, stripGhciNoise) where

import Atelier.Time (Millisecond, fromMicroseconds)
import Data.Char (isDigit)

import Data.Text qualified as T

import Tricorder.Build.Test qualified as Test


-- | Parse hspec output into individual test case results.
--
-- Recognises lines ending with @OK@ or @FAIL@ (right-aligned, space-padded),
-- with or without a trailing timing annotation like @(0.05s)@ or @(120ms)@.
-- For failing tests, collects the indented detail lines that follow as the
-- failure message.
parseHspecOutput :: Text -> [Test.Case]
parseHspecOutput = go . T.lines
  where
    go [] = []
    go (l : ls)
        | T.isSuffixOf "OK" norm =
            Test.Case {description = extractDesc "OK" norm, outcome = Test.Passed}
                : go ls
        | T.isSuffixOf "FAIL" norm =
            let (detailLines, rest) = span (\dl -> indentOf dl > indentOf l) ls
                details = T.intercalate "\n" $ filter (not . T.null) $ map T.strip detailLines
            in  Test.Case {description = extractDesc "FAIL" norm, outcome = Test.Failed details}
                    : go rest
        | otherwise = go ls
      where
        norm = stripTimingAnnotation (T.stripEnd l)

    extractDesc suffix l =
        T.strip $ T.dropEnd (T.length suffix) $ T.stripEnd l

    indentOf = T.length . T.takeWhile (== ' ')


-- | Strip a trailing hspec timing annotation of the form @" (0.05s)"@ or @" (120ms)"@.
--
-- Scans from the end of the line: strips the closing @)@, walks backwards
-- through digits, @.@, @s@, @m@, @μ@, then requires @(@ followed by a space.
-- Returns the input unchanged if the suffix does not match this pattern.
stripTimingAnnotation :: Text -> Text
stripTimingAnnotation t
    | T.null t || T.last t /= ')' = t
    | otherwise =
        let withoutClose = T.init t
            (timePart, rest) = T.span (\c -> isDigit c || c `elem` (".smμ" :: [Char])) (T.reverse withoutClose)
        in  if T.null timePart then
                t
            else case T.uncons rest of
                Just ('(', afterParen) ->
                    case T.uncons afterParen of
                        Just (' ', desc) -> T.stripEnd (T.reverse desc)
                        _ -> t
                _ -> t


-- | Extract the test suite duration from hspec summary output.
-- Matches non-indented summary lines ending with @"(Xs)"@,
-- e.g. @"All 160 tests passed (0.33s)"@ or @"1 out of 177 tests failed (0.06s)"@.
parseHspecDuration :: Text -> Maybe Millisecond
parseHspecDuration output =
    listToMaybe $ mapMaybe extractMs (T.lines output)
  where
    extractMs line = do
        guard $ not (T.isPrefixOf " " line)
        guard $ T.isSuffixOf "s)" line
        let numStr = T.takeWhileEnd (/= '(') (T.dropEnd 2 line)
        secs <- readMaybe (T.unpack numStr) :: Maybe Double
        pure $ fromMicroseconds (round (secs * 1_000_000))


-- | Strip GHCi/cabal startup and shutdown noise from captured output lines.
stripGhciNoise :: [Text] -> [Text]
stripGhciNoise ls =
    case dropWhile (not . T.isPrefixOf "ghci> ") ls of
        [] -> ls
        _ : afterPrompt -> reverse $ dropWhile isGhciNoiseLine $ reverse afterPrompt


isGhciNoiseLine :: Text -> Bool
isGhciNoiseLine l =
    T.isPrefixOf "ghci>" l
        || l == "Leaving GHCi."
        || T.isPrefixOf "*** Exception: " l
