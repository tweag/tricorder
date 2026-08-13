module Unit.Tricorder.Session.CabalFileSpec (spec_CabalFile) where

import Atelier.Effects.Env (runEnvConst)
import Atelier.Effects.FileSystem (runFileSystemState)
import Effectful (runPureEff)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState)
import Test.Hspec (Spec, describe, it, shouldBe)

import Data.Map.Strict qualified as Map

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.CabalFile (discoverCabalFiles)
import Unit.Tricorder.Session.Helpers (cabalFixture, libTestCabal, multiPackageFs)


spec_CabalFile :: Spec
spec_CabalFile = do
    describe "discoverCabalFiles" testDiscoverCabalFiles


-- | Pins the discovery contract: a @cabal.project@ (or @.local@/@.freeze@
-- variant) selects per-package @.cabal@ files from its @packages:@ stanza;
-- otherwise the @.cabal@ files in the project root are used. Falls back
-- further to @$HOME/.cabal/config@'s @packages:@ stanza if none of the
-- project-root files exist.
testDiscoverCabalFiles :: Spec
testDiscoverCabalFiles = do
    describe "when there is no cabal.project" do
        it "finds the .cabal files in the project root" do
            let actual =
                    runDiscovery (Map.singleton "/myapp.cabal" cabalFixture) []
                        $ discoverCabalFiles
            actual `shouldBe` ["/myapp.cabal"]

        it "returns no files when the root has no cabal file" do
            let actual = runDiscovery mempty [] discoverCabalFiles
            actual `shouldBe` []

    describe "when there is a multi-package cabal.project" do
        it "resolves each listed package to its .cabal (regression: was root-only)" do
            let actual = runDiscovery multiPackageFs [] discoverCabalFiles
            actual `shouldBe` ["/pkg-a/pkg-a.cabal", "/pkg-b/pkg-b.cabal"]

    describe "priority among cabal.project.local, cabal.project.freeze, and cabal.project" do
        it "prefers cabal.project.local over cabal.project" do
            let fs =
                    Map.fromList
                        [ ("/cabal.project.local", "packages: pkg-a\n")
                        , ("/cabal.project", "packages: pkg-b\n")
                        ]
                        `Map.union` multiPackageCabalFiles
                actual = runDiscovery fs [] discoverCabalFiles
            actual `shouldBe` ["/pkg-a/pkg-a.cabal"]

        it "prefers cabal.project.freeze over cabal.project" do
            let fs =
                    Map.fromList
                        [ ("/cabal.project.freeze", "packages: pkg-a\n")
                        , ("/cabal.project", "packages: pkg-b\n")
                        ]
                        `Map.union` multiPackageCabalFiles
                actual = runDiscovery fs [] discoverCabalFiles
            actual `shouldBe` ["/pkg-a/pkg-a.cabal"]

        describe "when a higher-priority file lists no packages" do
            it "falls through to the next file in priority order" do
                let fs =
                        Map.fromList
                            [ ("/cabal.project.local", "tests: True\n")
                            , ("/cabal.project", "packages: pkg-b\n")
                            ]
                            `Map.union` multiPackageCabalFiles
                    actual = runDiscovery fs [] discoverCabalFiles
                actual `shouldBe` ["/pkg-b/pkg-b.cabal"]

    describe "packages: entry resolution" do
        it "uses a direct .cabal path entry verbatim, without scanning a directory" do
            let fs = Map.singleton "/cabal.project" "packages: sub/foo.cabal\n"
                actual = runDiscovery fs [] discoverCabalFiles
            actual `shouldBe` ["/sub/foo.cabal"]

        it "skips glob entries under packages: (not expanded)" do
            let fs = Map.singleton "/cabal.project" "packages: */*.cabal\n"
                actual = runDiscovery fs [] discoverCabalFiles
            actual `shouldBe` []

    describe "$HOME/.cabal/config fallback" do
        describe "when no cabal.project files exist" do
            it "uses $HOME/.cabal/config as a last-resort packages source" do
                let fs =
                        Map.singleton "/home/user/.cabal/config" "packages: pkg-a\n"
                            `Map.union` multiPackageCabalFiles
                    actual = runDiscovery fs [("HOME", "/home/user")] discoverCabalFiles
                actual `shouldBe` ["/pkg-a/pkg-a.cabal"]

        describe "when $HOME/.cabal/config exists but lists no packages" do
            it "falls back to scanning the project root" do
                let fs =
                        Map.fromList
                            [ ("/home/user/.cabal/config", "")
                            , ("/myapp.cabal", cabalFixture)
                            ]
                    actual = runDiscovery fs [("HOME", "/home/user")] discoverCabalFiles
                actual `shouldBe` ["/myapp.cabal"]
  where
    pr = ProjectRoot "/"
    multiPackageCabalFiles =
        Map.fromList
            [ ("/pkg-a/pkg-a.cabal", libTestCabal "pkg-a")
            , ("/pkg-b/pkg-b.cabal", libTestCabal "pkg-b")
            ]
    runDiscovery fs env =
        runPureEff
            . runEnvConst env
            . evalState fs
            . runFileSystemState
            . runReader pr
