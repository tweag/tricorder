module Unit.Tricorder.SourceLookup.SliceSpec (spec_Slice) where

import Test.Hspec

import Data.Text qualified as T

import Tricorder.SourceLookup.Slice (sliceSymbol)


spec_Slice :: Spec
spec_Slice = describe "sliceSymbol" do
    valueBindings
    typeDeclarations
    constructors
    compactDeclarations
    robustness
    capturePrecision


-- | Build a source fixture from individual lines.
src :: [Text] -> Text
src = T.unlines


valueBindings :: Spec
valueBindings = describe "value bindings" do
    it "slices a function with its signature and doc block" do
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
            `shouldBe` Just "-- | The answer to everything.\nanswer :: Int\nanswer = 42"

    it "slices a binding with no signature" do
        let source = src ["foo = 1", "", "bar = 2"]
        sliceSymbol "foo" source `shouldBe` Just "foo = 1"

    it "captures every equation of a multi-equation binding" do
        let source =
                src
                    [ "isJust :: Maybe a -> Bool"
                    , "isJust (Just _) = True"
                    , "isJust Nothing = False"
                    , ""
                    , "next = ()"
                    ]
        sliceSymbol "isJust" source
            `shouldBe` Just "isJust :: Maybe a -> Bool\nisJust (Just _) = True\nisJust Nothing = False"

    it "slices an operator binding in (op) form" do
        let source =
                src
                    [ "(<+>) :: Int -> Int -> Int"
                    , "a <+> b = a + b"
                    ]
        sliceSymbol "<+>" source
            `shouldBe` Just "(<+>) :: Int -> Int -> Int\na <+> b = a + b"

    it "does not match a different binding with a shared prefix" do
        let source = src ["answer = 1", "", "answerable = 2"]
        sliceSymbol "answerable" source `shouldBe` Just "answerable = 2"


-- | Real Hackage source frequently packs top-level declarations together with
-- no blank line between them. The slice must stop at the neighbouring
-- declaration, not swallow it.
compactDeclarations :: Spec
compactDeclarations = describe "adjacent declarations without blank lines" do
    it "does not swallow the following binding" do
        sliceSymbol "bar" (src ["foo = 1", "bar = 2", "baz = 3"])
            `shouldBe` Just "bar = 2"

    it "does not swallow the preceding binding and its signature" do
        let source =
                src
                    [ "foo :: Int"
                    , "foo = 1"
                    , "bar :: Int"
                    , "bar = 2"
                    ]
        sliceSymbol "bar" source `shouldBe` Just "bar :: Int\nbar = 2"

    it "keeps the doc block but not a preceding declaration" do
        let source =
                src
                    [ "foo = 1"
                    , "-- | doc for bar"
                    , "bar = 2"
                    ]
        sliceSymbol "bar" source `shouldBe` Just "-- | doc for bar\nbar = 2"


typeDeclarations :: Spec
typeDeclarations = describe "type declarations" do
    it "slices a data declaration with doc and deriving clause" do
        let source =
                src
                    [ "-- | A JSON value."
                    , "data Value = Null | Bool Bool"
                    , "    deriving (Show)"
                    , ""
                    , "instance Eq Value"
                    ]
        sliceSymbol "Value" source
            `shouldBe` Just "-- | A JSON value.\ndata Value = Null | Bool Bool\n    deriving (Show)"

    it "slices a newtype" do
        sliceSymbol "Age" (src ["newtype Age = Age Int", ""])
            `shouldBe` Just "newtype Age = Age Int"

    it "slices a type alias" do
        sliceSymbol "Name" (src ["type Name = Text"])
            `shouldBe` Just "type Name = Text"

    it "slices a type family" do
        sliceSymbol "Elem" (src ["type family Elem c"])
            `shouldBe` Just "type family Elem c"

    it "slices a class with its methods" do
        let source =
                src
                    [ "class Eq a => Container a where"
                    , "    empty :: a"
                    , ""
                    , "foo = ()"
                    ]
        sliceSymbol "Container" source
            `shouldBe` Just "class Eq a => Container a where\n    empty :: a"

    it "slices a record declaration including all fields" do
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
            `shouldBe` Just
                ( "data Person = Person\n"
                    <> "    { name :: Text\n"
                    <> "    , age :: Int\n"
                    <> "    }\n"
                    <> "    deriving (Show)"
                )

    it "slices a GADT declaration" do
        let source =
                src
                    [ "data Expr a where"
                    , "    Lit :: Int -> Expr Int"
                    , "    Add :: Expr Int -> Expr Int -> Expr Int"
                    , ""
                    ]
        sliceSymbol "Expr" source
            `shouldBe` Just
                ( "data Expr a where\n"
                    <> "    Lit :: Int -> Expr Int\n"
                    <> "    Add :: Expr Int -> Expr Int -> Expr Int"
                )


constructors :: Spec
constructors = describe "constructor queries" do
    it "returns the enclosing data block for a constructor" do
        let source =
                src
                    [ "-- | Optionality."
                    , "data Maybe a = Nothing | Just a"
                    , ""
                    , "foo = ()"
                    ]
        sliceSymbol "Just" source
            `shouldBe` Just "-- | Optionality.\ndata Maybe a = Nothing | Just a"

    it "returns the enclosing GADT block for a GADT constructor" do
        let source =
                src
                    [ "data Expr a where"
                    , "    Lit :: Int -> Expr Int"
                    , "    Add :: Expr Int -> Expr Int -> Expr Int"
                    , ""
                    ]
        sliceSymbol "Lit" source
            `shouldBe` Just
                ( "data Expr a where\n"
                    <> "    Lit :: Int -> Expr Int\n"
                    <> "    Add :: Expr Int -> Expr Int -> Expr Int"
                )


robustness :: Spec
robustness = describe "robustness" do
    it "returns Nothing for a missing symbol" do
        sliceSymbol "nope" (src ["foo = 1", "bar = 2"]) `shouldBe` Nothing

    it "returns Nothing for an empty query" do
        sliceSymbol "" (src ["foo = 1"]) `shouldBe` Nothing

    it "does not choke on CPP-laden source" do
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
        result `shouldSatisfy` isJust
        fmap (T.isInfixOf "answer = 42") result `shouldBe` Just True


-- | The slice must span exactly the queried declaration: not truncating it
-- early, not swallowing a neighbour, and not anchoring on the wrong entity.
-- These are the over-/under-capture shapes real Hackage source triggers.
capturePrecision :: Spec
capturePrecision = describe "capture precision" do
    it "keeps a where-clause that contains a blank line" do
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
            `shouldBe` Just "foo x = go x\n  where\n    go y = y + 1\n\n    helper = 2"

    it "does not swallow a following binding that merely uses the operator" do
        let source =
                src
                    [ "(<+>) :: Int -> Int -> Int"
                    , "a <+> b = a + b"
                    , "merge x y = x <+> y"
                    ]
        sliceSymbol "<+>" source
            `shouldBe` Just "(<+>) :: Int -> Int -> Int\na <+> b = a + b"

    it "does not anchor on a superclass name in a class head" do
        let source =
                src
                    [ "class Eq a => Ord a where"
                    , "    compare :: a -> a -> Ordering"
                    ]
        sliceSymbol "Eq" source `shouldBe` Nothing

    it "slices a class that has a superclass context by its own name" do
        let source =
                src
                    [ "class Eq a => Ord a where"
                    , "    compare :: a -> a -> Ordering"
                    ]
        sliceSymbol "Ord" source
            `shouldBe` Just "class Eq a => Ord a where\n    compare :: a -> a -> Ordering"

    it "picks the data block that actually defines the constructor" do
        let source =
                src
                    [ "-- | Uses Just internally."
                    , "data Wrapper = Wrap Int"
                    , ""
                    , "data Maybe a = Nothing | Just a"
                    ]
        sliceSymbol "Just" source
            `shouldBe` Just "data Maybe a = Nothing | Just a"

    it "does not anchor on a constructor name used as a field type elsewhere" do
        let source =
                src
                    [ "data Holder = Holder Bar"
                    , ""
                    , "data Thing = Bar | Baz"
                    ]
        sliceSymbol "Bar" source `shouldBe` Just "data Thing = Bar | Baz"

    it "keeps a multi-line {- | -} block doc comment" do
        let source =
                src
                    [ "{- | This does X"
                    , "   over multiple lines. -}"
                    , "foo :: Int"
                    , "foo = 1"
                    ]
        sliceSymbol "foo" source
            `shouldBe` Just "{- | This does X\n   over multiple lines. -}\nfoo :: Int\nfoo = 1"
