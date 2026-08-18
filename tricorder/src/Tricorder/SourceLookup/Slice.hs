-- | A pure, lexical source slicer.
--
-- It is deliberately /lexical/. It reasons about column-0 anchors, leading
-- keywords, and blank-line boundaries; it never builds a real Haskell AST. That
-- keeps it robust to CPP, unknown language extensions, and exotic syntax: a
-- shape it cannot make sense of simply yields 'Nothing', and the caller falls
-- back to the whole module (or reports the symbol as not found). It never
-- throws.
module Tricorder.SourceLookup.Slice
    ( sliceSymbol
    )
where

import Data.Char (isAlphaNum, isSpace, isUpper)

import Data.List qualified as List
import Data.Text qualified as T


-- | Slice the declaration that introduces @symbol@ from @source@.
--
-- Returns the top-level declaration that introduces the symbol: the declaration
-- head, any type signature directly above it, and the contiguous doc-comment
-- block above that — terminating at the blank line or the next top-level
-- declaration that ends it. 'Nothing' when no introducing declaration is found.
sliceSymbol :: Text -> Text -> Maybe Text
sliceSymbol symbol source
    | T.null symbol = Nothing
    | otherwise =
        let ls = T.lines source
        in  if isTypeSymbol symbol then
                sliceType symbol ls <|> sliceConstructor symbol ls
            else
                sliceValue symbol ls


-- | Evaluate whether the symbol references a type-level entity.
isTypeSymbol :: Text -> Bool
isTypeSymbol = maybe False (isUpper . fst) . T.uncons


-- ── Value bindings ─────────────────────────────────────────────────────────

-- | Slice the value binding introducing @name@ (a function, CAF, or operator).
sliceValue :: Text -> [Text] -> Maybe Text
sliceValue name ls =
    (\i -> expandAt (belongsToValue name) i ls) <$> List.findIndex (introducesValue name) ls


-- | Whether a line introduces the value @name@ at column 0 — its type
-- signature, an equation head, or a bare binding. Operators are matched in
-- their parenthesised @(op)@ form.
introducesValue :: Text -> Text -> Bool
introducesValue name line =
    isCol0 line
        && ( leadingIdent line == name
                || ("(" <> name <> ")") `T.isPrefixOf` line
           )


-- | Whether a column-0 line below the anchor still belongs to the value binding
-- for @name@: a further equation or signature (same leading identifier or
-- @(name)@ head), or — for an operator — an infix equation whose left-hand side
-- uses it (e.g. @a \<+\> b = …@, which leads with the argument rather than the
-- operator).
belongsToValue :: Text -> Text -> Bool
belongsToValue name line =
    introducesValue name line
        || (isOperatorName name && usesOperatorInHead name line)


-- | Whether @line@ is an equation whose left-hand side applies operator @name@
-- infix. The head is the text before the first @=@; the operator must appear
-- there as a whitespace-delimited token, so an unrelated binding that merely
-- mentions the operator in its /body/ (@merge x y = x \<+\> y@) is excluded.
usesOperatorInHead :: Text -> Text -> Bool
usesOperatorInHead name line =
    (" " <> name <> " ") `T.isInfixOf` (" " <> T.strip head_ <> " ")
  where
    head_ = fst (T.breakOn "=" line)


-- | Whether @name@ is an operator (its first character is not identifier-like).
isOperatorName :: Text -> Bool
isOperatorName = maybe False (not . isIdentChar . fst) . T.uncons


-- ── Type / class declarations ──────────────────────────────────────────────

-- | Slice the type-level declaration head introducing @name@. A type\/class
-- body is entirely indented, so no column-0 line below the head belongs to it.
sliceType :: Text -> [Text] -> Maybe Text
sliceType name ls =
    (\i -> expandAt (const False) i ls) <$> List.findIndex (introducesType name) ls


-- | Whether a column-0 line is a declaration head for the type-level @name@.
introducesType :: Text -> Text -> Bool
introducesType name line =
    isCol0 line
        && case T.words line of
            ("data" : "family" : n : _) -> tok n == name
            ("type" : "family" : n : _) -> tok n == name
            ("data" : n : _) -> tok n == name
            ("newtype" : n : _) -> tok n == name
            ("type" : n : _) -> tok n == name
            ("class" : ws) -> maybe False ((== name) . tok) (classHead ws)
            _ -> False
  where
    tok = T.takeWhile isIdentChar


-- | The class name from the words following the @class@ keyword: the first word
-- after the superclass context (the last @=>@), or the very first word when
-- there is no context. So @class Eq a => Ord a where@ yields @Ord@, not the
-- superclass @Eq@.
classHead :: [Text] -> Maybe Text
classHead ws =
    case break (== "=>") (reverse (takeWhile (/= "where") ws)) of
        (afterContext, _ : _) -> viaNonEmpty last afterContext
        (_, []) -> listToMaybe ws


-- | Slice the @data@ \/ @newtype@ declaration whose body defines @name@ as a
-- constructor, returning that whole declaration block. Used as a fallback for
-- uppercase queries that do not name a type head.
sliceConstructor :: Text -> [Text] -> Maybe Text
sliceConstructor name ls =
    List.find (mentionsConstructor name) (map (\i -> expandAt (const False) i ls) dataHeads)
  where
    dataHeads = List.findIndices isDataNewtypeHead ls


-- | Whether a column-0 line opens a @data@ or @newtype@ declaration.
isDataNewtypeHead :: Text -> Bool
isDataNewtypeHead line =
    isCol0 line
        && case T.words line of
            ("data" : _) -> True
            ("newtype" : _) -> True
            _ -> False


-- | Whether a declaration block defines @name@ as a constructor. Lexical and
-- approximate, but it looks only at /constructor positions/ — the leading token
-- of each @|@-separated alternative in an ADT, or the names before @::@ in a
-- GADT — so a mention of @name@ as a field type or inside a doc comment does not
-- count, and we do not return a @data@ block that merely references it.
mentionsConstructor :: Text -> Text -> Bool
mentionsConstructor name block = name `elem` constructorNames block


-- | The constructor names introduced by a @data@ \/ @newtype@ block, ignoring
-- doc comments. Handles both ADT syntax (@= A x | B y@) and GADT syntax
-- (@A, B :: …@ lines under a @where@ head).
constructorNames :: Text -> [Text]
constructorNames block =
    case filter (not . isCommentLine) (T.lines block) of
        [] -> []
        code@(headLine : rest)
            | "where" `elem` T.words headLine -> concatMap gadtCons rest
            | otherwise -> adtCons (T.unwords code)
  where
    -- ADT: names lead each alternative after the first @=@.
    adtCons decl =
        let rhs = T.drop 1 (T.dropWhile (/= '=') decl)
        in  mapMaybe (leadingCon . T.stripStart) (T.splitOn "|" rhs)
    -- GADT: @Con1, Con2 :: …@ — names before the @::@.
    gadtCons line
        | "::" `T.isInfixOf` line =
            mapMaybe (leadingCon . T.strip) (T.splitOn "," (fst (T.breakOn "::" line)))
        | otherwise = []
    leadingCon t = case leadingIdent t of
        "" -> Nothing
        ident -> Just ident


-- ── Block expansion ────────────────────────────────────────────────────────

-- | Expand the declaration anchored at line index @i@ into its full slice: the
-- contiguous doc-comment block above @i@, then the declaration from @i@ down to
-- (but not including) the next top-level declaration.
--
-- The block ends at the next top-level (column-0) declaration. Indented lines,
-- blank lines, and CPP directives all continue it — so a blank line inside a
-- @where@ clause or between guards does not truncate the slice — while
-- @sameDecl@ recognises the column-0 lines that also continue it (further
-- equations of a value binding, or an operator's infix body). Trailing blank
-- lines picked up before the boundary are trimmed off.
expandAt :: (Text -> Bool) -> Int -> [Text] -> Text
expandAt sameDecl i ls =
    let (before, rest) = splitAt i ls
        docBlock = docCommentAbove before
        body = case rest of
            [] -> []
            (hd : tl) -> hd : takeWhile continuesBody tl
    in  T.intercalate "\n" (docBlock <> dropTrailingBlanks body)
  where
    continuesBody line =
        isBlank line
            || not (isCol0 line)
            || isCppLine line
            || sameDecl line
    dropTrailingBlanks = reverse . dropWhile isBlank . reverse


-- | The contiguous doc-comment block immediately above a declaration, in source
-- order. Handles line comments (@--@) and multi-line block comments
-- (@{- … -}@), whose interior and closing lines are not themselves
-- comment-prefixed. Stops at the first non-comment (or blank) line.
docCommentAbove :: [Text] -> [Text]
docCommentAbove before = reverse (takeDoc (reverse before))
  where
    takeDoc [] = []
    takeDoc (l : ls)
        | isCommentLine l = l : takeDoc ls
        | closesBlockComment l =
            let (blockBody, ls') = consumeToBlockOpen ls
            in  (l : blockBody) <> takeDoc ls'
        | otherwise = []
    -- Consume upward (source-reversed) until the line that opens the block.
    consumeToBlockOpen [] = ([], [])
    consumeToBlockOpen (l : ls)
        | opensBlockComment l = ([l], ls)
        | otherwise = let (blockBody, ls') = consumeToBlockOpen ls in (l : blockBody, ls')
    closesBlockComment l = "-}" `T.isSuffixOf` T.stripEnd l && not (opensBlockComment l)
    opensBlockComment l = "{-" `T.isPrefixOf` T.stripStart l


-- ── Lexical helpers ────────────────────────────────────────────────────────

-- | A line that is empty or only whitespace.
isBlank :: Text -> Bool
isBlank = T.null . T.strip


-- | A line whose first non-blank content opens a comment (@--@ or @{-@). Used
-- to gather the doc block above a declaration.
isCommentLine :: Text -> Bool
isCommentLine line =
    let s = T.stripStart line
    in  "--" `T.isPrefixOf` s || "{-" `T.isPrefixOf` s


-- | A CPP directive line (@#if@, @#else@, @#endif@, …). These sit at column 0
-- but are transparent to declaration boundaries, so a slice spans them.
isCppLine :: Text -> Bool
isCppLine = T.isPrefixOf "#" . T.stripStart


-- | A line whose first character is in column 0 (not indented, not empty).
isCol0 :: Text -> Bool
isCol0 line = case T.uncons line of
    Just (c, _) -> not (isSpace c)
    Nothing -> False


-- | The leading identifier token of a line, or @""@ when it does not start with
-- one. E.g. @"foo x = 1"@ → @"foo"@, @"foo :: Int"@ → @"foo"@, @"-- doc"@ → @""@.
leadingIdent :: Text -> Text
leadingIdent = T.takeWhile isIdentChar


-- | Characters that may appear in a Haskell identifier.
isIdentChar :: Char -> Bool
isIdentChar c = isAlphaNum c || c == '_' || c == '\''
