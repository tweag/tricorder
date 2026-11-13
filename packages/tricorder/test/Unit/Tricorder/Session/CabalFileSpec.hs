module Unit.Tricorder.Session.CabalFileSpec (test_CabalFile) where

import Atelier.FileSystem.Path ((</>))
import Effectful (runPureEff)
import Effectful.Reader.Static (runReader)
import Test.Tasty (DependencyType (AllFinish), TestTree, dependentTestGroup, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.Effects.FileSystem.Glob qualified as Glob
import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log qualified as Log
import Atelier.FileSystem.Path qualified as Path
import Data.Map.Strict qualified as Map

import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.CabalFile
    ( CabalFile (..)
    , discoverCabalPackages
    , discoverStackPackages
    , readProjectFile
    )
import Tricorder.Session.StackProject (StackProject (..))
import Unit.Tricorder.Session.Helpers
    ( cabalFixture
    , multiPackageCabalFs
    , multiPackageFs
    , withHome
    , withProjectFiles
    )


test_CabalFile :: TestTree
test_CabalFile =
    testGroup
        "CabalFile"
        [ -- Discovery consults @$HOME/.cabal/config@, and @$HOME@ is process-global,
          -- so these must not run concurrently.
          dependentTestGroup "discoverCabalPackages" AllFinish testDiscoverCabalPackages
        , testGroup "discoverStackPackages" testDiscoverStackPackages
        , testGroup "readProjectFile" testReadProjectFile
        ]


-- | Pins the discovery contract: a @cabal.project@ (or @.local@/@.freeze@
-- variant) selects per-package @.cabal@ files from its @packages:@ stanza;
-- otherwise the @.cabal@ files in the project root are used. Falls back
-- further to @$HOME/.cabal/config@'s @packages:@ stanza if none of the
-- project-root files exist.
--
-- Runs against real temporary directories; see 'runDiscovery'.
testDiscoverCabalPackages :: [TestTree]
testDiscoverCabalPackages =
    [ testGroup
        "when there is no cabal.project"
        [ testCase "finds the .cabal files in the project root" do
            actual <- runDiscovery (Map.singleton (rel "myapp.cabal") cabalFixture)
            actual @?= Right [rel "myapp.cabal"]
        , testCase "returns no files when the root has no cabal file" do
            actual <- runDiscovery mempty
            actual @?= Right []
        ]
    , testGroup
        "when there is a multi-package cabal.project"
        [ testCase "resolves each listed package to its .cabal (regression: was root-only)" do
            actual <- runDiscovery multiPackageFs
            actual @?= Right [rel "pkg-a/pkg-a.cabal", rel "pkg-b/pkg-b.cabal"]
        ]
    , testGroup
        "priority among cabal.project.local, cabal.project.freeze, and cabal.project"
        [ testCase "prefers cabal.project.local over cabal.project" do
            actual <-
                runDiscovery
                    $ Map.fromList
                        [ (rel "cabal.project.local", "packages: pkg-a\n")
                        , (rel "cabal.project", "packages: pkg-b\n")
                        ]
                        `Map.union` multiPackageCabalFs
            actual @?= Right [rel "pkg-a/pkg-a.cabal"]
        , testCase "prefers cabal.project.freeze over cabal.project" do
            actual <-
                runDiscovery
                    $ Map.fromList
                        [ (rel "cabal.project.freeze", "packages: pkg-a\n")
                        , (rel "cabal.project", "packages: pkg-b\n")
                        ]
                        `Map.union` multiPackageCabalFs
            actual @?= Right [rel "pkg-a/pkg-a.cabal"]
        , testGroup
            "when a higher-priority file lists no packages"
            [ testCase "falls through to the next file in priority order" do
                actual <-
                    runDiscovery
                        $ Map.fromList
                            [ (rel "cabal.project.local", "tests: True\n")
                            , (rel "cabal.project", "packages: pkg-b\n")
                            ]
                            `Map.union` multiPackageCabalFs
                actual @?= Right [rel "pkg-b/pkg-b.cabal"]
            ]
        ]
    , testGroup
        "packages: entry resolution"
        [ testCase "uses a direct .cabal path entry verbatim, without scanning a directory" do
            actual <- runDiscovery $ Map.singleton (rel "cabal.project") "packages: sub/foo.cabal\n"
            actual @?= Right [rel "sub/foo.cabal"]
        , testCase "expands a glob entry matching .cabal files directly" do
            actual <-
                runDiscovery
                    $ Map.singleton (rel "cabal.project") "packages: */*.cabal\n"
                        `Map.union` multiPackageCabalFs
            fromRight [] actual @?= [rel "pkg-a/pkg-a.cabal", rel "pkg-b/pkg-b.cabal"]
        , testCase "expands a glob entry matching package directories" do
            actual <-
                runDiscovery
                    $ Map.singleton (rel "cabal.project") "packages: */\n"
                        `Map.union` multiPackageCabalFs
            fromRight [] actual @?= [rel "pkg-a/pkg-a.cabal", rel "pkg-b/pkg-b.cabal"]
        , testCase "returns no files when a glob entry matches nothing" do
            actual <- runDiscovery $ Map.singleton (rel "cabal.project") "packages: */*.cabal\n"
            actual @?= Right []
        ]
    , testGroup
        "$HOME/.cabal/config fallback"
        [ testGroup
            "when no cabal.project files exist"
            [ testCase "uses $HOME/.cabal/config as a last-resort packages source" do
                actual <-
                    runDiscovery
                        $ Map.singleton (rel "home/.cabal/config") "packages: pkg-a\n"
                            `Map.union` multiPackageCabalFs
                actual @?= Right [rel "pkg-a/pkg-a.cabal"]
            ]
        , testGroup
            "when $HOME/.cabal/config exists but lists no packages"
            [ testCase "falls back to scanning the project root" do
                actual <-
                    runDiscovery
                        $ Map.fromList
                            [ (rel "home/.cabal/config", "")
                            , (rel "myapp.cabal", cabalFixture)
                            ]
                actual @?= Right [rel "myapp.cabal"]
            ]
        ]
    , testGroup
        "packages: single-line list"
        [ testGroup
            "when package list is comma-separated"
            [ testCase "parses package names correctly" do
                actual <-
                    runDiscovery
                        $ Map.singleton (rel "cabal.project") "packages: pkg-a, pkg-b\n"
                            `Map.union` multiPackageCabalFs
                fromRight [] actual @?= [rel "pkg-a/pkg-a.cabal", rel "pkg-b/pkg-b.cabal"]
            ]
        ]
    ]
  where
    -- Unchecked, for brevity: test inputs are known-good relative paths.
    rel :: FilePath -> Path.Relative
    rel = either error id . Path.fromFilePath


-- | Materialise the given files in a temporary project root, run package
-- discovery there, and report the discovered paths relative to that root.
--
-- @$HOME@ is pointed at @home/@ inside the root, so a test can seed
-- @home/.cabal/config@ and tests that don't are unaffected by the real
-- @$HOME@.
runDiscovery :: Map Path.Relative ByteString -> IO (Either Text [Path.Relative])
runDiscovery files =
    withProjectFiles files \root -> do
        let pr = ProjectRoot root
        result <-
            withHome (root </> Path.relative @"home")
                $ Glob.runIO
                $ runReader pr discoverCabalPackages
        pure $ fmap (fmap (Path.makeRelative root)) result


-- | Pins the discovery contract: with a @stack.yaml@, package paths come
-- straight from its @packages:@ list, resolved against the project root.
testDiscoverStackPackages :: [TestTree]
testDiscoverStackPackages =
    [ testCase "resolves each package path against the project root" do
        let actual = runStack (StackProject [Path.rel @"pkg-a", Path.rel @"pkg-b"]) discoverStackPackages
        actual @?= Right [Path.absolute @"/pkg-a", Path.absolute @"/pkg-b"]
    , testCase "normalises resolved paths" do
        let actual = runStack (StackProject [Path.rel @"./pkg-a"]) discoverStackPackages
        actual @?= Right [Path.absolute @"/pkg-a"]
    , testCase "returns no packages when the list is empty" do
        let actual = runStack (StackProject []) discoverStackPackages
        actual @?= Right []
    ]
  where
    pr = ProjectRoot (Path.absolute @"/")
    runStack result =
        runPureEff
            . runReader pr
            . Log.runNoOp
            . Input.withConst result


-- | Pins how a package path resolves to a @.cabal@ file: a directory path
-- (as listed in @stack.yaml@) reads the @.cabal@ file inside it.
testReadProjectFile :: [TestTree]
testReadProjectFile =
    [ testGroup
        "when the path is a directory"
        [ testCase "reads the .cabal file inside it" do
            actual <- runRead multiPackageCabalFs
            actual @?= Right (Path.rel @"pkg-a/pkg-a.cabal")
        , testCase "fails with the directory path when it contains no .cabal file" do
            actual <- runRead $ Map.singleton (Path.rel @"pkg-a/package.yaml") "name: pkg-a\n"
            actual @?= Left (Path.rel @"pkg-a")
        ]
    ]
  where
    -- Reads @pkg-a@ in a temporary project root, reporting paths relative to it.
    runRead files =
        withProjectFiles files \root -> do
            result <- readProjectFile $ root </> Path.rel @"pkg-a"
            pure
                $ bimap (Path.makeRelative root) (Path.makeRelative root . (.projectFilePath)) result
