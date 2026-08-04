module Unit.Tricorder.SourceLookup.GhcPkgSpec (spec_GhcPkg) where

import Effectful (runPureEff)
import Test.Hspec

import Tricorder.SourceLookup.GhcPkg (GhcPkg, GhcPkgScript (..), findModule, runGhcPkgScripted)


spec_GhcPkg :: Spec
spec_GhcPkg = do
    describe "findModule" testFindModule


testFindModule :: Spec
testFindModule = do
    it "returns Just pkgId when module is known" do
        let result = runScripted [NextFindModule (Just "base-4.18")] $ findModule "Prelude"
        result `shouldBe` Just "base-4.18"

    it "returns Nothing for an unknown module" do
        let result = runScripted [NextFindModule Nothing] $ findModule "No.Such.Module"
        result `shouldBe` Nothing

    it "returns the first scripted result" do
        let result = runScripted [NextFindModule (Just "pkg-1.0"), NextFindModule (Just "pkg-2.0")] $ findModule "Foo"
        result `shouldBe` Just "pkg-1.0"


runScripted :: [GhcPkgScript] -> Eff '[GhcPkg] a -> a
runScripted script = runPureEff . runGhcPkgScripted script
