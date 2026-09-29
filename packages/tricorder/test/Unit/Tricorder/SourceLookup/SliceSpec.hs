module Unit.Tricorder.SourceLookup.SliceSpec (test_Slice) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Data.Text qualified as T

import Tricorder.SourceLookup.Slice (sliceSymbol)


test_Slice :: TestTree
test_Slice =
    testGroup
        "Slice"
        [ testGroup
            "sliceSymbol"
            [ valueBindings
            , typeDeclarations
            , constructors
            , compactDeclarations
            , robustness
            , capturePrecision
            ]
        ]


-- | Build a source fixture from individual lines.
src :: [Text] -> Text
src = T.unlines


valueBindings :: TestTree
valueBindings =
    testGroup
        "value bindings"
        [ testCase "slices a function with its signature and doc block" do
            let source =
                    src
                        [ "-- | The answer to everything."
                        , "answer :: Int"
                        , "answer = 42"
                        , ""
                        , "other :: Bool"
                        , "other = True"
                        ]
            sliceSymbol "answer" source
                @?= Just "-- | The answer to everything.\nanswer :: Int\nanswer = 42"
        , testCase "slices a binding with no signature" do
            let source = src ["foo = 1", "", "bar = 2"]
            sliceSymbol "foo" source @?= Just "foo = 1"
        , testCase "captures every equation of a multi-equation binding" do
            let source =
                    src
                        [ "isJust :: Maybe a -> Bool"
                        , "isJust (Just _) = True"
                        , "isJust Nothing = False"
                        , ""
                        , "next = ()"
                        ]
            sliceSymbol "isJust" source
                @?= Just "isJust :: Maybe a -> Bool\nisJust (Just _) = True\nisJust Nothing = False"
        , testCase "keeps a multi-line line-comment doc block" do
            let source =
                    src
                        [ "-- | The answer to everything,"
                        , "-- computed once."
                        , "answer :: Int"
                        , "answer = 42"
                        ]
            sliceSymbol "answer" source
                @?= Just "-- | The answer to everything,\n-- computed once.\nanswer :: Int\nanswer = 42"
        , testCase "slices an operator binding in (op) form" do
            let source =
                    src
                        [ "(<+>) :: Int -> Int -> Int"
                        , "a <+> b = a + b"
                        ]
            sliceSymbol "<+>" source
                @?= Just "(<+>) :: Int -> Int -> Int\na <+> b = a + b"
        , testCase "does not match a different binding with a shared prefix" do
            let source = src ["answer = 1", "", "answerable = 2"]
            sliceSymbol "answerable" source @?= Just "answerable = 2"
        ]


-- | Real Hackage source frequently packs top-level declarations together with
-- no blank line between them. The slice must stop at the neighbouring
-- declaration, not swallow it.
compactDeclarations :: TestTree
compactDeclarations =
    testGroup
        "adjacent declarations without blank lines"
        [ testCase "does not swallow the following binding" do
            sliceSymbol "bar" (src ["foo = 1", "bar = 2", "baz = 3"])
                @?= Just "bar = 2"
        , testCase "does not swallow the preceding binding and its signature" do
            let source =
                    src
                        [ "foo :: Int"
                        , "foo = 1"
                        , "bar :: Int"
                        , "bar = 2"
                        ]
            sliceSymbol "bar" source @?= Just "bar :: Int\nbar = 2"
        , testCase "keeps the doc block but not a preceding declaration" do
            let source =
                    src
                        [ "foo = 1"
                        , "-- | doc for bar"
                        , "bar = 2"
                        ]
            sliceSymbol "bar" source @?= Just "-- | doc for bar\nbar = 2"
        , testCase "keeps a multi-line doc block but not a preceding declaration" do
            let source =
                    src
                        [ "foo = 1"
                        , "-- | doc for bar,"
                        , "-- second line."
                        , "bar = 2"
                        ]
            sliceSymbol "bar" source
                @?= Just "-- | doc for bar,\n-- second line.\nbar = 2"
        ]


typeDeclarations :: TestTree
typeDeclarations =
    testGroup
        "type declarations"
        [ testCase "slices a data declaration with doc and deriving clause" do
            let source =
                    src
                        [ "-- | A JSON value."
                        , "data Value = Null | Bool Bool"
                        , "    deriving (Show)"
                        , ""
                        , "instance Eq Value"
                        ]
            sliceSymbol "Value" source
                @?= Just "-- | A JSON value.\ndata Value = Null | Bool Bool\n    deriving (Show)"
        , testCase "keeps a multi-line block doc comment on a data declaration" do
            let source =
                    src
                        [ "{- | A JSON value,"
                        , "   as parsed. -}"
                        , "data Value = Null | Bool Bool"
                        , ""
                        ]
            sliceSymbol "Value" source
                @?= Just "{- | A JSON value,\n   as parsed. -}\ndata Value = Null | Bool Bool"
        , testCase "slices a newtype" do
            sliceSymbol "Age" (src ["newtype Age = Age Int", ""])
                @?= Just "newtype Age = Age Int"
        , testCase "slices a type alias" do
            sliceSymbol "Name" (src ["type Name = Text"])
                @?= Just "type Name = Text"
        , testCase "slices a type family" do
            sliceSymbol "Elem" (src ["type family Elem c"])
                @?= Just "type family Elem c"
        , testCase "slices a class with its methods" do
            let source =
                    src
                        [ "class Eq a => Container a where"
                        , "    empty :: a"
                        , ""
                        , "foo = ()"
                        ]
            sliceSymbol "Container" source
                @?= Just "class Eq a => Container a where\n    empty :: a"
        , testCase "slices a record declaration including all fields" do
            let source =
                    src
                        [ "data Person = Person"
                        , "    { name :: Text"
                        , "    , age :: Int"
                        , "    }"
                        , "    deriving (Show)"
                        , ""
                        ]
            sliceSymbol "Person" source
                @?= Just
                    ( "data Person = Person\n"
                        <> "    { name :: Text\n"
                        <> "    , age :: Int\n"
                        <> "    }\n"
                        <> "    deriving (Show)"
                    )
        , testCase "slices a GADT declaration" do
            let source =
                    src
                        [ "data Expr a where"
                        , "    Lit :: Int -> Expr Int"
                        , "    Add :: Expr Int -> Expr Int -> Expr Int"
                        , ""
                        ]
            sliceSymbol "Expr" source
                @?= Just
                    ( "data Expr a where\n"
                        <> "    Lit :: Int -> Expr Int\n"
                        <> "    Add :: Expr Int -> Expr Int -> Expr Int"
                    )
        ]


constructors :: TestTree
constructors =
    testGroup
        "constructor queries"
        [ testCase "returns the enclosing data block for a constructor" do
            let source =
                    src
                        [ "-- | Optionality."
                        , "data Maybe a = Nothing | Just a"
                        , ""
                        , "foo = ()"
                        ]
            sliceSymbol "Just" source
                @?= Just "-- | Optionality.\ndata Maybe a = Nothing | Just a"
        , testCase "keeps a multi-line doc block above the enclosing data block" do
            let source =
                    src
                        [ "-- | Optionality,"
                        , "-- the Maybe type."
                        , "data Maybe a = Nothing | Just a"
                        , ""
                        ]
            sliceSymbol "Just" source
                @?= Just "-- | Optionality,\n-- the Maybe type.\ndata Maybe a = Nothing | Just a"
        , testCase "returns the enclosing GADT block for a GADT constructor" do
            let source =
                    src
                        [ "data Expr a where"
                        , "    Lit :: Int -> Expr Int"
                        , "    Add :: Expr Int -> Expr Int -> Expr Int"
                        , ""
                        ]
            sliceSymbol "Lit" source
                @?= Just
                    ( "data Expr a where\n"
                        <> "    Lit :: Int -> Expr Int\n"
                        <> "    Add :: Expr Int -> Expr Int -> Expr Int"
                    )
        ]


robustness :: TestTree
robustness =
    testGroup
        "robustness"
        [ testCase "returns Nothing for a missing symbol" do
            sliceSymbol "nope" (src ["foo = 1", "bar = 2"]) @?= Nothing
        , testCase "returns Nothing for an empty query" do
            sliceSymbol "" (src ["foo = 1"]) @?= Nothing
        , testCase "does not choke on CPP-laden source" do
            let source =
                    src
                        [ "#if MIN_VERSION_base(4,18,0)"
                        , "answer :: Int"
                        , "#else"
                        , "answer :: Integer"
                        , "#endif"
                        , "answer = 42"
                        ]
            let result = sliceSymbol "answer" source
            assertBool "expected Just" $ isJust (result)
            fmap (T.isInfixOf "answer = 42") result @?= Just True
        ]


-- | The slice must span exactly the queried declaration: not truncating it
-- early, not swallowing a neighbour, and not anchoring on the wrong entity.
-- These are the over-/under-capture shapes real Hackage source triggers.
capturePrecision :: TestTree
capturePrecision =
    testGroup
        "capture precision"
        [ testCase "keeps a where-clause that contains a blank line" do
            let source =
                    src
                        [ "foo x = go x"
                        , "  where"
                        , "    go y = y + 1"
                        , ""
                        , "    helper = 2"
                        , ""
                        , "bar = 3"
                        ]
            sliceSymbol "foo" source
                @?= Just "foo x = go x\n  where\n    go y = y + 1\n\n    helper = 2"
        , testCase "does not swallow a following binding that merely uses the operator" do
            let source =
                    src
                        [ "(<+>) :: Int -> Int -> Int"
                        , "a <+> b = a + b"
                        , "merge x y = x <+> y"
                        ]
            sliceSymbol "<+>" source
                @?= Just "(<+>) :: Int -> Int -> Int\na <+> b = a + b"
        , testCase "does not anchor on a superclass name in a class head" do
            let source =
                    src
                        [ "class Eq a => Ord a where"
                        , "    compare :: a -> a -> Ordering"
                        ]
            sliceSymbol "Eq" source @?= Nothing
        , testCase "slices a class that has a superclass context by its own name" do
            let source =
                    src
                        [ "class Eq a => Ord a where"
                        , "    compare :: a -> a -> Ordering"
                        ]
            sliceSymbol "Ord" source
                @?= Just "class Eq a => Ord a where\n    compare :: a -> a -> Ordering"
        , testCase "picks the data block that actually defines the constructor" do
            let source =
                    src
                        [ "-- | Uses Just internally."
                        , "data Wrapper = Wrap Int"
                        , ""
                        , "data Maybe a = Nothing | Just a"
                        ]
            sliceSymbol "Just" source
                @?= Just "data Maybe a = Nothing | Just a"
        , testCase "does not anchor on a constructor name used as a field type elsewhere" do
            let source =
                    src
                        [ "data Holder = Holder Bar"
                        , ""
                        , "data Thing = Bar | Baz"
                        ]
            sliceSymbol "Bar" source @?= Just "data Thing = Bar | Baz"
        , testCase "keeps a multi-line {- | -} block doc comment" do
            let source =
                    src
                        [ "{- | This does X"
                        , "   over multiple lines. -}"
                        , "foo :: Int"
                        , "foo = 1"
                        ]
            sliceSymbol "foo" source
                @?= Just "{- | This does X\n   over multiple lines. -}\nfoo :: Int\nfoo = 1"
        ]
