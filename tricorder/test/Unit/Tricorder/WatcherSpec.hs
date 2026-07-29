module Unit.Tricorder.WatcherSpec (spec_Watcher) where

import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.FileWatcher (FileEvent (..), matchesAny)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Dispatch.Dynamic (reinterpret_)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (execState, put)
import Effectful.Writer.Static.Shared (runWriter)
import Test.Hspec (Spec, describe, it, shouldBe, shouldMatchList)
import Text.Regex.TDFA.ReadRegex (parseRegex)

import Atelier.Effects.Publishing.Pub qualified as Pub

import Tricorder.BuildState
    ( CabalChangeDetected (..)
    , ChangeKind (..)
    , DaemonInfo (..)
    , SourceChangeDetected (..)
    )
import Tricorder.Effects.BuildStore (BuildStore (..))
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (WatchDirs (..), WatchExclusionPatterns (WatchExclusionPatterns))
import Tricorder.Watcher (WatchedFile (..), WatcherSession (..), makeWatches, markWatchedFiles)


spec_Watcher :: Spec
spec_Watcher = do
    describe "markWatchedFiles" testMarkWatchedFiles
    describe "makeWatches" testMakeWatches


testMarkWatchedFiles :: Spec
testMarkWatchedFiles = do
    it "should mark build store as dirty" do
        ((state, _), _) <- runTest "foo"
        state `shouldBe` Just SourceChange

    describe "with non-cabal file change" $ it "should publish SourceChangeDetected" do
        (_, sourceChanges) <- runTest "foo"
        sourceChanges `shouldMatchList` [SourceChangeDetected "foo" Modified]

    describe "with cabal file change" $ it "should publish CabalChangeDetected" do
        ((_, cabalChanges), _) <- runTest "foo.cabal"
        cabalChanges `shouldMatchList` [CabalChangeDetected "foo.cabal" Modified]
  where
    runTest =
        runEff
            . runConcurrent
            . runDelay
            . runReader emptyDaemonInfo
            . runWriter
            . Pub.toWriter @SourceChangeDetected
            . runWriter
            . Pub.toWriter @CabalChangeDetected
            . mockBuildStore
            . markWatchedFiles
            . (`WatchedFile` Modified)
    mockBuildStore :: Eff (BuildStore : es) a -> Eff es (Maybe ChangeKind)
    mockBuildStore = reinterpret_ (execState Nothing) \case
        MarkDirty ck -> put $ Just ck
        _ -> error "Not implemented"


testMakeWatches :: Spec
testMakeWatches = do
    describe "source watches" do
        it "matches .hs files in configured watch dirs" do
            let watches = makeWatches (ProjectRoot "/proj") (watcherSession ["/proj/src"] [])
            matchesAny watches "/proj/src/Foo.hs" `shouldBe` True

        it "does not match non-.hs files" do
            let watches = makeWatches (ProjectRoot "/proj") (watcherSession ["/proj/src"] [])
            matchesAny watches "/proj/src/Foo.txt" `shouldBe` False

        it "excludes paths containing dist-newstyle" do
            let watches = makeWatches (ProjectRoot "/proj") (watcherSession ["/proj/src"] [])
            matchesAny watches "/proj/src/dist-newstyle/Foo.hs" `shouldBe` False

        it "excludes paths matching an exclusion pattern" do
            let pat = parsePattern "vendor"
                watches = makeWatches (ProjectRoot "/proj") (watcherSession ["/proj/src"] [pat])
            matchesAny watches "/proj/src/vendor/Foo.hs" `shouldBe` False
            matchesAny watches "/proj/src/Foo.hs" `shouldBe` True

        it "matches .hs files across multiple watch dirs" do
            let watches = makeWatches (ProjectRoot "/proj") (watcherSession ["/proj/src", "/proj/test"] [])
            matchesAny watches "/proj/src/Foo.hs" `shouldBe` True
            matchesAny watches "/proj/test/FooSpec.hs" `shouldBe` True

        -- Second line of defense: 'cabalWatches' registers the whole project
        -- root, and 'deduplicateDirs' collapses the narrow source dirs into it,
        -- so the OS watches the entire repo recursively. 'matchesAny' is what
        -- re-scopes events back to the configured dirs — a .hs file in a sibling
        -- package must not match.
        it "does not match a .hs file in a sibling package outside the watch dirs" do
            let watches = makeWatches (ProjectRoot "/proj") (watcherSession ["/proj/pkg-a/src"] [])
            matchesAny watches "/proj/pkg-a/src/Foo.hs" `shouldBe` True
            matchesAny watches "/proj/pkg-b/src/Foo.hs" `shouldBe` False

    describe "cabal watches" do
        it "matches .cabal files under project root" do
            let watches = makeWatches (ProjectRoot "/proj") emptyWatcherSession
            matchesAny watches "/proj/foo.cabal" `shouldBe` True

        it "matches cabal.project under project root" do
            let watches = makeWatches (ProjectRoot "/proj") emptyWatcherSession
            matchesAny watches "/proj/cabal.project" `shouldBe` True

        it "matches package.yaml under project root" do
            let watches = makeWatches (ProjectRoot "/proj") emptyWatcherSession
            matchesAny watches "/proj/package.yaml" `shouldBe` True

        it "does not match non-cabal files" do
            let watches = makeWatches (ProjectRoot "/proj") emptyWatcherSession
            matchesAny watches "/proj/README.md" `shouldBe` False

        it "excludes cabal files under dist-newstyle" do
            let watches = makeWatches (ProjectRoot "/proj") emptyWatcherSession
            matchesAny watches "/proj/dist-newstyle/foo.cabal" `shouldBe` False
  where
    parsePattern p = fromRight (error . toText $ "bad test pattern: " <> p) (parseRegex p)
    emptyWatcherSession = watcherSession [] []
    watcherSession dirs patterns = WatcherSession (WatchDirs dirs) (WatchExclusionPatterns patterns)


emptyDaemonInfo :: DaemonInfo
emptyDaemonInfo =
    DaemonInfo
        { targets = []
        , watchDirs = []
        , sockPath = ""
        , logFile = ""
        , metricsPort = Nothing
        }
