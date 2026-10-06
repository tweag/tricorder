module Tricorder.SourceLookup.Reexport
    ( reexportCandidates
    , exportsByName
    , declaresMember
    )
where

import Data.Char (isAlphaNum, isSpace, isUpper)
import Data.List (partition)
import Tricorder.SourceLookup.SourceQuery (ModuleName (..))

import Data.Text qualified as T

import Tricorder.SourceLookup.Slice (sliceSymbol)


reexportCandidates :: Text -> Text -> [ModuleName]
reexportCandidates symbol source =
    case moduleHeader stripped of
        Nothing -> []
        Just (self, exports) ->
            let imports = filter ((/= self) . (.modName)) (moduleImports stripped)
                routes = mapMaybe (exportRoute symbol definedLocally) exports
                matching = filter (\i -> any (routeMatches symbol i) routes) imports
                (strong, weak) = partition (namesSymbol symbol) matching
            in  ordNub (map (.modName) (strong <> weak))
  where
    stripped = stripComments source
    definedLocally n = isJust (sliceSymbol n source)


exportsByName :: Text -> Text -> Bool
exportsByName symbol source =
    case moduleHeader (stripComments source) of
        Nothing -> False
        Just (_, exports) -> any names exports
  where
    names = \case
        NameItem _ n subs -> n == symbol || symbol `elem` subs
        ModuleItem _ -> False


declaresMember :: Text -> Text -> Bool
declaresMember symbol source =
    case moduleHeader (stripComments source) of
        Nothing -> False
        Just (_, exports) -> any isLocalMember exports
  where
    isLocalMember = \case
        NameItem Nothing n subs
            | n /= symbol
            , symbol `elem` subs || ".." `elem` subs
            , Just decl <- sliceSymbol n source ->
                mentions decl
        _ -> False
    -- The symbol leads a line of the declaration (a method or field signature,
    -- a default method, a GADT constructor, a further @|@ alternative), heads a
    -- constructor alternative of the @data@ line, or is one of several names
    -- sharing a signature (@foo, bar :: …@). A mere use in a body does not count.
    mentions decl = any declares (T.lines decl)
    declares line =
        let sig = fst (T.breakOn "::" line)
            alternatives = drop 1 (T.split (`elem` ("=|" :: String)) (fst (T.breakOn "where" line)))
        in  leading line == symbol
                || ("::" `T.isInfixOf` line && symbol `elem` map leading (T.splitOn "," sig))
                || (isDataHead line && symbol `elem` map leading alternatives)
    isDataHead line = any (`T.isPrefixOf` line) ["data ", "newtype "]
    leading t =
        let s = T.dropWhile (\c -> isSpace c || c `elem` ("{,|" :: String)) t
        in  case T.stripPrefix "(" s of
                Just op -> T.strip (T.takeWhile (/= ')') op)
                Nothing -> T.takeWhile isIdentChar s


-- | One entry of an export or import list.
data Item
    = -- | A name, its optional qualifier, and its sub-list (@..@ for a wildcard).
      NameItem (Maybe Text) Text [Text]
    | -- | A @module M@ entry.
      ModuleItem Text


-- | How an export entry could carry the symbol out of the module.
data Route
    = -- | Via the named entity (under an optional qualifier).
      ViaName (Maybe Text) Text
    | -- | Via a @module M@ export.
      ViaModule Text


exportRoute :: Text -> (Text -> Bool) -> Item -> Maybe Route
exportRoute symbol definedLocally = \case
    NameItem q n subs
        | n == symbol -> Just (ViaName q n)
        | symbol `elem` subs || ".." `elem` subs, not (definedLocally n) -> Just (ViaName q n)
        | otherwise -> Nothing
    ModuleItem m -> Just (ViaModule m)


-- | Whether an import could bring @symbol@ into scope along a route.
routeMatches :: Text -> Import -> Route -> Bool
routeMatches symbol i = \case
    ViaName Nothing n -> not i.qualified && carries n
    ViaName (Just q) n -> q == scopeName i && carries n
    ViaModule m ->
        not i.qualified
            && (m == scopeName i || m == unModuleName i.modName)
            && (provides symbol i || hasWildcard i)
  where
    -- The import brings in the exported entity @n@ (or the symbol directly),
    -- and does not hide the symbol itself.
    carries n = (provides n i || provides symbol i) && not (i.hiding && namedIn i)
    namedIn imp = symbol `elem` concatMap itemNames (fromMaybe [] imp.items)
    hasWildcard imp = case imp.items of
        Just its | not imp.hiding -> any isWildcard its
        _ -> False
    isWildcard = \case
        NameItem _ _ subs -> ".." `elem` subs
        ModuleItem _ -> False


data Import = Import
    { modName :: ModuleName
    , qualified :: Bool
    , alias :: Maybe Text
    , hiding :: Bool
    , items :: Maybe [Item]
    }


scopeName :: Import -> Text
scopeName i = fromMaybe (unModuleName i.modName) i.alias


provides :: Text -> Import -> Bool
provides name i = case i.items of
    Nothing -> True
    Just its
        | i.hiding -> name `notElem` concatMap itemNames its
        | otherwise -> name `elem` concatMap itemNames its


namesSymbol :: Text -> Import -> Bool
namesSymbol symbol i = case i.items of
    Just its | not i.hiding -> symbol `elem` concatMap itemNames its
    _ -> False


itemNames :: Item -> [Text]
itemNames = \case
    NameItem _ n subs -> n : filter (/= "..") subs
    ModuleItem _ -> []


moduleImports :: Text -> [Import]
moduleImports = mapMaybe parseImport . groupImports . T.lines
  where
    groupImports [] = []
    groupImports (l : ls)
        | isImportLine l =
            let (cont, rest) = span isContinuation ls
            in  T.unwords (l : cont) : groupImports rest
        | otherwise = groupImports ls
    isImportLine l = case T.stripPrefix "import" l of
        Just rest -> maybe True (isSpace . fst) (T.uncons rest)
        Nothing -> False
    isContinuation l = case T.uncons l of
        Nothing -> True
        Just (c, _) -> isSpace c


parseImport :: Text -> Maybe Import
parseImport decl = do
    afterImport <- T.stripPrefix "import" decl
    let (preQualified, afterPre) = skipPrefixes False (T.strip afterImport)
        (name, afterName) = T.span isModuleChar afterPre
    guard (not (T.null name))
    pure
        $ parseSuffix
            Import
                { modName = ModuleName name
                , qualified = preQualified
                , alias = Nothing
                , hiding = False
                , items = Nothing
                }
            (T.strip afterName)
  where
    -- @safe@, @qualified@, @{-# SOURCE #-}@ (already stripped), and a
    -- package-import string may precede the module name.
    skipPrefixes q t
        | Just rest <- T.stripPrefix "\"" t =
            skipPrefixes q (T.strip (T.drop 1 (T.dropWhile (/= '"') rest)))
        | otherwise = case T.breakOn " " t of
            ("safe", rest) -> skipPrefixes q (T.strip rest)
            ("qualified", rest) -> skipPrefixes True (T.strip rest)
            _ -> (q, t)
    parseSuffix i t
        | T.null t = i
        | "(" `T.isPrefixOf` t = case balanced t of
            Just (inner, rest) ->
                parseSuffix i {items = Just (mapMaybe parseItem (splitTopCommas inner))} (T.strip rest)
            Nothing -> i
        | otherwise =
            let (w, rest) = T.break (\c -> isSpace c || c == '(') t
            in  case w of
                    "qualified" -> parseSuffix i {qualified = True} (T.strip rest)
                    "hiding" -> parseSuffix i {hiding = True} (T.strip rest)
                    "as" ->
                        let (a, rest') = T.span isModuleChar (T.strip rest)
                        in  parseSuffix i {alias = Just a} (T.strip rest')
                    _ -> i


moduleHeader :: Text -> Maybe (ModuleName, [Item])
moduleHeader src = do
    afterModule <- viaNonEmpty head (mapMaybe startsModule (lineStarts src))
    let (name, rest) = T.span isModuleChar (T.strip afterModule)
    guard (not (T.null name))
    (inner, _) <- balanced (T.strip rest)
    pure (ModuleName name, mapMaybe parseItem (splitTopCommas inner))
  where
    -- The text after a column-0 @module@ keyword.
    startsModule l = case T.stripPrefix "module" l of
        Just rest | maybe False (isSpace . fst) (T.uncons rest) -> Just rest
        _ -> Nothing


lineStarts :: Text -> [Text]
lineStarts t = t : go t
  where
    go s = case T.breakOn "\n" s of
        (_, rest) | T.null rest -> []
        (_, rest) -> let s' = T.drop 1 rest in s' : go s'


parseItem :: Text -> Maybe Item
parseItem raw
    | T.null t = Nothing
    | Just rest <- T.stripPrefix "module " t =
        Just (ModuleItem (T.takeWhile isModuleChar (T.strip rest)))
    | otherwise = do
        let t' = dropNamespace t
        (name, rest) <-
            if "(" `T.isPrefixOf` t'
                then first T.strip <$> balanced t'
                else Just (T.break (\c -> isSpace c || c == '(') t')
        guard (not (T.null name))
        let subs = case balanced (T.strip rest) of
                Just (inner, _) -> map (unparen . T.strip) (splitTopCommas inner)
                Nothing -> []
            (q, n) = splitQualified name
        pure (NameItem q n subs)
  where
    t = T.strip raw
    dropNamespace s = fromMaybe s (asum [T.strip <$> T.stripPrefix p s | p <- ["type ", "pattern "]])
    unparen s = maybe s (T.strip . fst) (balanced s)


-- | Split a qualified name such as @T.pack@ or @Data.Text.Text@ into its
-- qualifier and its base name.
splitQualified :: Text -> (Maybe Text, Text)
splitQualified name =
    case T.splitOn "." name of
        segs@(_ : _ : _)
            | Just (quals, base) <- unsnoc segs
            , not (T.null base)
            , all isConid quals ->
                (Just (T.intercalate "." quals), base)
        _ -> (Nothing, name)
  where
    isConid s = maybe False (\(c, rest) -> isUpper c && T.all isIdentChar rest) (T.uncons s)
    unsnoc xs = (,) <$> viaNonEmpty init xs <*> viaNonEmpty last xs


-- | Given text starting with @(@, the contents up to the matching @)@ and the
-- text after it.
balanced :: Text -> Maybe (Text, Text)
balanced t = do
    rest <- T.stripPrefix "(" t
    let go :: Int -> Int -> String -> Maybe Int
        go _ _ [] = Nothing
        go depth n (c : cs)
            | c == ')' && depth == 0 = Just n
            | c == ')' = go (depth - 1) (n + 1) cs
            | c == '(' = go (depth + 1) (n + 1) cs
            | otherwise = go depth (n + 1) cs
    n <- go 0 0 (toString rest)
    pure (T.take n rest, T.drop (n + 1) rest)


splitTopCommas :: Text -> [Text]
splitTopCommas = map toText . go (0 :: Int) [] . toString
  where
    go _ acc [] = [reverse acc]
    go depth acc (c : cs)
        | c == ',' && depth == 0 = reverse acc : go depth [] cs
        | c == '(' = go (depth + 1) (c : acc) cs
        | c == ')' = go (depth - 1) (c : acc) cs
        | otherwise = go depth (c : acc) cs


stripComments :: Text -> Text
stripComments = toText . code . toString
  where
    code [] = []
    code ('{' : '-' : cs) = ' ' : block (1 :: Int) cs
    code ('"' : cs) = '"' : str cs
    code ('\'' : '\\' : cs) = let (lit, rest) = break (== '\'') cs in '\'' : '\\' : lit <> code rest
    code ('\'' : c : '\'' : cs) = '\'' : c : '\'' : code cs
    code s@(c : _)
        | isIdentChar c = let (ident, rest) = span isIdentChar s in ident <> code rest
        | isSymbolChar c =
            let (op, rest) = span isSymbolChar s
            in  if length op >= 2 && all (== '-') op
                    then code (dropWhile (/= '\n') rest)
                    else op <> code rest
    code (c : cs) = c : code cs

    block _ [] = []
    block depth ('-' : '}' : cs)
        | depth == 1 = code cs
        | otherwise = block (depth - 1) cs
    block depth ('{' : '-' : cs) = block (depth + 1) cs
    block depth ('\n' : cs) = '\n' : block depth cs
    block depth (_ : cs) = block depth cs

    str [] = []
    str ('\\' : c : cs) = '\\' : c : str cs
    str ('"' : cs) = '"' : code cs
    str (c : cs) = c : str cs


isIdentChar :: Char -> Bool
isIdentChar c = isAlphaNum c || c == '_' || c == '\''


isModuleChar :: Char -> Bool
isModuleChar c = isAlphaNum c || c == '_' || c == '\'' || c == '.'


isSymbolChar :: Char -> Bool
isSymbolChar c = c `elem` ("!#$%&*+./<=>?@\\^|-~:" :: String)
