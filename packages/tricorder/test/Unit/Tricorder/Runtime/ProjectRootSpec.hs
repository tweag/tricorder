module Unit.Tricorder.Runtime.ProjectRootSpec (test_ProjectRoot) where

import Atelier.Effects.FileSystem (FileSystem (..))
import Effectful (runPureEff)
import Effectful.Dispatch.Dynamic (interpret_)
import System.FilePath (takeDirectory, takeFileName)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Runtime.ProjectRoot (findFileUpwards, findProjectRoot)


test_ProjectRoot :: TestTree
test_ProjectRoot =
    testGroup
        "ProjectRoot"
        [ testGroup
            "findProjectRoot"
            [ testCase "stops at a package directory inside a larger project" do
                run ["/repo/stack.yaml", "/repo/pkg/pkg.cabal"] "/repo/pkg/src"
                    @?= Just "/repo/pkg"
            , testCase "finds stack.yaml in an ancestor" do
                run ["/repo/stack.yaml", "/repo/pkg/README.md"] "/repo/pkg"
                    @?= Just "/repo"
            , testCase "finds cabal.project in the current directory" do
                run ["/repo/cabal.project"] "/repo" @?= Just "/repo"
            , testCase "finds nothing without any project files" do
                run ["/repo/pkg/README.md"] "/repo/pkg" @?= Nothing
            ]
        , testGroup
            "findFileUpwards"
            [ testCase "finds stack.yaml above a package directory" do
                runUp "stack.yaml" ["/repo/stack.yaml", "/repo/pkg/pkg.cabal"] "/repo/pkg"
                    @?= Just "/repo"
            , testCase "prefers the nearest match" do
                runUp "cabal.project" ["/repo/cabal.project", "/repo/pkg/cabal.project"] "/repo/pkg"
                    @?= Just "/repo/pkg"
            , testCase "finds nothing when the file is absent" do
                runUp "stack.yaml" ["/repo/cabal.project"] "/repo" @?= Nothing
            ]
        ]


-- | Run 'findProjectRoot' against a fake filesystem where 'listDirectory'
-- returns the bare names of the files directly inside a directory, like the
-- real one.
run :: [FilePath] -> FilePath -> Maybe FilePath
run files start = runPureEff $ fakeFilesystem files $ findProjectRoot start


fakeFilesystem :: [FilePath] -> Eff (FileSystem : es) a -> Eff es a
fakeFilesystem files = interpret_ \case
    ListDirectory dir -> pure [takeFileName f | f <- files, takeDirectory f == dir]
    DoesFileExist f -> pure $ f `elem` files
    _ -> error "unexpected FileSystem operation"


runUp :: FilePath -> [FilePath] -> FilePath -> Maybe FilePath
runUp name files start = runPureEff $ fakeFilesystem files $ findFileUpwards name start
