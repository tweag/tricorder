module Unit.Tricorder.Session.WatchDirsSpec (spec_WatchDirs) where

import Data.Default (def)
import Test.Hspec (Spec, context, describe, it, shouldBe)

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Target (ComponentKind (..), Target (..), parseTarget)
import Tricorder.Session.WatchDirs (WatchDirs (..), resolveWatchDirs, sourceDirsForTarget)
import Unit.Tricorder.Session.Helpers (gpd, multiCabalFiles, singleCabalFile)


spec_WatchDirs :: Spec
spec_WatchDirs = do
    describe "resolveWatchDirs" testResolveWatchDirs
    describe "sourceDirsForTarget" testSourceDirsForTarget


testResolveWatchDirs :: Spec
testResolveWatchDirs = do
    describe "when watch_dirs is set in config" do
        it "uses config dirs relative to project root" do
            let WatchDirs actual =
                    resolveWatchDirs pr [] def {watchDirs = ["src", "test"]} []
            actual `shouldBe` ["/src", "/test"]

    describe "when watch_dirs is not set" do
        it "falls back to [\".\"] when targets list is empty" do
            let WatchDirs actual = resolveWatchDirs pr [] def []
            actual `shouldBe` ["."]

        it "infers source dirs from resolved targets" do
            let WatchDirs actual =
                    resolveWatchDirs pr singleCabalFile def (mkTargets ["lib:myapp", "test:myapp-test"])
            actual `shouldBe` ["/src", "/test"]

        it "falls back to [\".\"] when there are no cabal files" do
            let WatchDirs actual =
                    resolveWatchDirs pr [] def (mkTargets ["lib:myapp"])
            actual `shouldBe` ["."]

        -- Sharp edge: an unparseable .cabal yields no source dirs, so resolution
        -- falls back to watching the whole project root. This pins the current
        -- behavior; if it ever changes to something narrower, update this test.
        it "falls back to [\".\"] when no cabal files are found or parsed" do
            let WatchDirs actual =
                    resolveWatchDirs pr [] def (mkTargets ["lib:myapp"])
            actual `shouldBe` ["."]

    describe "when the project is a multi-package cabal.project" do
        it "infers per-package source dirs, scoped to each package's directory" do
            let WatchDirs actual =
                    resolveWatchDirs
                        pr
                        multiCabalFiles
                        def
                        (mkTargets ["lib:pkg-a", "test:pkg-a-test", "lib:pkg-b", "test:pkg-b-test"])
            actual
                `shouldBe` ["/pkg-a/src", "/pkg-a/test", "/pkg-b/src", "/pkg-b/test"]

        it "scopes a bare package-name target to that package, ignoring siblings" do
            let WatchDirs actual =
                    resolveWatchDirs pr multiCabalFiles def (mkTargets ["pkg-a"])
            actual `shouldBe` ["/pkg-a/src", "/pkg-a/test"]
  where
    pr = ProjectRoot "/"


-- | These exercise the 'Target' -> dirs resolution directly with constructed
-- 'Target' values; the string -> 'Target' parsing is covered by 'testParseTarget'.
testSourceDirsForTarget :: Spec
testSourceDirsForTarget = do
    describe "Qualified Lib" do
        context "when the name is empty" do
            it "returns the main library source dirs" do
                sourceDirsForTarget gpd (Qualified Lib "") `shouldBe` ["src"]

        context "when the name matches the package name" do
            it "returns the main library source dirs" do
                sourceDirsForTarget gpd (Qualified Lib "myapp") `shouldBe` ["src"]

        context "when the name matches a sub-library" do
            it "returns the sub-library source dirs" do
                sourceDirsForTarget gpd (Qualified Lib "myapp-utils") `shouldBe` ["utils"]

        context "when the sub-library is unknown" do
            it "returns an empty list" do
                sourceDirsForTarget gpd (Qualified Lib "nonexistent") `shouldBe` []

    describe "Qualified FLib" do
        it "returns the foreign-library source dirs" do
            sourceDirsForTarget gpd (Qualified FLib "myapp-flib") `shouldBe` ["flib"]

    describe "Qualified Exe" do
        it "returns the executable source dirs" do
            sourceDirsForTarget gpd (Qualified Exe "myapp-exe") `shouldBe` ["app"]

    describe "Qualified Test" do
        it "returns the test suite source dirs" do
            sourceDirsForTarget gpd (Qualified Test "myapp-test") `shouldBe` ["test"]

    describe "Qualified Bench" do
        it "returns the benchmark source dirs" do
            sourceDirsForTarget gpd (Qualified Bench "myapp-bench") `shouldBe` ["bench"]

    describe "Bare (package name)" do
        it "returns every component's source dirs" do
            sourceDirsForTarget gpd (Bare "myapp") `shouldBe` ["src", "utils", "flib", "app", "test", "bench"]

    describe "Bare (component name)" do
        context "when it names a sub-library" do
            it "returns the sub-library source dirs" do
                sourceDirsForTarget gpd (Bare "myapp-utils") `shouldBe` ["utils"]

        context "when it names an executable" do
            it "returns the executable source dirs" do
                sourceDirsForTarget gpd (Bare "myapp-exe") `shouldBe` ["app"]

        context "when it names a test suite" do
            it "returns the test suite source dirs" do
                sourceDirsForTarget gpd (Bare "myapp-test") `shouldBe` ["test"]

        context "when it matches no component" do
            it "returns an empty list" do
                sourceDirsForTarget gpd (Bare "unknown") `shouldBe` []

    describe "Unrecognized" do
        it "matches an aliased kind prefix by trailing name" do
            sourceDirsForTarget gpd (Unrecognized "executable:myapp-exe") `shouldBe` ["app"]

        it "matches a case-variant kind prefix by trailing name" do
            sourceDirsForTarget gpd (Unrecognized "Test-Suite:myapp-test") `shouldBe` ["test"]

        it "matches the main library when the trailing name is the package name" do
            sourceDirsForTarget gpd (Unrecognized "library:myapp") `shouldBe` ["src"]

        it "returns an empty list when the trailing name matches no component" do
            sourceDirsForTarget gpd (Unrecognized "bogus:x") `shouldBe` []


mkTargets :: [Text] -> [Target]
mkTargets = fmap parseTarget
