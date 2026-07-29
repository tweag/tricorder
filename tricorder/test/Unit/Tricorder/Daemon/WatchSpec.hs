module Unit.Tricorder.Daemon.WatchSpec (spec_Watch) where

import Atelier.Effects.FileWatcher (FileEvent (..), matchesAny)
import Effectful (runEff)
import Effectful.Writer.Static.Shared (execWriter, runWriter)
import Test.Hspec (Spec, describe, it, shouldBe, shouldMatchList)
import Text.Regex.TDFA.ReadRegex (parseRegex)

import Atelier.Effects.Publishing.Pub qualified as Pub

import Tricorder.BuildState
    ( CabalChangeDetected (..)
    , SourceChangeDetected (..)
    )
import Tricorder.Daemon.Watch (WatchedFile (..))
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (WatchDirs (..), WatchExclusionPatterns (..))

import Tricorder.Daemon.Watch qualified as Watch


spec_Watch :: Spec
spec_Watch = do
    describe "publishChange" testPublishChange
    describe "specs" testSpecs


testPublishChange :: Spec
testPublishChange = do
    describe "with non-cabal file change" $ it "should publish SourceChangeDetected" do
        (_, sourceChanges) <- runTest "foo"
        sourceChanges `shouldMatchList` [SourceChangeDetected "foo" Modified]

    describe "with cabal file change" $ it "should publish CabalChangeDetected" do
        (cabalChanges, _) <- runTest "foo.cabal"
        cabalChanges `shouldMatchList` [CabalChangeDetected "foo.cabal" Modified]
  where
    runTest =
        runEff
            . runWriter
            . Pub.toWriter @SourceChangeDetected
            . execWriter
            . Pub.toWriter @CabalChangeDetected
            . Watch.publishChange
            . (`WatchedFile` Modified)


testSpecs :: Spec
testSpecs = do
    describe "source watches" do
        it "matches .hs files in configured watch dirs" do
            let watches =
                    Watch.specs
                        (ProjectRoot "/proj")
                        (WatchExclusionPatterns [])
                        (WatchDirs ["/proj/src"])
            matchesAny watches "/proj/src/Foo.hs" `shouldBe` True

        it "does not match non-.hs files" do
            let watches =
                    Watch.specs
                        (ProjectRoot "/proj")
                        (WatchExclusionPatterns [])
                        (WatchDirs ["/proj/src"])
            matchesAny watches "/proj/src/Foo.txt" `shouldBe` False

        it "excludes paths containing dist-newstyle" do
            let watches =
                    Watch.specs
                        (ProjectRoot "/proj")
                        (WatchExclusionPatterns [])
                        (WatchDirs ["/proj/src"])
            matchesAny watches "/proj/src/dist-newstyle/Foo.hs" `shouldBe` False

        it "excludes paths matching an exclusion pattern" do
            let pat = parsePattern "vendor"
                watches =
                    Watch.specs
                        (ProjectRoot "/proj")
                        (WatchExclusionPatterns [pat])
                        (WatchDirs ["/proj/src"])
            matchesAny watches "/proj/src/vendor/Foo.hs" `shouldBe` False
            matchesAny watches "/proj/src/Foo.hs" `shouldBe` True

        it "matches .hs files across multiple watch dirs" do
            let watches =
                    Watch.specs
                        (ProjectRoot "/proj")
                        (WatchExclusionPatterns [])
                        (WatchDirs ["/proj/src", "/proj/test"])
            matchesAny watches "/proj/src/Foo.hs" `shouldBe` True
            matchesAny watches "/proj/test/FooSpec.hs" `shouldBe` True

        -- Second line of defense: 'cabalWatches' registers the whole project
        -- root, and 'deduplicateDirs' collapses the narrow source dirs into it,
        -- so the OS watches the entire repo recursively. 'matchesAny' is what
        -- re-scopes events back to the configured dirs — a .hs file in a sibling
        -- package must not match.
        it "does not match a .hs file in a sibling package outside the watch dirs" do
            let watches =
                    Watch.specs
                        (ProjectRoot "/proj")
                        (WatchExclusionPatterns [])
                        (WatchDirs ["/proj/pkg-a/src"])
            matchesAny watches "/proj/pkg-a/src/Foo.hs" `shouldBe` True
            matchesAny watches "/proj/pkg-b/src/Foo.hs" `shouldBe` False

    describe "cabal watches" do
        it "matches .cabal files under project root" do
            let watches =
                    Watch.specs
                        (ProjectRoot "/proj")
                        (WatchExclusionPatterns [])
                        (WatchDirs [])
            matchesAny watches "/proj/foo.cabal" `shouldBe` True

        it "matches cabal.project under project root" do
            let watches =
                    Watch.specs
                        (ProjectRoot "/proj")
                        (WatchExclusionPatterns [])
                        (WatchDirs [])
            matchesAny watches "/proj/cabal.project" `shouldBe` True

        it "matches package.yaml under project root" do
            let watches =
                    Watch.specs
                        (ProjectRoot "/proj")
                        (WatchExclusionPatterns [])
                        (WatchDirs [])
            matchesAny watches "/proj/package.yaml" `shouldBe` True

        it "does not match non-cabal files" do
            let watches =
                    Watch.specs
                        (ProjectRoot "/proj")
                        (WatchExclusionPatterns [])
                        (WatchDirs [])
            matchesAny watches "/proj/README.md" `shouldBe` False

        it "excludes cabal files under dist-newstyle" do
            let watches =
                    Watch.specs
                        (ProjectRoot "/proj")
                        (WatchExclusionPatterns [])
                        (WatchDirs [])
            matchesAny watches "/proj/dist-newstyle/foo.cabal" `shouldBe` False
  where
    parsePattern p = fromRight (error . toText $ "bad test pattern: " <> p) (parseRegex p)
