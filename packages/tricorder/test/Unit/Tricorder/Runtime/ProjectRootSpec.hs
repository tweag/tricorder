module Unit.Tricorder.Runtime.ProjectRootSpec (test_ProjectRoot) where

import Atelier.FileSystem.Path ((</>))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.FileSystem.Path qualified as Path
import Data.Map.Strict qualified as Map

import Tricorder.Runtime.ProjectRoot (findFileUpwards, findProjectRoot)
import Unit.Tricorder.Session.Helpers (withProjectFiles)


test_ProjectRoot :: TestTree
test_ProjectRoot =
    testGroup
        "ProjectRoot"
        [ testGroup
            "findProjectRoot"
            [ testCase "stops at a package directory inside a larger project" do
                actual <- run ["stack.yaml", "pkg/pkg.cabal", "pkg/src/Foo.hs"] (Path.rel @"pkg/src")
                actual @?= Just (Path.rel @"pkg")
            , testCase "finds stack.yaml in an ancestor" do
                actual <- run ["stack.yaml", "pkg/README.md"] (Path.rel @"pkg")
                actual @?= Just (Path.rel @".")
            , testCase "finds cabal.project in the current directory" do
                actual <- run ["cabal.project"] (Path.rel @".")
                actual @?= Just (Path.rel @".")
            , testCase "finds nothing without any project files" do
                actual <- run ["pkg/README.md"] (Path.rel @"pkg")
                -- The temporary directory is created under /tmp, which has no
                -- project files in any ancestor.
                actual @?= Nothing
            ]
        , testGroup
            "findFileUpwards"
            [ testCase "finds stack.yaml above a package directory" do
                actual <- runUp (Path.rel @"stack.yaml") ["stack.yaml", "pkg/pkg.cabal"] (Path.rel @"pkg")
                actual @?= Just (Path.rel @".")
            , testCase "prefers the nearest match" do
                actual <- runUp (Path.rel @"cabal.project") ["cabal.project", "pkg/cabal.project"] (Path.rel @"pkg")
                actual @?= Just (Path.rel @"pkg")
            , testCase "finds nothing when the file is absent" do
                actual <- runUp (Path.rel @"stack.yaml") ["cabal.project"] (Path.rel @".")
                actual @?= Nothing
            ]
        ]


-- | Run 'findProjectRoot' from a directory inside a temporary project root
-- seeded with empty files, reporting the result relative to that root.
run :: [FilePath] -> Path.Relative -> IO (Maybe Path.Relative)
run files start = withProjectFiles (seed files) \root ->
    fmap (Path.makeRelative root) <$> findProjectRoot (root </> start)


-- | Run 'findFileUpwards' likewise.
runUp :: Path.Relative -> [FilePath] -> Path.Relative -> IO (Maybe Path.Relative)
runUp name files start = withProjectFiles (seed files) \root ->
    fmap (Path.makeRelative root) <$> findFileUpwards name (root </> start)


seed :: [FilePath] -> Map Path.Relative ByteString
seed files = Map.fromList [(rel f, "") | f <- files]


rel :: FilePath -> Path.Relative
rel = either error id . Path.fromFilePath
