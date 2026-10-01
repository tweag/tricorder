module Unit.Tricorder.Session.WatchDirsSpec (test_WatchDirs) where

import Data.Default (def)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Target (ComponentKind (..), Target (..))
import Tricorder.Session.WatchDirs (WatchDirs (..), resolveWatchDirs, sourceDirsForTarget)
import Unit.Tricorder.Session.Helpers (gpd, multiCabalFiles, singleCabalFile)

import Tricorder.Session.Target qualified as Target


test_WatchDirs :: TestTree
test_WatchDirs =
    testGroup
        "WatchDirs"
        [ testGroup "resolveWatchDirs" testResolveWatchDirs
        , testGroup "sourceDirsForTarget" testSourceDirsForTarget
        ]


testResolveWatchDirs :: [TestTree]
testResolveWatchDirs =
    [ testGroup
        "when watch_dirs is set in config"
        [ testCase "uses config dirs relative to project root" do
            let WatchDirs actual =
                    resolveWatchDirs pr [] def {watchDirs = ["src", "test"]} []
            actual @?= ["/src", "/test"]
        ]
    , testGroup
        "when watch_dirs is not set"
        [ testCase "falls back to [\".\"] when targets list is empty" do
            let WatchDirs actual = resolveWatchDirs pr [] def []
            actual @?= ["."]
        , testCase "infers source dirs from resolved targets" do
            let WatchDirs actual =
                    resolveWatchDirs pr singleCabalFile def (mkTargets ["lib:myapp", "test:myapp-test"])
            actual @?= ["/src", "/test"]
        , testCase "falls back to [\".\"] when there are no cabal files" do
            let WatchDirs actual =
                    resolveWatchDirs pr [] def (mkTargets ["lib:myapp"])
            actual @?= ["."]
        , -- Sharp edge: an unparseable .cabal yields no source dirs, so resolution
          -- falls back to watching the whole project root. This pins the current
          -- behavior; if it ever changes to something narrower, update this test.
          testCase "falls back to [\".\"] when no cabal files are found or parsed" do
            let WatchDirs actual =
                    resolveWatchDirs pr [] def (mkTargets ["lib:myapp"])
            actual @?= ["."]
        ]
    , testGroup
        "when the project is a multi-package cabal.project"
        [ testCase "infers per-package source dirs, scoped to each package's directory" do
            let WatchDirs actual =
                    resolveWatchDirs
                        pr
                        multiCabalFiles
                        def
                        (mkTargets ["lib:pkg-a", "test:pkg-a-test", "lib:pkg-b", "test:pkg-b-test"])
            actual
                @?= ["/pkg-a/src", "/pkg-a/test", "/pkg-b/src", "/pkg-b/test"]
        , testCase "scopes a bare package-name target to that package, ignoring siblings" do
            let WatchDirs actual =
                    resolveWatchDirs pr multiCabalFiles def (mkTargets ["pkg-a"])
            actual @?= ["/pkg-a/src", "/pkg-a/test"]
        ]
    ]
  where
    pr = ProjectRoot "/"


-- | These exercise the 'Target' -> dirs resolution directly with constructed
-- 'Target' values; the string -> 'Target' parsing is covered by 'testParseTarget'.
testSourceDirsForTarget :: [TestTree]
testSourceDirsForTarget =
    [ testGroup
        "Qualified Lib"
        [ testGroup
            "when the name is empty"
            [ testCase "returns the main library source dirs" do
                sourceDirsForTarget gpd (Qualified Lib "") @?= ["src"]
            ]
        , testGroup
            "when the name matches the package name"
            [ testCase "returns the main library source dirs" do
                sourceDirsForTarget gpd (Qualified Lib "myapp") @?= ["src"]
            ]
        , testGroup
            "when the name matches a sub-library"
            [ testCase "returns the sub-library source dirs" do
                sourceDirsForTarget gpd (Qualified Lib "myapp-utils") @?= ["utils"]
            ]
        , testGroup
            "when the sub-library is unknown"
            [ testCase "returns an empty list" do
                sourceDirsForTarget gpd (Qualified Lib "nonexistent") @?= []
            ]
        ]
    , testGroup
        "Qualified FLib"
        [ testCase "returns the foreign-library source dirs" do
            sourceDirsForTarget gpd (Qualified FLib "myapp-flib") @?= ["flib"]
        ]
    , testGroup
        "Qualified Exe"
        [ testCase "returns the executable source dirs" do
            sourceDirsForTarget gpd (Qualified Exe "myapp-exe") @?= ["app"]
        ]
    , testGroup
        "Qualified Test"
        [ testCase "returns the test suite source dirs" do
            sourceDirsForTarget gpd (Qualified Test "myapp-test") @?= ["test"]
        ]
    , testGroup
        "Qualified Bench"
        [ testCase "returns the benchmark source dirs" do
            sourceDirsForTarget gpd (Qualified Bench "myapp-bench") @?= ["bench"]
        ]
    , testGroup
        "Bare (package name)"
        [ testCase "returns every component's source dirs" do
            sourceDirsForTarget gpd (Bare "myapp") @?= ["src", "utils", "flib", "app", "test", "bench"]
        ]
    , testGroup
        "Bare (component name)"
        [ testGroup
            "when it names a sub-library"
            [ testCase "returns the sub-library source dirs" do
                sourceDirsForTarget gpd (Bare "myapp-utils") @?= ["utils"]
            ]
        , testGroup
            "when it names an executable"
            [ testCase "returns the executable source dirs" do
                sourceDirsForTarget gpd (Bare "myapp-exe") @?= ["app"]
            ]
        , testGroup
            "when it names a test suite"
            [ testCase "returns the test suite source dirs" do
                sourceDirsForTarget gpd (Bare "myapp-test") @?= ["test"]
            ]
        , testGroup
            "when it matches no component"
            [ testCase "returns an empty list" do
                sourceDirsForTarget gpd (Bare "unknown") @?= []
            ]
        ]
    , testGroup
        "Unrecognized"
        [ testCase "matches an aliased kind prefix by trailing name" do
            sourceDirsForTarget gpd (Unrecognized "executable:myapp-exe") @?= ["app"]
        , testCase "matches a case-variant kind prefix by trailing name" do
            sourceDirsForTarget gpd (Unrecognized "Test-Suite:myapp-test") @?= ["test"]
        , testCase "matches the main library when the trailing name is the package name" do
            sourceDirsForTarget gpd (Unrecognized "library:myapp") @?= ["src"]
        , testCase "returns an empty list when the trailing name matches no component" do
            sourceDirsForTarget gpd (Unrecognized "bogus:x") @?= []
        ]
    ]


mkTargets :: [Text] -> [Target]
mkTargets = fmap Target.parse
