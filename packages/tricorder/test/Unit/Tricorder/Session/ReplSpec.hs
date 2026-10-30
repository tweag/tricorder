module Unit.Tricorder.Session.ReplSpec (test_Repl) where

import Atelier.Effects.FileSystem (FileSystem)
import Effectful (runPureEff)
import Effectful.State.Static.Shared (State, evalState)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.Effects.FileSystem qualified as FileSystem
import Data.Map.Strict qualified as Map

import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.Repl (Repl (..), resolveRepl)


test_Repl :: TestTree
test_Repl =
    testGroup
        "Repl"
        [ testGroup "resolveRepl" testResolveRepl
        ]


testResolveRepl :: [TestTree]
testResolveRepl =
    [ testCase "resolves Stack for a single-package stack.yaml" do
        withFiles [("/stack.yaml", "")] (resolveRepl pr) @?= Stack
    , testCase "resolves StackMulti for a multi-package stack.yaml" do
        withFiles
            [("/stack.yaml", "packages:\n  - foo\n  - bar\n")]
            (resolveRepl pr)
            @?= StackMulti
    , testCase "resolves Cabal when there is a cabal.project file" do
        withFiles [("/cabal.project", "")] (resolveRepl pr) @?= Cabal
    , testCase "resolves Cabal when there is at least one *.cabal file" do
        withFiles [("/foo.cabal", "")] (resolveRepl pr) @?= Cabal
    , testCase "prefers Stack over Cabal when both are present" do
        withFiles [("/stack.yaml", ""), ("/cabal.project", "")] (resolveRepl pr) @?= Stack
    , testCase "falls back to Cabal when there are no project files at all" do
        withFiles [] (resolveRepl pr) @?= Cabal
    ]


-- | Run a 'FileSystem'-using computation against a faked in-memory
-- filesystem seeded with the given files (content is irrelevant except for
-- @stack.yaml@, which is parsed for its @packages@ key).
withFiles :: [(FilePath, ByteString)] -> Eff '[FileSystem, State (Map FilePath ByteString)] a -> a
withFiles files action =
    runPureEff $ evalState (Map.fromList files) $ FileSystem.runState action


pr :: ProjectRoot
pr = ProjectRoot "/"
