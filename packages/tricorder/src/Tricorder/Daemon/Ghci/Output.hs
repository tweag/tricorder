module Tricorder.Daemon.Ghci.Output
    ( parseShowModules
    , parseShowTargets
    )
where

import Data.Char (isSpace)
import Text.Megaparsec
import Text.Megaparsec.Char (char)
import Prelude hiding (many)

import Data.Text qualified as T

import Tricorder.Daemon.Ghci.LineParser (LineParser, LineStream (..))
import Tricorder.Daemon.Ghci.TextParser (TextParser)

import Tricorder.Daemon.Ghci.LineParser qualified as LineParser
import Tricorder.Daemon.Ghci.TextParser qualified as TextParser


-- | Parse the output of @:show modules@ into (module name, file path) pairs.
parseShowModules :: [Text] -> [(Text, FilePath)]
parseShowModules ls =
    case parse (catMaybes <$> many showModuleLine <* eof) "" (LineStream ls) of
        Right items -> items
        Left _ -> []


-- | Parse or skip one line of @:show modules@ output.
showModuleLine :: LineParser (Maybe (Text, FilePath))
showModuleLine = do
    line <- anySingle
    pure $ TextParser.run showModuleLineP (LineParser.stripAnsi line)


showModuleLineP :: TextParser (Text, FilePath)
showModuleLineP = do
    modName <- takeWhile1P Nothing (not . isSpace)
    _ <- takeWhileP Nothing (/= '(')
    _ <- char '('
    _ <- char ' '
    filePath <- takeWhile1P Nothing (\c -> c /= ',' && c /= ')')
    pure (modName, toString (T.stripEnd filePath))


-- | Parse the output of @:show targets@.
--
-- Each line names one target. In @cabal repl --enable-multi-repl@ these are
-- dotted module names (e.g. @"Foo.Bar"@); in plain @ghci@ sessions they can
-- also be file paths. A leading @*@ marks the active interactive target and
-- is stripped. Blank lines are skipped.
parseShowTargets :: [Text] -> [Text]
parseShowTargets = mapMaybe parseLine
  where
    parseLine raw =
        let cleaned = T.strip $ T.dropWhile (== '*') $ T.strip $ LineParser.stripAnsi raw
        in  if T.null cleaned then Nothing else Just cleaned
