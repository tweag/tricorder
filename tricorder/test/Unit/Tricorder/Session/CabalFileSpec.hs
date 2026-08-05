module Unit.Tricorder.Session.CabalFileSpec (spec_CabalFile) where

import Atelier.Effects.FileSystem (runFileSystemState)
import Atelier.Effects.Log (runLogNoOp)
import Effectful (runPureEff)
import Effectful.State.Static.Shared (evalState)
import Test.Hspec (Spec, describe, it, shouldBe)

import Data.Map.Strict qualified as Map

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.CabalFile (discoverCabalFiles)
import Unit.Tricorder.Session.Helpers (cabalFixture, multiPackageFs)


spec_CabalFile :: Spec
spec_CabalFile = do
    describe "discoverCabalFiles" testDiscoverCabalFiles


-- | Pins the discovery contract: a @cabal.project@ selects per-package
-- @.cabal@ files from its @packages:@ stanza; otherwise the @.cabal@ files in
-- the project root are used.
testDiscoverCabalFiles :: Spec
testDiscoverCabalFiles = do
    describe "when there is no cabal.project" do
        it "finds the .cabal files in the project root" do
            let actual =
                    runDiscovery (Map.singleton "/myapp.cabal" cabalFixture)
                        $ discoverCabalFiles pr
            actual `shouldBe` ["/myapp.cabal"]

        it "returns no files when the root has no cabal file" do
            let actual = runDiscovery mempty $ discoverCabalFiles pr
            actual `shouldBe` []

    describe "when there is a multi-package cabal.project" do
        it "resolves each listed package to its .cabal (regression: was root-only)" do
            let actual = runDiscovery multiPackageFs $ discoverCabalFiles pr
            actual `shouldBe` ["/pkg-a/pkg-a.cabal", "/pkg-b/pkg-b.cabal"]
  where
    pr = ProjectRoot "/"
    runDiscovery fs = runPureEff . evalState fs . runFileSystemState . runLogNoOp
