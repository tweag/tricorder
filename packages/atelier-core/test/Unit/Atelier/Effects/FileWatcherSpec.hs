module Unit.Atelier.Effects.FileWatcherSpec (test_FileWatcher) where

import Control.Concurrent (forkIO, killThread, newQSem, signalQSem, waitQSem)
import Data.IORef (modifyIORef, newIORef, readIORef)
import Data.List (isSuffixOf)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Hedgehog (Gen, PropertyT, forAll, property, (===))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))
import Test.Tasty.Hedgehog (testProperty)

import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range

import Atelier.Effects.FileWatcher
    ( FileEvent (..)
    , FileWatcher
    , Watch
    , deduplicateDirs
    , dir
    , dirWhere
    , matchesAny
    , runFileWatcherScripted
    , watchFilePaths
    )


test_FileWatcher :: TestTree
test_FileWatcher =
    testGroup
        "FileWatcher"
        [ testGroup
            "deduplicateDirs"
            [ testGroup
                "properties"
                [ testProperty "result is an antichain: no element is an ancestor of another"
                    $ property propAntichain
                , testProperty "result covers all inputs: every input has an ancestor-or-equal in the result"
                    $ property propCoverage
                , testProperty "is idempotent"
                    $ property propIdempotent
                , testProperty "result is a subset of the input"
                    $ property propSubset
                ]
            , testGroup
                "edge cases"
                [ testCase "returns empty list unchanged" do
                    deduplicateDirs [] @?= []
                , testCase "does not treat a dir as an ancestor of a similarly named dir" do
                    deduplicateDirs ["/src", "/srcover"] @?= ["/src", "/srcover"]
                ]
            ]
        , testGroup
            "matchesAny"
            [ testCase "matches a file under a watched directory" do
                matchesAny [dir "/proj/src"] "/proj/src/Foo.hs"
                    @?= True
            , testCase "does not match a relative watch dir against an absolute event path" do
                -- runFileWatcherIO must canonicalize Watch paths to absolute before
                -- calling matchesAny, because fsnotify always reports absolute paths.
                matchesAny [dir "src"] "/proj/src/Foo.hs"
                    @?= False
            , testCase "applies the file predicate" do
                matchesAny [dirWhere "/proj/src" (\f -> ".hs" `isSuffixOf` f)] "/proj/src/Foo.hs"
                    @?= True
                matchesAny [dirWhere "/proj/src" (\f -> ".hs" `isSuffixOf` f)] "/proj/src/Foo.js"
                    @?= False
            ]
        , testGroup "runFileWatcherScripted" testScripted
        ]


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: [TestTree]
testScripted =
    [ testGroup
        "watchFilePaths"
        [ testCase "calls the callback with the scripted path" do
            paths <- collectPaths ["/src/Foo.hs"]
            paths @?= ["/src/Foo.hs"]
        , testCase "calls the callback with each path in order" do
            paths <- collectPaths ["/src/Foo.hs", "/src/Bar.hs"]
            paths @?= ["/src/Foo.hs", "/src/Bar.hs"]
        , testCase "ignores the watch specification" do
            paths <- collectPathsWith [dir "/any"] ["/src/Foo.hs"]
            paths @?= ["/src/Foo.hs"]
        , testCase "passes the full path to the callback unchanged" do
            let path = "/home/user/project/src/Some/Deep/Module.hs"
            paths <- collectPaths [path]
            paths @?= [path]
        ]
    ]


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- | Run the scripted interpreter, collecting all callback-delivered paths.
-- Uses a semaphore to wait for exactly N events before cancelling the watcher.
collectPaths :: [FilePath] -> IO [FilePath]
collectPaths = collectPathsWith []


collectPathsWith :: [Watch] -> [FilePath] -> IO [FilePath]
collectPathsWith watches scripted = do
    ref <- newIORef []
    sem <- newQSem 0
    tid <- forkIO $ void $ runScripted scripted $ watchFilePaths watches \filePath _fileEvent -> liftIO do
        modifyIORef ref (<> [filePath])
        signalQSem sem
    replicateM_ (length scripted) (waitQSem sem)
    killThread tid
    readIORef ref


runScripted :: [FilePath] -> Eff '[FileWatcher, Concurrent, IOE] a -> IO a
runScripted paths = runEff . runConcurrent . runFileWatcherScripted (map (,Modified) paths)


--------------------------------------------------------------------------------
-- Properties
--------------------------------------------------------------------------------

propAntichain :: PropertyT IO ()
propAntichain = do
    dirs <- forAll genDirs
    let result = deduplicateDirs dirs
    let pairs = [(a, b) | a <- result, b <- result, a /= b]
    all (\(a, b) -> not (isStrictAncestor a b)) pairs === True


propCoverage :: PropertyT IO ()
propCoverage = do
    dirs <- forAll genDirs
    let result = deduplicateDirs dirs
    all (isCoveredBy result) dirs === True


propIdempotent :: PropertyT IO ()
propIdempotent = do
    dirs <- forAll genDirs
    deduplicateDirs (deduplicateDirs dirs) === deduplicateDirs dirs


propSubset :: PropertyT IO ()
propSubset = do
    dirs <- forAll genDirs
    let result = deduplicateDirs dirs
    all (`elem` dirs) result === True


--------------------------------------------------------------------------------
-- Generators
--------------------------------------------------------------------------------

genDirs :: Gen [FilePath]
genDirs = Gen.list (Range.linear 0 10) genAbsDir


-- Generates absolute paths like /a/b/c using short segments to encourage
-- overlaps between generated paths.
genAbsDir :: Gen FilePath
genAbsDir = do
    segments <- Gen.list (Range.linear 1 4) genSegment
    pure $ "/" <> intercalate "/" segments


genSegment :: Gen String
genSegment = Gen.string (Range.linear 1 3) (Gen.element ['a', 'b', 'c', 'd'])


--------------------------------------------------------------------------------
-- Helpers (mirror of FileWatcher internals)
--------------------------------------------------------------------------------

isStrictAncestor :: FilePath -> FilePath -> Bool
isStrictAncestor parent child = (parent <> "/") `isPrefixOf` child


isCoveredBy :: [FilePath] -> FilePath -> Bool
isCoveredBy result d = any (\r -> r == d || isStrictAncestor r d) result
