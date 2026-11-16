module Unit.Tricorder.Daemon.BuilderSpec (test_Builder) where

import Data.Time (UTCTime (..), addUTCTime, fromGregorian)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.FileSystem.Path qualified as Path
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Tricorder.Build (BuildResult (..), Diagnostic (..))
import Tricorder.Build.DiagnosticLocation (DiagnosticLocation (..))
import Tricorder.Build.Duration (Duration (..))
import Tricorder.Daemon.Builder (NewLoadResult (..), compileBuildResults)
import Tricorder.Daemon.Ghci.LoadResult (LoadResult (..))
import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.WatchDirs (WatchDirs (..))

import Tricorder.Build.Severity qualified as Severity


test_Builder :: TestTree
test_Builder =
    testGroup
        "Builder"
        [ testGroup "compileBuildResults" testCompileBuildResults
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
                                , compiledFiles = Set.singleton errPath
                                , loadedModules = Map.empty
                                , targetNames = []
                                , diagnostics = []
                                }
                        }
        r.duration @?= Duration 10_000
    , testCase "merges with existing results" do
        let oldWarn = errMsg {severity = Severity.Warning}
        let (m, _) =
                compileBuildResults root watchDirs (Map.fromList [(errMsg.file, [oldWarn])])
                    $ NewLoadResult
                        { startTime = epoch
                        , endTime = epoch
                        , loadResult =
                            LoadResult
                                { moduleCount = 2
                                , compiledFiles = Set.singleton warnPath
                                , loadedModules = Map.empty
                                , targetNames = []
                                , diagnostics = [warnMsg]
                                }
                        }
        m
            @?= fromList
                [ (warnMsg.file, [warnMsg])
                , (errMsg.file, [oldWarn])
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
                                , compiledFiles = Set.singleton warnPath
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
    root = ProjectRoot (Path.absolute @"/")
    watchDirs = WatchDirs [Path.absolute @"/src"]


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

errPath :: Path.Any
errPath = Path.Relative (Path.rel @"./src/Foo.hs")


warnPath :: Path.Any
warnPath = Path.Relative (Path.rel @"./src/Bar.hs")


errMsg :: Diagnostic
errMsg =
    Diagnostic
        { severity = Severity.Error
        , file = Location errPath
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
        { severity = Severity.Warning
        , file = Location warnPath
        , line = 10
        , col = 3
        , endLine = 10
        , endCol = 8
        , title = "Unused import"
        , text = "Unused import"
        }


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0
