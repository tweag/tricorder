module Unit.Atelier.Effects.FileWatcherSpec (spec_FileWatcher) where

import Control.Concurrent (forkIO, killThread, newQSem, signalQSem, waitQSem)
import Data.IORef (modifyIORef, newIORef, readIORef)
import Data.List (isSuffixOf)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Hedgehog (Gen, PropertyT, forAll, (===))
import Test.Hspec (Spec, describe, it, shouldBe)
import Test.Hspec.Hedgehog (hedgehog)

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


spec_FileWatcher :: Spec
spec_FileWatcher = do
    describe "deduplicateDirs" do
        describe "properties" do
            it "result is an antichain: no element is an ancestor of another"
                $ hedgehog propAntichain
            it "result covers all inputs: every input has an ancestor-or-equal in the result"
                $ hedgehog propCoverage
            it "is idempotent"
                $ hedgehog propIdempotent
            it "result is a subset of the input"
                $ hedgehog propSubset

        describe "edge cases" do
            it "returns empty list unchanged" do
                deduplicateDirs [] `shouldBe` []

            it "does not treat a dir as an ancestor of a similarly named dir" do
                deduplicateDirs ["/src", "/srcover"] `shouldBe` ["/src", "/srcover"]

    describe "matchesAny" do
        it "matches a file under a watched directory" do
            matchesAny [dir "/proj/src"] "/proj/src/Foo.hs"
                `shouldBe` True

        it "does not match a relative watch dir against an absolute event path" do
            -- runFileWatcherIO must canonicalize Watch paths to absolute before
            -- calling matchesAny, because fsnotify always reports absolute paths.
            matchesAny [dir "src"] "/proj/src/Foo.hs"
                `shouldBe` False

        it "applies the file predicate" do
            matchesAny [dirWhere "/proj/src" (\f -> ".hs" `isSuffixOf` f)] "/proj/src/Foo.hs"
                `shouldBe` True
            matchesAny [dirWhere "/proj/src" (\f -> ".hs" `isSuffixOf` f)] "/proj/src/Foo.js"
                `shouldBe` False

    describe "runFileWatcherScripted" testScripted


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    describe "watchFilePaths" do
        it "calls the callback with the scripted path" do
            paths <- collectPaths ["/src/Foo.hs"]
            paths `shouldBe` ["/src/Foo.hs"]

        it "calls the callback with each path in order" do
            paths <- collectPaths ["/src/Foo.hs", "/src/Bar.hs"]
            paths `shouldBe` ["/src/Foo.hs", "/src/Bar.hs"]

        it "ignores the watch specification" do
            paths <- collectPathsWith [dir "/any"] ["/src/Foo.hs"]
            paths `shouldBe` ["/src/Foo.hs"]

        it "passes the full path to the callback unchanged" do
            let path = "/home/user/project/src/Some/Deep/Module.hs"
            paths <- collectPaths [path]
            paths `shouldBe` [path]


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
