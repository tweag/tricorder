module Tricorder.Daemon.Ghci.Load
    ( Load (..)
    , parser
    , textParser
    )
where

import Text.Megaparsec (anySingle, choice, satisfy, takeWhile1P, takeWhileP)
import Text.Megaparsec.Char (char, string)

import Data.Char qualified as Char
import Data.Text qualified as T
import Text.Megaparsec.Char.Lexer qualified as L

import Tricorder.Daemon.Ghci.LineParser (LineParser)
import Tricorder.Daemon.Ghci.LoadOutcome (LoadOutcome)
import Tricorder.Daemon.Ghci.Position (Position (..))
import Tricorder.Daemon.Ghci.TextParser (TextParser)

import Tricorder.Daemon.Ghci.Diagnostic qualified as Diagnostic
import Tricorder.Daemon.Ghci.LineParser qualified as LineParser
import Tricorder.Daemon.Ghci.LoadOutcome qualified as LoadOutcome
import Tricorder.Daemon.Ghci.Loading qualified as Ghci (Loading (..))
import Tricorder.Daemon.Ghci.Loading qualified as Ghci.Loading
import Tricorder.Daemon.Ghci.Message qualified as Ghci
import Tricorder.Daemon.Ghci.Severity qualified as Severity
import Tricorder.Daemon.Ghci.TextParser qualified as TextParser


-- | A structured item from GHCi's reload output.
data Load
    = Loading Ghci.Loading
    | Message Ghci.Message
    | LoadConfig FilePath
    | Summary LoadOutcome
    deriving stock (Eq, Show)


-- | Parse one item (or skip one line) from the reload output.
parser :: LineParser (Maybe Load)
parser =
    choice
        [ -- Pattern: "Loaded GHCi configuration from <path>"
          fmap Just $ do
            (_, stripped) <- LineParser.satisfyStripped ("Loaded GHCi configuration from " `T.isPrefixOf`)
            let file = toString $ T.drop (T.length "Loaded GHCi configuration from ") stripped
            pure (LoadConfig file)
        , -- Pattern: "[N of M] Compiling ..."
          do
            (_, stripped) <- LineParser.satisfyStripped ("[" `T.isPrefixOf`)
            pure (TextParser.run textParser stripped)
        , -- Pattern: terminal summary line "Ok, ..." / "Failed, ..."
          fmap Just $ do
            (_, stripped) <-
                LineParser.satisfyStripped (\s -> "Ok, " `T.isPrefixOf` s || "Failed, " `T.isPrefixOf` s)
            pure
                $ Summary
                $ if "Failed, " `T.isPrefixOf` stripped
                    then LoadOutcome.LoadFailed
                    else LoadOutcome.LoadSucceeded
        , -- Pattern: "<no location info>: error:"
          fmap Just $ do
            (origLine, _) <- LineParser.satisfyStripped ("<no location info>: error:" `T.isPrefixOf`)
            body <- many (satisfy isMessageBody)
            pure
                $ Message
                    Ghci.Message
                        { severity = Severity.Error
                        , file = "<no location info>"
                        , startPos = Position 0 0
                        , endPos = Position 0 0
                        , messageLines = origLine : body
                        }
        , -- Pattern: diagnostic "file:pos:severity: ..."
          do
            (origLine, stripped) <-
                LineParser.satisfyStripped
                    ( \s ->
                        not (T.null s)
                            && not (" " `T.isPrefixOf` s)
                            && not ("\t" `T.isPrefixOf` s)
                    )
            case TextParser.run Diagnostic.headerParser stripped of
                Nothing -> pure Nothing
                Just (fileT, sp, ep, afterPos) ->
                    let lower = T.toLower (T.stripStart afterPos)
                    in  case Severity.parse lower of
                            Nothing -> pure Nothing
                            Just sev -> do
                                body <- many (satisfy isMessageBody)
                                pure
                                    $ Just
                                    $ Message
                                        Ghci.Message
                                            { severity = sev
                                            , file = toString fileT
                                            , startPos = sp
                                            , endPos = ep
                                            , messageLines = origLine : body
                                            }
        , -- Fallback: skip any other line
          fmap (const Nothing) anySingle
        ]


-- | Parse a "[N of M] Compiling Mod ( file, ... )" loading line.
textParser :: TextParser Load
textParser = do
    _ <- char '['
    _ <- takeWhileP Nothing (== ' ')
    n <- L.decimal
    _ <- string " of "
    m <- L.decimal
    _ <- takeWhileP Nothing (== ' ')
    _ <- char ']'
    _ <- takeWhile1P Nothing (== ' ')
    _ <- string "Compiling"
    _ <- takeWhile1P Nothing (== ' ')
    modName <- takeWhile1P Nothing (not . Char.isSpace)
    _ <- takeWhileP Nothing (/= '(')
    _ <- char '('
    _ <- takeWhileP Nothing (== ' ')
    filePath <- takeWhile1P Nothing (\c -> c /= ',' && c /= ')')
    pure
        $ Loading
            Ghci.Loading
                { Ghci.Loading.index = n
                , Ghci.Loading.total = m
                , Ghci.Loading.moduleName = modName
                , Ghci.Loading.sourceFile = toString (T.stripEnd filePath)
                }


-- | Check if a line is a continuation of a diagnostic message body.
isMessageBody :: Text -> Bool
isMessageBody line =
    " " `T.isPrefixOf` line
        || "\t" `T.isPrefixOf` line
        || case T.break (== '|') line of
            (prefix, rest)
                | not (T.null rest) ->
                    T.all (\c -> Char.isSpace c || Char.isDigit c) prefix
            _ -> False
