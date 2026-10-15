module Tricorder.Daemon.Ghci.Result
    ( collectResult
    , collectResultCustom
    , reloadFailed
    , parseProgressLine
    , parseReload
    , extractTitle
    , toAbsolute
    , toRelative
    )
where

import Data.Char (isDigit, isSpace, toLower)
import System.FilePath (isAbsolute, makeRelative, normalise, splitDirectories, (</>))
import Text.Megaparsec
import Prelude hiding (many)

import Data.List qualified as List
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text qualified as T

import Tricorder.Build (Diagnostic (..), Severity (..))
import Tricorder.Daemon.Ghci.LineParser (LineStream (..))
import Tricorder.Daemon.Ghci.Load (Load)
import Tricorder.Daemon.Ghci.LoadResult (LoadResult (..))
import Tricorder.Daemon.Ghci.LoadedModule (LoadedModule (..))
import Tricorder.Daemon.Ghci.Loading (Loading)
import Tricorder.Daemon.Ghci.Message (Message (..))
import Tricorder.Daemon.Ghci.Position (Position (..))

import Tricorder.Daemon.Ghci.Diagnostic qualified as Diagnostic
import Tricorder.Daemon.Ghci.LineParser qualified as LineParser
import Tricorder.Daemon.Ghci.Load qualified as Load
import Tricorder.Daemon.Ghci.LoadOutcome qualified as LoadOutcome
import Tricorder.Daemon.Ghci.Loading qualified as Loading
import Tricorder.Daemon.Ghci.Path qualified as Path
import Tricorder.Daemon.Ghci.Severity qualified as Severity
import Tricorder.Daemon.Ghci.TextParser qualified as TextParser


-- ---------------------------------------------------------------------------
-- Line-level helpers
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- parseReload
-- ---------------------------------------------------------------------------

-- | Parse the output of @:reload@ from GHCi into structured items.
parseReload :: [Text] -> [Load]
parseReload ls =
    case parse (catMaybes <$> many Load.parser <* eof) "" (LineStream ls) of
        Right items -> items
        Left _ -> []


-- | Parse a single line as a "[N of M] Compiling …" progress event.
--
-- Returns 'Nothing' for any line that is not a loading line. Used to stream
-- progress updates as GHCi emits them, rather than parsing the whole reload
-- output after the fact.
parseProgressLine :: Text -> Maybe Loading
parseProgressLine line =
    let stripped = LineParser.stripAnsi line
    in  if "[" `T.isPrefixOf` stripped
            then case TextParser.run Load.textParser stripped of
                Just (Load.Loading l) -> Just l
                _ -> Nothing
            else
                Nothing


-- ---------------------------------------------------------------------------
-- Pure utilities (unchanged)
-- ---------------------------------------------------------------------------

-- | Make an absolute path relative to the given base directory, prefixed with @"./"@.
-- Paths already relative, or absolute paths outside @base@, are returned unchanged.
toRelative :: FilePath -> FilePath -> FilePath
toRelative base path
    | not (isAbsolute path) = path
    | otherwise = case splitDirectories (makeRelative base path) of
        (".." : _) -> path
        rel -> "." </> List.foldr1 (</>) rel


-- | Make a relative path absolute by prepending the given base directory.
-- Paths already absolute are returned unchanged.
toAbsolute :: FilePath -> FilePath -> FilePath
toAbsolute base path
    | isAbsolute path = path
    | otherwise = base </> path


-- | Assemble a 'LoadResult' from a project root, parsed reload items, the
-- @:show modules@ output, and the @:show targets@ output.
collectResultCustom :: FilePath -> [Load] -> [(Text, FilePath)] -> [Text] -> LoadResult
collectResultCustom projectRoot loads modules targets =
    let rel = toRelative projectRoot
        abs' = toAbsolute projectRoot
        compiledFiles = case [l.sourceFile | Load.Loading l <- loads] of
            [] -> Set.fromList (map (rel . snd) modules)
            fs -> Set.fromList (map rel fs)
        mkEntry (mn, fp) =
            ( normalise (abs' fp)
            , LoadedModule {relPath = rel fp, moduleName = mn}
            )
    in  LoadResult
            { moduleCount = length modules
            , compiledFiles
            , loadedModules = Map.fromList (map mkEntry modules)
            , targetNames = targets
            , diagnostics = toDiagnostics rel loads
            }


-- | Assemble a 'LoadResult' from the raw reload output plus the @:show
-- modules@ / @:show targets@ output.
--
-- This is 'collectResultCustom' wrapped with a safety net: if GHCi's reload
-- ended in a @Failed,@ summary but no error diagnostic was captured (e.g. a
-- location-less failure we don't otherwise attribute to a file), a synthetic
-- error diagnostic is appended so the build can never be reported as clean
-- while GHCi considers it failed.
collectResult :: FilePath -> [Text] -> [(Text, FilePath)] -> [Text] -> LoadResult
collectResult projectRoot reloadLines modules targets =
    let loads = parseReload reloadLines
        base = collectResultCustom projectRoot loads modules targets
        hasError = any (\d -> d.severity == SError) base.diagnostics
    in  if reloadFailed loads && not hasError
            then
                base {diagnostics = base.diagnostics ++ [Diagnostic.unattributedFailure]}
            else
                base


-- | Whether GHCi's load ended in failure, decided from the 'GSummary' items
-- 'parseReload' produces — the single place that classifies GHCi's terminal
-- @Ok, …@ / @Failed, …@ summary line.
--
-- GHCi emits the real summary last, after all compilation output. Output
-- produced /during/ the load (a Template Haskell splice, top-level IO run while
-- interpreting) can contain an earlier line that looks like a summary, so only
-- the /last/ 'GSummary' reflects the true outcome.
reloadFailed :: [Load] -> Bool
reloadFailed loads =
    case [outcome | Load.Summary outcome <- loads] of
        [] -> False
        outcomes -> List.last outcomes == LoadOutcome.LoadFailed


toDiagnostics :: (FilePath -> FilePath) -> [Load] -> [Diagnostic]
toDiagnostics rel loads = mapMaybe toMsg loads
  where
    -- Location-less messages (e.g. @<no location info>@, @<interactive>@) carry
    -- no source span. We keep the *errors* — a @<no location info>@ error is a
    -- genuine load failure (e.g. a home-unit GHC plugin that can't be loaded in
    -- @--enable-multi-repl@) and must not be silently dropped — but discard
    -- location-less warnings, which are just noise without a file to attach to.
    toMsg (Load.Message m) | Path.isLocationLess m.file, m.severity /= Severity.Error = Nothing
    toMsg (Load.Message m) =
        Just
            Diagnostic
                { severity = case m.severity of
                    Severity.Warning -> SWarning
                    Severity.Error -> SError
                , file = rel m.file
                , line = m.startPos.line
                , col = m.startPos.col
                , endLine = m.endPos.line
                , endCol = m.endPos.col
                , title = extractTitle (map toString m.messageLines)
                , text = unlines (map toText m.messageLines)
                }
    toMsg _ = Nothing


-- | Extract a short human-readable title from GHCi message lines.
--
-- The header line (@"file:line:col: severity: rest"@) is the first element.
-- The human-readable text is either:
--
--   * Inline, after @"error:"@ \/ @"warning:"@ in the header (old GHC style), or
--   * On subsequent indented lines (new GHC style, when header ends with a
--     diagnostic code such as @[GHC-83865]@ or @[-Wmissing-deriving-strategies]@).
--
-- Source-display lines (@"39 | ..."@, @"   | ^^^^"@) are skipped when
-- scanning body lines for content.
extractTitle :: [String] -> Text
extractTitle [] = ""
extractTitle (header : body) =
    fromMaybe (firstBodyLine body) $ inlineFromHeader $ toString $ LineParser.stripAnsi $ toText header
  where
    inlineFromHeader :: String -> Maybe Text
    inlineFromHeader h =
        let lower = map toLower h
        in  case headerAfter "error:" lower h <|> headerAfter "warning:" lower h of
                Nothing -> Nothing
                Just rest ->
                    let content = stripDiagCodes (dropWhile isSpace rest)
                    in  if null content then Nothing else Just (toText content)

    headerAfter :: String -> String -> String -> Maybe String
    headerAfter needle haystack original =
        fmap (\i -> drop (i + length needle) original)
            $ List.findIndex (needle `List.isPrefixOf`) (List.tails haystack)

    stripDiagCodes :: String -> String
    stripDiagCodes s = case dropWhile isSpace s of
        '[' : rest ->
            let after = dropWhile isSpace (drop 1 (dropWhile (/= ']') rest))
            in  stripDiagCodes after
        other -> other

    firstBodyLine :: [String] -> Text
    firstBodyLine xs =
        case [ t
             | x <- xs
             , let t = dropWhile isSpace (toString (LineParser.stripAnsi (toText x)))
             , not (null t)
             , not (isSourceLine t)
             ] of
            (t : _) -> toText t
            [] -> ""

    isSourceLine :: String -> Bool
    isSourceLine s = case dropWhile (\c -> isDigit c || c == ' ') s of
        ('|' : _) -> True
        _ -> not (null s) && all (\c -> c `elem` ("^~_ " :: String)) s
