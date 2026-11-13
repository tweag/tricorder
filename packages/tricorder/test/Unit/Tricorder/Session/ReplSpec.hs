module Unit.Tricorder.Session.ReplSpec (test_Repl) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.FileSystem.Path qualified as Path
import Data.Map.Strict qualified as Map

import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.Repl (Repl (..), resolveRepl)
import Unit.Tricorder.Session.Helpers (withProjectFiles)


test_Repl :: TestTree
test_Repl =
    testGroup
        "Repl"
        [ testGroup "resolveRepl" testResolveRepl
        ]


testResolveRepl :: [TestTree]
testResolveRepl =
    [ testCase "resolves Stack for a single-package stack.yaml" do
        resolve [(Path.rel @"stack.yaml", "")] >>= (@?= Stack)
    , testCase "resolves StackMulti for a multi-package stack.yaml" do
        resolve [(Path.rel @"stack.yaml", "packages:\n  - foo\n  - bar\n")] >>= (@?= StackMulti)
    , testCase "resolves Cabal when there is a cabal.project file" do
        resolve [(Path.rel @"cabal.project", "")] >>= (@?= Cabal)
    , testCase "resolves Cabal when there is at least one *.cabal file" do
        resolve [(Path.rel @"foo.cabal", "")] >>= (@?= Cabal)
    , testCase "prefers Stack over Cabal when both are present" do
        resolve [(Path.rel @"stack.yaml", ""), (Path.rel @"cabal.project", "")] >>= (@?= Stack)
    , testCase "falls back to Cabal when there are no project files at all" do
        resolve [] >>= (@?= Cabal)
    ]


-- | Resolve the 'Repl' of a temporary project root seeded with the given
-- files (content is irrelevant except for @stack.yaml@, which is parsed for
-- its @packages@ key).
resolve :: [(Path.Relative, ByteString)] -> IO Repl
resolve files = withProjectFiles (Map.fromList files) (resolveRepl . ProjectRoot)
