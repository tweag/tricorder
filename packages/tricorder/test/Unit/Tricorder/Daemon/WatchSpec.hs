module Unit.Tricorder.Daemon.WatchSpec (test_Watch) where

import Atelier.Effects.FileWatcher (matchesAny)
import Atelier.Effects.FileWatcher.Event (Event (..))
import Effectful (runEff)
import Effectful.Writer.Static.Shared (execWriter, runWriter)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))
import Text.Regex.TDFA.ReadRegex (parseRegex)

import Atelier.Effects.PubSub.Pub qualified as Pub
import Atelier.FileSystem.Path qualified as Path

import Tricorder.Build.Changes (ProjectChangeDetected (..), SourceChangeDetected (..))
import Tricorder.Daemon.Watch (WatchedFile (..))
import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.WatchDirs (WatchDirs (..))
import Tricorder.Session.WatchExclusionPatterns (Pattern (..), WatchExclusionPatterns (..))

import Tricorder.Daemon.Watch qualified as Watch


test_Watch :: TestTree
test_Watch =
    testGroup
        "Watch"
        [ testGroup "publishChange" testPublishChange
        , testGroup "specs" testSpecs
        ]


testPublishChange :: [TestTree]
testPublishChange =
    [ testGroup
        "with non-cabal file change"
        [ testCase "should publish SourceChangeDetected" do
            (_, sourceChanges) <- runTest (Path.Relative $ Path.rel @"foo")
            sourceChanges @?= [SourceChangeDetected (Path.Relative $ Path.rel @"foo") Modified]
        ]
    , testGroup
        "with cabal file change"
        [ testCase "should publish CabalChangeDetected" do
            (cabalChanges, _) <- runTest $ Path.Relative $ Path.rel @"foo.cabal"
            cabalChanges @?= [ProjectChangeDetected (Path.Relative $ Path.rel @"foo.cabal") Modified]
        ]
    ]
  where
    runTest =
        runEff
            . runWriter
            . Pub.toWriter @SourceChangeDetected
            . execWriter
            . Pub.toWriter @ProjectChangeDetected
            . Watch.publishChange
            . (`WatchedFile` Modified)


testSpecs :: [TestTree]
testSpecs =
    [ testGroup
        "source watches"
        [ testCase "matches .hs files in configured watch dirs" do
            let watches =
                    Watch.specs
                        (ProjectRoot (Path.absolute @"/proj"))
                        (WatchExclusionPatterns [])
                        (WatchDirs [Path.absolute @"/proj/src"])
            matchesAny watches (Path.absolute @"/proj/src/Foo.hs") @?= True
        , testCase "does not match non-.hs files" do
            let watches =
                    Watch.specs
                        (ProjectRoot (Path.absolute @"/proj"))
                        (WatchExclusionPatterns [])
                        (WatchDirs [Path.absolute @"/proj/src"])
            matchesAny watches (Path.absolute @"/proj/src/Foo.txt") @?= False
        , testCase "excludes paths containing dist-newstyle" do
            let watches =
                    Watch.specs
                        (ProjectRoot (Path.absolute @"/proj"))
                        (WatchExclusionPatterns [])
                        (WatchDirs [Path.absolute @"/proj/src"])
            matchesAny watches (Path.absolute @"/proj/src/dist-newstyle/Foo.hs") @?= False
        , testCase "excludes paths matching an exclusion pattern" do
            let pat = parsePattern "vendor"
                watches =
                    Watch.specs
                        (ProjectRoot (Path.absolute @"/proj"))
                        (WatchExclusionPatterns [pat])
                        (WatchDirs [Path.absolute @"/proj/src"])
            matchesAny watches (Path.absolute @"/proj/src/vendor/Foo.hs") @?= False
            matchesAny watches (Path.absolute @"/proj/src/Foo.hs") @?= True
        , testCase "matches .hs files across multiple watch dirs" do
            let watches =
                    Watch.specs
                        (ProjectRoot (Path.absolute @"/proj"))
                        (WatchExclusionPatterns [])
                        (WatchDirs [Path.absolute @"/proj/src", Path.absolute @"/proj/test"])
            matchesAny watches (Path.absolute @"/proj/src/Foo.hs") @?= True
            matchesAny watches (Path.absolute @"/proj/test/FooSpec.hs") @?= True
        , -- Second line of defense: 'cabalWatches' registers the whole project
          -- root, and 'deduplicateDirs' collapses the narrow source dirs into it,
          -- so the OS watches the entire repo recursively. 'matchesAny' is what
          -- re-scopes events back to the configured dirs — a .hs file in a sibling
          -- package must not match.
          testCase "does not match a .hs file in a sibling package outside the watch dirs" do
            let watches =
                    Watch.specs
                        (ProjectRoot (Path.absolute @"/proj"))
                        (WatchExclusionPatterns [])
                        (WatchDirs [Path.absolute @"/proj/pkg-a/src"])
            matchesAny watches (Path.absolute @"/proj/pkg-a/src/Foo.hs") @?= True
            matchesAny watches (Path.absolute @"/proj/pkg-b/src/Foo.hs") @?= False
        ]
    , testGroup
        "cabal watches"
        [ testCase "matches .cabal files under project root" do
            let watches =
                    Watch.specs
                        (ProjectRoot (Path.absolute @"/proj"))
                        (WatchExclusionPatterns [])
                        (WatchDirs [])
            matchesAny watches (Path.absolute @"/proj/foo.cabal") @?= True
        , testCase "matches cabal.project under project root" do
            let watches =
                    Watch.specs
                        (ProjectRoot (Path.absolute @"/proj"))
                        (WatchExclusionPatterns [])
                        (WatchDirs [])
            matchesAny watches (Path.absolute @"/proj/cabal.project") @?= True
        , testCase "does not match package.yaml (its .cabal file is watched instead)" do
            let watches =
                    Watch.specs
                        (ProjectRoot (Path.absolute @"/proj"))
                        (WatchExclusionPatterns [])
                        (WatchDirs [])
            matchesAny watches (Path.absolute @"/proj/package.yaml") @?= False
        , testCase "does not match non-cabal files" do
            let watches =
                    Watch.specs
                        (ProjectRoot (Path.absolute @"/proj"))
                        (WatchExclusionPatterns [])
                        (WatchDirs [])
            matchesAny watches (Path.absolute @"/proj/README.md") @?= False
        , testCase "excludes cabal files under dist-newstyle" do
            let watches =
                    Watch.specs
                        (ProjectRoot (Path.absolute @"/proj"))
                        (WatchExclusionPatterns [])
                        (WatchDirs [])
            matchesAny watches (Path.absolute @"/proj/dist-newstyle/foo.cabal") @?= False
        ]
    ]
  where
    parsePattern p = Pattern $ fromRight (error . toText $ "bad test pattern: " <> p) (parseRegex p)
