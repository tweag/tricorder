module Unit.Tricorder.Daemon.BuilderSpec (test_Builder) where

import Data.Time (UTCTime (..), addUTCTime, fromGregorian)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Tricorder.Build (BuildResult (..), Diagnostic (..), Severity (..))
import Tricorder.Build.Duration (Duration (..))
import Tricorder.Daemon.Builder (NewLoadResult (..), compileBuildResults)
import Tricorder.Daemon.Ghci.LoadResult (LoadResult (..))
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.WatchDirs (WatchDirs (..))


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
