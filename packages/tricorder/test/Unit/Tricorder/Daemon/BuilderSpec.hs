module Unit.Tricorder.Daemon.BuilderSpec (test_Builder) where

import Data.Time (UTCTime (..), addUTCTime, fromGregorian)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Tricorder.Build (BuildResult (..), Diagnostic (..), Severity (..))
import Tricorder.Build.Duration (Duration (..))
import Tricorder.Daemon.Builder (NewLoadResult (..), compileBuildResults)
import Tricorder.Daemon.GhciSession.GhciParser
    ( LoadResult (..)
    , LoadedModule (..)
    , extractTitle
    , resolveKnownTargets
    )
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.WatchDirs (WatchDirs (..))


test_Builder :: TestTree
test_Builder =
    testGroup
        "Builder"
        [ testGroup "extractTitle" testExtractTitle
        , testGroup "compileBuildResults" testCompileBuildResults
        , testGroup "resolveKnownTargets" testResolveKnownTargets
        ]


data StopSignal = StopSignal
    deriving stock (Show)


testCompileBuildResults :: [TestTree]
testCompileBuildResults =
    [ testCase "uses NewLoadResult's times to calculate duration" do
        let (_, r) =
                compileBuildResults
                    root
                    watchDirs
                    mempty
                    NewLoadResult
                        { startTime = addUTCTime 10 epoch
                        , endTime = addUTCTime 20 epoch
                        , loadResult =
                            LoadResult
                                { moduleCount = 2
                                , compiledFiles = Set.singleton errMsg.file
                                , loadedModules = Map.empty
                                , targetNames = []
                                , diagnostics = []
                                }
                        }
        r.duration @?= Duration 10_000
    , testCase "merges with existing results" do
        let (m, _) =
                compileBuildResults root watchDirs (Map.fromList [(errMsg.file, [errMsg])])
                    $ NewLoadResult
                        { startTime = epoch
                        , endTime = epoch
                        , loadResult =
                            LoadResult
                                { moduleCount = 2
                                , compiledFiles = Set.singleton warnMsg.file
                                , loadedModules = Map.empty
                                , targetNames = []
                                , diagnostics = [warnMsg]
                                }
                        }
        m
            @?= fromList
                [ (warnMsg.file, [warnMsg])
                , (errMsg.file, [errMsg])
                ]
    , testCase "returns a BuildResult" do
        let (_, r) =
                compileBuildResults root watchDirs mempty
                    $ NewLoadResult
                        { startTime = epoch
                        , endTime = addUTCTime 10 epoch
                        , loadResult =
                            LoadResult
                                { moduleCount = 2
                                , compiledFiles = Set.singleton warnMsg.file
                                , loadedModules = Map.empty
                                , targetNames = []
                                , diagnostics = [warnMsg]
                                }
                        }
            expected =
                BuildResult
                    { completedAt = addUTCTime 10 epoch
                    , duration = Duration 10_000
                    , moduleCount = 2
                    , diagnostics = [warnMsg]
                    }
        r @?= expected
    ]
  where
    root = ProjectRoot "/"
    watchDirs = WatchDirs ["/src"]


--------------------------------------------------------------------------------
-- resolveKnownTargets tests
--------------------------------------------------------------------------------

testResolveKnownTargets :: [TestTree]
testResolveKnownTargets =
    [ testCase "uses :show modules as the primary source for path↔name mapping" do
        let result =
                emptyLr
                    { loadedModules =
                        Map.fromList
                            [
                                ( "/abs/src/Foo.hs"
                                , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                                )
                            ]
                    , targetNames = ["Foo"]
                    }
        resolveKnownTargets Map.empty result
            @?= Map.fromList
                [
                    ( "/abs/src/Foo.hs"
                    , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                    )
                ]
    , -- Regression test for the stale-results bug. After a failed compile, the
      -- module disappears from :show modules but stays in :show targets. The
      -- prior state's entry must be carried over so the dispatcher continues to
      -- see the file as "known" and issues :reload (not :add) when the user
      -- fixes the error.
      testCase "carries over prior state for targets that are no longer in :show modules" do
        let prev =
                Map.fromList
                    [
                        ( "/abs/src/Foo.hs"
                        , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                        )
                    ]
            result =
                emptyLr
                    { loadedModules = Map.empty -- Foo failed to compile
                    , targetNames = ["Foo"] -- but is still a target
                    }
        resolveKnownTargets prev result @?= prev
    , testCase "drops targets that are no longer in :show targets" do
        let prev =
                Map.fromList
                    [
                        ( "/abs/src/Foo.hs"
                        , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                        )
                    ]
            result = emptyLr {loadedModules = Map.empty, targetNames = []}
        resolveKnownTargets prev result @?= Map.empty
    , -- Dropped from the path-keyed map because we have no path↔name entry;
      -- the dispatcher still handles them via 'KnownTargetNames'.
      testCase "drops targets that have neither a current :show modules entry nor prior state" do
        let result = emptyLr {loadedModules = Map.empty, targetNames = ["BrandNew"]}
        resolveKnownTargets Map.empty result @?= Map.empty
    ]
  where
    emptyLr =
        LoadResult
            { moduleCount = 0
            , compiledFiles = Set.empty
            , loadedModules = Map.empty
            , targetNames = []
            , diagnostics = []
            }


--------------------------------------------------------------------------------
-- extractTitle tests
--------------------------------------------------------------------------------

testExtractTitle :: [TestTree]
testExtractTitle =
    [ testCase "returns empty string for empty message" do
        extractTitle [] @?= ""
    , -- New GHC style: header ends with [GHC-XXXXX], content on body lines.
      -- Captured from GHC 9.10.2 with -Weverything.
      testCase "extracts first body line for error with [GHC-XXXXX] code" do
        extractTitle
            [ "src/Tricorder/Config.hs:39:20: error: [GHC-83865]"
            , "    \8226 Couldn't match expected type 'Int' with actual type 'Bool'"
            , "    \8226 In the expression: True"
            , "      In an equation for '_deliberateError': _deliberateError = True"
            , "   |"
            , "39 | _deliberateError = True"
            , "   |                    ^^^^"
            ]
            @?= "\8226 Couldn't match expected type 'Int' with actual type 'Bool'"
    , testCase "extracts first body line for warning with [GHC-XXXXX] [-Wfoo] codes" do
        extractTitle
            [ "src/Tricorder/Config.hs:38:26: warning: [GHC-55631] [-Wmissing-deriving-strategies]"
            , "    No deriving strategy specified. Did you want stock, newtype, or anyclass?"
            , "   |"
            , "38 | data TestWarn = TestWarn deriving (Eq)"
            , "   |                          ^^^^^^^^^^^^^"
            ]
            @?= "No deriving strategy specified. Did you want stock, newtype, or anyclass?"
    , -- Old GHC style: message text is inline on the header line.
      testCase "extracts inline content for old-style single-line error" do
        extractTitle ["GHCi.hs:70:1: error: Parse error: naked expression at top level"]
            @?= "Parse error: naked expression at top level"
    , testCase "extracts inline content for old-style Warning (capital W)" do
        extractTitle ["GHCi.hs:81:1: Warning: Defined but not used: \8216foo\8217"]
            @?= "Defined but not used: \8216foo\8217"
    , -- Multi-line without any inline message: position-only or "Warning:" header.
      testCase "extracts first body line when header has position only" do
        extractTitle
            [ "GHCi.hs:72:13:"
            , "    No instance for (Num ([String] -> [String]))"
            , "      arising from the literal '1'"
            ]
            @?= "No instance for (Num ([String] -> [String]))"
    , testCase "extracts first body line when header ends with 'Warning:'" do
        extractTitle
            [ "/src/TrieSpec.hs:(192,7)-(193,76): Warning:"
            , "    A do-notation statement discarded a result of type '[()]'"
            ]
            @?= "A do-notation statement discarded a result of type '[()]'"
    , -- Source display lines (pipe/caret) must be skipped.
      testCase "skips source display lines when scanning body" do
        extractTitle
            [ "file.hs:1:1: error: [GHC-12345]"
            , "   |"
            , "1 | foo bar"
            , "   |     ^^^"
            , "    actual content here"
            ]
            @?= "actual content here"
    , -- ANSI-escaped header (colour output): strip escapes before searching.
      testCase "handles ANSI-escaped headers" do
        extractTitle
            [ "\ESC[;1msrc/Types.hs:11:1: \ESC[35mwarning:\ESC[0m \ESC[35m[-Wunused-imports]\ESC[0m"
            , "    The import of 'Data.Data' is redundant"
            ]
            @?= "The import of 'Data.Data' is redundant"
    ]


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

errMsg :: Diagnostic
errMsg =
    Diagnostic
        { severity = SError
        , file = "./src/Foo.hs"
        , line = 1
        , col = 1
        , endLine = 1
        , endCol = 5
        , title = "Variable not in scope: foo"
        , text = "Variable not in scope: foo"
        }


warnMsg :: Diagnostic
warnMsg =
    Diagnostic
        { severity = SWarning
        , file = "./src/Bar.hs"
        , line = 10
        , col = 3
        , endLine = 10
        , endCol = 8
        , title = "Unused import"
        , text = "Unused import"
        }


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0
