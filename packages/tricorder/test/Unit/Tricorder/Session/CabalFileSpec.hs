module Unit.Tricorder.Session.CabalFileSpec (spec_CabalFile) where

import Atelier.Effects.Env (runEnvConst)
import Atelier.Effects.FileSystem (runFileSystemState)
import Effectful (runPureEff)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState)
import Test.Hspec (Spec, describe, it, shouldBe, shouldMatchList)

import Atelier.Effects.FileSystem.Glob qualified as Glob
import Data.Map.Strict qualified as Map

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.CabalFile (discoverCabalPackages, discoverStackPackages)
import Tricorder.Session.StackYaml (StackProject (..))
import Unit.Tricorder.Session.Helpers (cabalFixture, multiPackageCabalFs, multiPackageFs)

import Tricorder.Session.StackYaml qualified as StackYaml


spec_CabalFile :: Spec
spec_CabalFile = do
    describe "discoverCabalPackages" testDiscoverCabalPackages
    describe "discoverStackPackages" testDiscoverStackPackages


-- | Pins the discovery contract: a @cabal.project@ (or @.local@/@.freeze@
-- variant) selects per-package @.cabal@ files from its @packages:@ stanza;
-- otherwise the @.cabal@ files in the project root are used. Falls back
-- further to @$HOME/.cabal/config@'s @packages:@ stanza if none of the
-- project-root files exist.
testDiscoverCabalPackages :: Spec
testDiscoverCabalPackages = do
    describe "when there is no cabal.project" do
        it "finds the .cabal files in the project root" do
            let actual =
                    runDiscovery (Map.singleton "/myapp.cabal" cabalFixture) []
                        $ discoverCabalPackages
            actual `shouldBe` Right ["/myapp.cabal"]

        it "returns no files when the root has no cabal file" do
            let actual = runDiscovery mempty [] discoverCabalPackages
            actual `shouldBe` Right []

    describe "when there is a multi-package cabal.project" do
        it "resolves each listed package to its .cabal (regression: was root-only)" do
            let actual = runDiscovery multiPackageFs [] discoverCabalPackages
            actual `shouldBe` Right ["/pkg-a/pkg-a.cabal", "/pkg-b/pkg-b.cabal"]

    describe "priority among cabal.project.local, cabal.project.freeze, and cabal.project" do
        it "prefers cabal.project.local over cabal.project" do
            let fs =
                    Map.fromList
                        [ ("/cabal.project.local", "packages: pkg-a\n")
                        , ("/cabal.project", "packages: pkg-b\n")
                        ]
                        `Map.union` multiPackageCabalFs
                actual = runDiscovery fs [] discoverCabalPackages
            actual `shouldBe` Right ["/pkg-a/pkg-a.cabal"]

        it "prefers cabal.project.freeze over cabal.project" do
            let fs =
                    Map.fromList
                        [ ("/cabal.project.freeze", "packages: pkg-a\n")
                        , ("/cabal.project", "packages: pkg-b\n")
                        ]
                        `Map.union` multiPackageCabalFs
                actual = runDiscovery fs [] discoverCabalPackages
            actual `shouldBe` Right ["/pkg-a/pkg-a.cabal"]

        describe "when a higher-priority file lists no packages" do
            it "falls through to the next file in priority order" do
                let fs =
                        Map.fromList
                            [ ("/cabal.project.local", "tests: True\n")
                            , ("/cabal.project", "packages: pkg-b\n")
                            ]
                            `Map.union` multiPackageCabalFs
                    actual = runDiscovery fs [] discoverCabalPackages
                actual `shouldBe` Right ["/pkg-b/pkg-b.cabal"]

    describe "packages: entry resolution" do
        it "uses a direct .cabal path entry verbatim, without scanning a directory" do
            let fs = Map.singleton "/cabal.project" "packages: sub/foo.cabal\n"
                actual = runDiscovery fs [] discoverCabalPackages
            actual `shouldBe` Right ["/sub/foo.cabal"]

        it "expands a glob entry matching .cabal files directly" do
            let fs = Map.singleton "/cabal.project" "packages: */*.cabal\n"
                script = [Glob.NextGlobDir1 ["/pkg-a/pkg-a.cabal", "/pkg-b/pkg-b.cabal"]]
                actual = runDiscoveryGlob fs [] script discoverCabalPackages
            fromRight [] actual `shouldMatchList` ["/pkg-a/pkg-a.cabal", "/pkg-b/pkg-b.cabal"]

        it "expands a glob entry matching package directories" do
            let fs =
                    Map.singleton "/cabal.project" "packages: */\n"
                        `Map.union` multiPackageCabalFs
                script = [Glob.NextGlobDir1 ["/pkg-a", "/pkg-b"]]
                actual = runDiscoveryGlob fs [] script discoverCabalPackages
            fromRight [] actual `shouldMatchList` ["/pkg-a/pkg-a.cabal", "/pkg-b/pkg-b.cabal"]

        it "returns no files when a glob entry matches nothing" do
            let fs = Map.singleton "/cabal.project" "packages: */*.cabal\n"
                script = [Glob.NextGlobDir1 []]
                actual = runDiscoveryGlob fs [] script discoverCabalPackages
            actual `shouldBe` Right []

    describe "$HOME/.cabal/config fallback" do
        describe "when no cabal.project files exist" do
            it "uses $HOME/.cabal/config as a last-resort packages source" do
                let fs =
                        Map.singleton "/home/user/.cabal/config" "packages: pkg-a\n"
                            `Map.union` multiPackageCabalFs
                    actual = runDiscovery fs [("HOME", "/home/user")] discoverCabalPackages
                actual `shouldBe` Right ["/pkg-a/pkg-a.cabal"]

        describe "when $HOME/.cabal/config exists but lists no packages" do
            it "falls back to scanning the project root" do
                let fs =
                        Map.fromList
                            [ ("/home/user/.cabal/config", "")
                            , ("/myapp.cabal", cabalFixture)
                            ]
                    actual = runDiscovery fs [("HOME", "/home/user")] discoverCabalPackages
                actual `shouldBe` Right ["/myapp.cabal"]

    describe "packages: single-line list" do
        describe "when package list is comma-separated" do
            it "parses package names correctly" do
                let fs =
                        Map.singleton "/cabal.project" "packages: pkg-a, pkg-b\n"
                            `Map.union` multiPackageCabalFs
                    actual = runDiscovery fs [] discoverCabalPackages
                fromRight [] actual `shouldMatchList` ["/pkg-a/pkg-a.cabal", "/pkg-b/pkg-b.cabal"]
  where
    pr = ProjectRoot "/"
    runDiscovery fs env = runDiscoveryGlob fs env []
    runDiscoveryGlob fs env script =
        runPureEff
            . runEnvConst env
            . evalState fs
            . runFileSystemState
            . Glob.runScripted script
            . runReader pr


-- | Pins the discovery contract: with a @stack.yaml@, package paths come
-- straight from its @packages:@ list, resolved against the project root.
testDiscoverStackPackages :: Spec
testDiscoverStackPackages = do
    it "resolves each package path against the project root" do
        let actual = runStack (Right $ StackProject ["pkg-a", "pkg-b"]) discoverStackPackages
        actual `shouldBe` Right ["/pkg-a", "/pkg-b"]

    it "normalises resolved paths" do
        let actual = runStack (Right $ StackProject ["./pkg-a"]) discoverStackPackages
        actual `shouldBe` Right ["/pkg-a"]

    it "returns no packages when the list is empty" do
        let actual = runStack (Right $ StackProject []) discoverStackPackages
        actual `shouldBe` Right []

    it "propagates a stack.yaml read failure as an error" do
        let actual = runStack (Left "boom") discoverStackPackages
        actual `shouldBe` Left "Failed to read project file: boom"
  where
    pr = ProjectRoot "/"
    runStack result =
        runPureEff
            . runReader pr
            . StackYaml.runConst result
