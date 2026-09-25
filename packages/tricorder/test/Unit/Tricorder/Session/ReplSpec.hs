module Unit.Tricorder.Session.ReplSpec (spec_Repl) where

import Atelier.Effects.FileSystem (FileSystem, runFileSystemState)
import Effectful (runPureEff)
import Effectful.State.Static.Shared (State, evalState)
import Test.Hspec (Spec, describe, it, shouldBe)

import Data.Map.Strict qualified as Map

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Repl (Repl (..), resolveRepl)


spec_Repl :: Spec
spec_Repl = do
    describe "resolveRepl" testResolveRepl


testResolveRepl :: Spec
testResolveRepl = do
    it "resolves Stack for a single-package stack.yaml" do
        withFiles [("/stack.yaml", "")] (resolveRepl pr) `shouldBe` Stack

    it "resolves StackMulti for a multi-package stack.yaml" do
        withFiles
            [("/stack.yaml", "packages:\n  - foo\n  - bar\n")]
            (resolveRepl pr)
            `shouldBe` StackMulti

    it "resolves Cabal when there is a cabal.project file" do
        withFiles [("/cabal.project", "")] (resolveRepl pr) `shouldBe` Cabal

    it "resolves Cabal when there is at least one *.cabal file" do
        withFiles [("/foo.cabal", "")] (resolveRepl pr) `shouldBe` Cabal

    it "prefers Stack over Cabal when both are present" do
        withFiles [("/stack.yaml", ""), ("/cabal.project", "")] (resolveRepl pr) `shouldBe` Stack

    it "falls back to Cabal when there are no project files at all" do
        withFiles [] (resolveRepl pr) `shouldBe` Cabal


-- | Run a 'FileSystem'-using computation against a faked in-memory
-- filesystem seeded with the given files (content is irrelevant except for
-- @stack.yaml@, which is parsed for its @packages@ key).
withFiles :: [(FilePath, ByteString)] -> Eff '[FileSystem, State (Map FilePath ByteString)] a -> a
withFiles files action =
    runPureEff $ evalState (Map.fromList files) $ runFileSystemState action


pr :: ProjectRoot
pr = ProjectRoot "/"
