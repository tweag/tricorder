module Tricorder.Daemon.GhciSession.GhciParser
    ( GhciLoad (..)
    , GhciLoading (..)
    , GhciMessage (..)
    , GhciSeverity (..)
    , LoadOutcome (..)
    , LoadResult (..)
    , LoadedModule (..)
    , Position (..)
    , collectResult
    , collectResultCustom
    , isLocationLess
    , reloadFailed
    , parseProgressLine
    , parseReload
    , parseShowModules
    , parseShowTargets
    , pathSuffixesAsModuleName
    , resolveKnownTargets
    , stripAnsi
    , extractTitle
    , toAbsolute
    , toRelative
    , unattributedFailure
    )
where

import Data.Char (isAlpha, isDigit, isSpace, toLower)
import System.FilePath (dropExtension, isAbsolute, makeRelative, normalise, splitDirectories, (</>))
import Text.Megaparsec
import Text.Megaparsec.Char (char, string)
import Prelude hiding (many)

import Data.List qualified as List
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text qualified as T
import Text.Megaparsec.Char.Lexer qualified as L

import Tricorder.Build (Diagnostic (..), Severity (..))


-- | Severity of a GHCi diagnostic message.
data GhciSeverity = GWarning | GError
    deriving stock (Eq, Ord, Show)


-- | Payload for a @[N of M] Compiling Mod ( file, ... )@ line.
data GhciLoading = GhciLoading
    { index :: Int
    -- ^ N (this module's index in the compilation sequence)
    , total :: Int
    -- ^ M (total modules to compile)
    , moduleName :: Text
    , sourceFile :: FilePath
    }
    deriving stock (Eq, Show)


-- | A source position (1-based line and column). @(0, 0)@ when unavailable.
data Position = Position
    { line :: Int
    , col :: Int
    }
    deriving stock (Eq, Show)


-- | Payload for a compiler diagnostic (error or warning).
data GhciMessage = GhciMessage
    { severity :: GhciSeverity
    , file :: FilePath
    , startPos :: Position
    , endPos :: Position
    -- ^ equals 'startPos' when no span
    , messageLines :: [Text]
    -- ^ raw lines (with any ANSI), header first
    }
    deriving stock (Eq, Show)


-- | The terminal summary GHCi emits to close a load: @Ok, N modules loaded.@
-- on success or @Failed, …@ on failure.
data LoadOutcome = LoadSucceeded | LoadFailed
    deriving stock (Eq, Show)


-- | A structured item from GHCi's reload output.
data GhciLoad
    = GLoading GhciLoading
    | GMessage GhciMessage
    | GLoadConfig FilePath
    | GSummary LoadOutcome
    deriving stock (Eq, Show)


-- | A module currently loaded in the GHCi session.
data LoadedModule = LoadedModule
    { relPath :: FilePath
    -- ^ Path relative to the project root (e.g. @"./src/Foo.hs"@).
    , moduleName :: Text
    }
    deriving stock (Eq, Show)


-- | The result of a GHCi load or reload operation.
data LoadResult = LoadResult
    { moduleCount :: Int
    , compiledFiles :: Set FilePath
    -- ^ Files compiled in this cycle (derived from 'GLoading' items).
    -- Used by the session layer to decide which files' previous diagnostics to replace vs. retain.
    , loadedModules :: Map FilePath LoadedModule
    -- ^ Map from canonical absolute path to module metadata, derived from @:show modules@ output.
    -- Lists only modules that compiled successfully this cycle — GHCi drops
    -- failed-compile modules from @:show modules@.
    , targetNames :: [Text]
    -- ^ Raw entries from @:show targets@ — typically dotted module names
    -- in @cabal repl --enable-multi-repl@. Unlike 'loadedModules' this
    -- survives failed compiles, so the Builder feeds it into
    -- @KnownTargetNames@ for the dispatcher's fallback lookup.
    , diagnostics :: [Diagnostic]
    }
    deriving stock (Eq, Show)


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


-- ---------------------------------------------------------------------------
-- Parser type aliases
-- ---------------------------------------------------------------------------

-- | Parser over a stream of 'Text' lines.
type LineParser = Parsec Void LineStream


-- | Parser over a single 'Text' value.
type TextParser = Parsec Void Text


-- ---------------------------------------------------------------------------
-- Text-level sub-parsers (helpers for diagnostic header parsing)
-- ---------------------------------------------------------------------------

-- | Run a 'TextParser' on a 'Text' value, returning 'Nothing' on failure.
runTP :: TextParser a -> Text -> Maybe a
runTP p t = case parse p "" t of
    Right x -> Just x
    Left _ -> Nothing


-- | Parse a GHCi position in one of the formats:
--   @(L1,C1)-(L2,C2):@, @L:C:@, or @L:C-C2:@.
-- Consumes the trailing colon.
positionP :: TextParser (Position, Position)
positionP = parenForm <|> simpleForm
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


-- | Parse the full diagnostic header:
--   @file:pos:@ or @drive:path:pos:@ for Windows.
-- Returns @(file, startPos, endPos, textAfterColon)@.
diagHeaderP :: TextParser (Text, Position, Position, Text)
diagHeaderP = do
    a <- takeWhile1P Nothing (/= ':')
    _ <- char ':'
    filePart <-
        if T.length a == 1 && isAlpha (T.head a) then do
            pathRest <- takeWhile1P Nothing (/= ':')
            _ <- char ':'
            pure (a <> ":" <> pathRest)
        else
            pure a
    (sp, ep) <- positionP
    afterPos <- getInput
    pure (filePart, sp, ep, afterPos)


-- ---------------------------------------------------------------------------
-- Line-level helpers
-- ---------------------------------------------------------------------------

-- | Check if a line is a continuation of a diagnostic message body.
isMessageBody :: Text -> Bool
isMessageBody line =
    " " `T.isPrefixOf` line
        || "\t" `T.isPrefixOf` line
        || case T.break (== '|') line of
            (prefix, rest)
                | not (T.null rest) ->
                    T.all (\c -> isSpace c || isDigit c) prefix
            _ -> False


-- | Consume a line whose stripped form satisfies the predicate.
-- Returns @(originalLine, strippedLine)@.
satisfyStripped :: (Text -> Bool) -> LineParser (Text, Text)
satisfyStripped p = token testLine mempty
  where
    testLine line =
        let stripped = stripAnsi line
        in  if p stripped then Just (line, stripped) else Nothing


-- ---------------------------------------------------------------------------
-- parseReload
-- ---------------------------------------------------------------------------

-- | Parse the output of @:reload@ from GHCi into structured items.
parseReload :: [Text] -> [GhciLoad]
parseReload ls =
    case parse (catMaybes <$> many reloadItem <* eof) "" (LineStream ls) of
        Right items -> items
        Left _ -> []


-- | Parse one item (or skip one line) from the reload output.
reloadItem :: LineParser (Maybe GhciLoad)
reloadItem =
    choice
        [ -- Pattern: "Loaded GHCi configuration from <path>"
          fmap Just $ do
            (_, stripped) <- satisfyStripped ("Loaded GHCi configuration from " `T.isPrefixOf`)
            let file = toString $ T.drop (T.length "Loaded GHCi configuration from ") stripped
            pure (GLoadConfig file)
        , -- Pattern: "[N of M] Compiling ..."
          do
            (_, stripped) <- satisfyStripped ("[" `T.isPrefixOf`)
            pure (runTP loadingLineP stripped)
        , -- Pattern: terminal summary line "Ok, ..." / "Failed, ..."
          fmap Just $ do
            (_, stripped) <-
                satisfyStripped (\s -> "Ok, " `T.isPrefixOf` s || "Failed, " `T.isPrefixOf` s)
            pure
                $ GSummary
                $ if "Failed, " `T.isPrefixOf` stripped then LoadFailed else LoadSucceeded
        , -- Pattern: "<no location info>: error:"
          fmap Just $ do
            (origLine, _) <- satisfyStripped ("<no location info>: error:" `T.isPrefixOf`)
            body <- many (satisfy isMessageBody)
            pure
                $ GMessage
                    GhciMessage
                        { severity = GError
                        , file = "<no location info>"
                        , startPos = Position 0 0
                        , endPos = Position 0 0
                        , messageLines = origLine : body
                        }
        , -- Pattern: diagnostic "file:pos:severity: ..."
          do
            (origLine, stripped) <-
                satisfyStripped
                    ( \s ->
                        not (T.null s)
                            && not (" " `T.isPrefixOf` s)
                            && not ("\t" `T.isPrefixOf` s)
                    )
            case runTP diagHeaderP stripped of
                Nothing -> pure Nothing
                Just (fileT, sp, ep, afterPos) ->
                    let lower = T.toLower (T.stripStart afterPos)
                    in  case parseSeverity lower of
                            Nothing -> pure Nothing
                            Just sev -> do
                                body <- many (satisfy isMessageBody)
                                pure
                                    $ Just
                                    $ GMessage
                                        GhciMessage
                                            { severity = sev
                                            , file = toString fileT
                                            , startPos = sp
                                            , endPos = ep
                                            , messageLines = origLine : body
                                            }
        , -- Fallback: skip any other line
          fmap (const Nothing) anySingle
        ]


-- | Parse a single line as a "[N of M] Compiling …" progress event.
--
-- Returns 'Nothing' for any line that is not a loading line. Used to stream
-- progress updates as GHCi emits them, rather than parsing the whole reload
-- output after the fact.
parseProgressLine :: Text -> Maybe GhciLoading
parseProgressLine line =
    let stripped = stripAnsi line
    in  if "[" `T.isPrefixOf` stripped then case runTP loadingLineP stripped of
            Just (GLoading l) -> Just l
            _ -> Nothing
        else
            Nothing


-- | Parse a "[N of M] Compiling Mod ( file, ... )" loading line.
loadingLineP :: TextParser GhciLoad
loadingLineP = do
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
    modName <- takeWhile1P Nothing (not . isSpace)
    _ <- takeWhileP Nothing (/= '(')
    _ <- char '('
    _ <- takeWhileP Nothing (== ' ')
    filePath <- takeWhile1P Nothing (\c -> c /= ',' && c /= ')')
    pure
        $ GLoading
            GhciLoading
                { index = n
                , total = m
                , moduleName = modName
                , sourceFile = toString (T.stripEnd filePath)
                }


-- | Determine severity from the text after the position (lowercased, stripped).
parseSeverity :: Text -> Maybe GhciSeverity
parseSeverity lower
    | "warning:" `T.isPrefixOf` lower = Just GWarning
    | "error:" `T.isPrefixOf` lower = Just GError
    | otherwise = Nothing


-- ---------------------------------------------------------------------------
-- parseShowModules
-- ---------------------------------------------------------------------------

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
    pure $ runTP showModuleLineP (stripAnsi line)


showModuleLineP :: TextParser (Text, FilePath)
showModuleLineP = do
    modName <- takeWhile1P Nothing (not . isSpace)
    _ <- takeWhileP Nothing (/= '(')
    _ <- char '('
    _ <- char ' '
    filePath <- takeWhile1P Nothing (\c -> c /= ',' && c /= ')')
    pure (modName, toString (T.stripEnd filePath))


-- ---------------------------------------------------------------------------
-- parseShowTargets
-- ---------------------------------------------------------------------------

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
        let cleaned = T.strip (T.dropWhile (== '*') (T.strip (stripAnsi raw)))
        in  if T.null cleaned then Nothing else Just cleaned


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


-- | Candidate dotted module names for a file path.
--
-- We can't convert dotted target names to paths without cabal's
-- source-dirs, so callers check the other direction: any uppercase-segment
-- suffix of the path (with @/@ → @.@, extension dropped) is a candidate.
-- E.g. @./tricorder/src/Tricorder/Version.hs@ yields candidates
-- @"Tricorder.Version"@ and @"Version"@.
pathSuffixesAsModuleName :: FilePath -> [Text]
pathSuffixesAsModuleName fp =
    let segments = filter (not . null) (splitDirectories (dropExtension (normalise fp)))
        upperSegments = dropWhile (not . startsUpper) segments
        suffixes = takeWhile (not . null) (iterate (drop 1) upperSegments)
    in  [T.intercalate "." (map toText s) | s <- suffixes]
  where
    startsUpper (c : _) = c >= 'A' && c <= 'Z'
    startsUpper _ = False


-- | Strip ANSI escape sequences of the form @ESC [ \<params\> \<letter\>@.
stripAnsi :: Text -> Text
stripAnsi t = case T.uncons t of
    Nothing -> t
    Just ('\ESC', rest) -> case T.uncons rest of
        Just ('[', rest') ->
            let afterParams = T.dropWhile (not . isAlpha) rest'
            in  stripAnsi (T.drop 1 afterParams)
        _ -> T.cons '\ESC' (stripAnsi rest)
    Just (c, rest) -> T.cons c (stripAnsi rest)


-- | Assemble a 'LoadResult' from a project root, parsed reload items, the
-- @:show modules@ output, and the @:show targets@ output.
collectResultCustom :: FilePath -> [GhciLoad] -> [(Text, FilePath)] -> [Text] -> LoadResult
collectResultCustom projectRoot loads modules targets =
    let rel = toRelative projectRoot
        abs' = toAbsolute projectRoot
        compiledFiles = case [l.sourceFile | GLoading l <- loads] of
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
    in  if reloadFailed loads && not hasError then
            base {diagnostics = base.diagnostics ++ [unattributedFailure]}
        else
            base


-- | Synthetic diagnostic for a failed load with no located error. Without a
-- source span it cannot point anywhere, but it stops the build reading as
-- clean and tells the user where to look.
unattributedFailure :: Diagnostic
unattributedFailure =
    Diagnostic
        { severity = SError
        , file = "<no location info>"
        , line = 0
        , col = 0
        , endLine = 0
        , endCol = 0
        , title = "GHCi reported a failed load with no located error"
        , text = "GHCi reported a failed load with no located error.\nRun `tricorder log` to see the full GHCi output.\n"
        }


-- | Whether GHCi's load ended in failure, decided from the 'GSummary' items
-- 'parseReload' produces — the single place that classifies GHCi's terminal
-- @Ok, …@ / @Failed, …@ summary line.
--
-- GHCi emits the real summary last, after all compilation output. Output
-- produced /during/ the load (a Template Haskell splice, top-level IO run while
-- interpreting) can contain an earlier line that looks like a summary, so only
-- the /last/ 'GSummary' reflects the true outcome.
reloadFailed :: [GhciLoad] -> Bool
reloadFailed loads =
    case [outcome | GSummary outcome <- loads] of
        [] -> False
        outcomes -> List.last outcomes == LoadFailed


-- | Whether a diagnostic file is a GHCi location-less pseudo-file — a fully
-- @\<…\>@-bracketed marker such as @\<no location info\>@ or @\<interactive\>@
-- rather than a real source path. These carry no source span but can still
-- represent genuine build-level failures, so callers treat them specially
-- (kept rather than dropped, cleared every cycle rather than retained).
--
-- We require both the opening @\<@ and a closing @\>@ so a real (if exotic)
-- path that merely starts with @\<@, e.g. @\<generated\>/Foo.hs@, is not
-- mistaken for a marker.
isLocationLess :: FilePath -> Bool
isLocationLess f = "<" `List.isPrefixOf` f && ">" `List.isSuffixOf` f


-- | Path↔module-name map for the next cycle: this round's @:show modules@
-- plus carryover from @prev@ for targets that failed mid-session and so
-- dropped out. Never-compiled targets are absent here (no path↔name
-- mapping); the dispatcher recognises those via 'KnownTargetNames'.
resolveKnownTargets
    :: Map FilePath LoadedModule
    -- ^ Previous known-targets map (carryover source).
    -> LoadResult
    -> Map FilePath LoadedModule
resolveKnownTargets prev lr =
    let primary = lr.loadedModules
        primaryNames = Set.fromList [lm.moduleName | lm <- Map.elems primary]
        prevByName = Map.fromList [(lm.moduleName, (path, lm)) | (path, lm) <- Map.toList prev]
        carryover =
            Map.fromList
                [ (path, lm)
                | name <- lr.targetNames
                , not (Set.member name primaryNames)
                , Just (path, lm) <- [Map.lookup name prevByName]
                ]
    in  Map.union primary carryover


toDiagnostics :: (FilePath -> FilePath) -> [GhciLoad] -> [Diagnostic]
toDiagnostics rel loads = mapMaybe toMsg loads
  where
    -- Location-less messages (e.g. @<no location info>@, @<interactive>@) carry
    -- no source span. We keep the *errors* — a @<no location info>@ error is a
    -- genuine load failure (e.g. a home-unit GHC plugin that can't be loaded in
    -- @--enable-multi-repl@) and must not be silently dropped — but discard
    -- location-less warnings, which are just noise without a file to attach to.
    toMsg (GMessage m) | isLocationLess m.file, m.severity /= GError = Nothing
    toMsg (GMessage m) =
        Just
            Diagnostic
                { severity = case m.severity of
                    GWarning -> SWarning
                    GError -> SError
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
    fromMaybe (firstBodyLine body) (inlineFromHeader (toString (stripAnsi (toText header))))
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
             , let t = dropWhile isSpace (toString (stripAnsi (toText x)))
             , not (null t)
             , not (isSourceLine t)
             ] of
            (t : _) -> toText t
            [] -> ""

    isSourceLine :: String -> Bool
    isSourceLine s = case dropWhile (\c -> isDigit c || c == ' ') s of
        ('|' : _) -> True
        _ -> not (null s) && all (\c -> c `elem` ("^~_ " :: String)) s
