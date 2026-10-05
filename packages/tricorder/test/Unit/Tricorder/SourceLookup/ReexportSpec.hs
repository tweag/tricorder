module Unit.Tricorder.SourceLookup.ReexportSpec (test_Reexport, test_exportsByName, test_declaresMember) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Data.Text qualified as T

import Tricorder.SourceLookup.Reexport (declaresMember, exportsByName, reexportCandidates)


test_Reexport :: TestTree
test_Reexport =
    testGroup
        "Reexport"
        [ testGroup
            "reexportCandidates"
            [ testCase "follows an import list naming the symbol" do
                let source =
                        src
                            [ "module Data.Text"
                            , "    ( Text"
                            , "    , pack -- re-exported"
                            , "    ) where"
                            , ""
                            , "import Data.Text.Array qualified as A"
                            , "import Data.Text.Show (singleton,"
                            , "    unpack)"
                            , "import Data.Text.Internal (Text(..), empty, pack)"
                            ]
                reexportCandidates "pack" source @?= ["Data.Text.Internal"]
            , testCase "ranks imports naming the symbol before unrestricted ones" do
                let source =
                        src
                            [ "module M (foo) where"
                            , "import A"
                            , "import B (foo)"
                            , "import C hiding (foo)"
                            ]
                reexportCandidates "foo" source @?= ["B", "A"]
            , testCase "yields nothing without an export list" do
                let source = src ["module M where", "import A (foo)"]
                reexportCandidates "foo" source @?= []
            , testCase "yields nothing when the export list does not mention the symbol" do
                let source = src ["module M (bar) where", "import A"]
                reexportCandidates "foo" source @?= []
            , testCase "follows a module re-export" do
                let source =
                        src
                            [ "module M (module X, bar) where"
                            , "import qualified Q"
                            , "import Data.Foo as X"
                            , "import Data.Bar"
                            ]
                reexportCandidates "foo" source @?= ["Data.Foo"]
            , testCase "matches a qualified export to its import alias" do
                let source =
                        src
                            [ "module M (T.foo) where"
                            , "import A"
                            , "import qualified B as T"
                            ]
                reexportCandidates "foo" source @?= ["B"]
            , testCase "follows a constructor through a wildcard export" do
                let source =
                        src
                            [ "module M (Shape(..)) where"
                            , "import Shapes (Shape(..))"
                            , "import Other (thing)"
                            ]
                reexportCandidates "Circle" source @?= ["Shapes"]
            , testCase "skips an import that hides the symbol but brings in its parent" do
                let source =
                        src
                            [ "module Prelude (Foldable(foldr)) where"
                            , "import GHC.Base hiding (foldr)"
                            , "import Data.Foldable (Foldable(..))"
                            ]
                reexportCandidates "foldr" source @?= ["Data.Foldable"]
            , testCase "yields nothing for a member of a locally declared parent" do
                let source =
                        src
                            [ "module Data.Foldable (Foldable(..)) where"
                            , "import GHC.Base"
                            , ""
                            , "class Foldable t where"
                            , "    foldr :: (a -> b -> b) -> b -> t a -> b"
                            ]
                reexportCandidates "foldr" source @?= []
            , testCase "matches operators" do
                let source = src ["module M ((<+>)) where", "import Ops ((<+>))"]
                reexportCandidates "<+>" source @?= ["Ops"]
            , testCase "ignores commented-out exports and imports" do
                let source =
                        src
                            [ "{-# LANGUAGE CPP #-}"
                            , "-- | module Fake (foo) where"
                            , "module M ( {- foo, -} bar ) where"
                            , "-- import A (foo)"
                            , "import B (bar)"
                            ]
                reexportCandidates "foo" source @?= []
            ]
        ]


src :: [Text] -> Text
src = T.unlines


test_declaresMember :: TestTree
test_declaresMember =
    testGroup
        "declaresMember"
        [ testCase "holds for a method of a locally declared class" do
            let source =
                    src
                        [ "module Data.Foldable (Foldable(..)) where"
                        , ""
                        , "class Foldable t where"
                        , "    foldr :: (a -> b -> b) -> b -> t a -> b"
                        ]
            declaresMember "foldr" source @?= True
        , testCase "does not hold for a symbol absent from the local parent" do
            let source =
                    src
                        [ "module M (Shape(..), foldr) where"
                        , "import Data.Foldable (foldr)"
                        , ""
                        , "data Shape = Circle | Square"
                        ]
            declaresMember "foldr" source @?= False
        , testCase "does not hold for a symbol merely used in the parent's body" do
            let source =
                    src
                        [ "module M (Functor(..), map) where"
                        , "import GHC.Base (map)"
                        , ""
                        , "class Functor f where"
                        , "    fmap :: (a -> b) -> f a -> f b"
                        , "    fmap = map"
                        ]
            declaresMember "map" source @?= False
        , testCase "holds for a constructor of a local data type" do
            let source =
                    src
                        [ "module M (Shape(..)) where"
                        , ""
                        , "data Shape = Circle Double | Square Double"
                        ]
            declaresMember "Square" source @?= True
        , testCase "does not hold when the parent is imported" do
            let source =
                    src
                        [ "module Prelude (Foldable(foldr)) where"
                        , "import Data.Foldable (Foldable(..))"
                        ]
            declaresMember "foldr" source @?= False
        ]


test_exportsByName :: TestTree
test_exportsByName =
    testGroup
        "exportsByName"
        [ testCase "holds for a symbol named directly" do
            exportsByName "pack" (src ["module Data.Text (Text, pack) where"]) @?= True
        , testCase "holds for a qualified export" do
            exportsByName "pack" (src ["module M (T.pack) where", "import qualified Data.Text as T"]) @?= True
        , testCase "holds for a symbol named in a sub-list" do
            exportsByName "Just" (src ["module M (Maybe(Nothing, Just)) where"]) @?= True
        , testCase "holds for a type whose sub-list is a wildcard" do
            exportsByName "Maybe" (src ["module M (Maybe(..)) where"]) @?= True
        , testCase "does not hold for a member covered only by a wildcard" do
            exportsByName "Just" (src ["module M (Maybe(..)) where"]) @?= False
        , testCase "does not hold for a module re-export" do
            exportsByName "Maybe" (src ["module M (module GHC.Maybe) where", "import GHC.Maybe"]) @?= False
        , testCase "does not hold without an export list" do
            exportsByName "pack" (src ["module M where", "", "pack = undefined"]) @?= False
        , testCase "ignores a commented-out export" do
            exportsByName "pack" (src ["module M ( {- pack, -} unpack ) where"]) @?= False
        ]
