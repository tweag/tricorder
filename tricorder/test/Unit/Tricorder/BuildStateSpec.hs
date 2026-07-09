module Unit.Tricorder.BuildStateSpec (spec_BuildState) where

import Data.Aeson (eitherDecode, encode)
import Data.Time (UTCTime (..), fromGregorian)
import Test.Hspec

import Data.Map.Strict qualified as Map

import Tricorder.BuildState
    ( BuildId (..)
    , BuildOutput (..)
    , BuildRecord (..)
    , BuildResult (..)
    , BuildState (..)
    , CyclePhase (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , Severity (..)
    , Status (..)
    , TestOutput (..)
    , currentId
    , liveSnapshot
    , suitesOf
    )
import Tricorder.Session (getTestTargets, parseTestTargets)

import Tricorder.BuildState.Test qualified as Test


spec_BuildState :: Spec
spec_BuildState = do
    describe "JSON round-trip" do
        it "survives Unicode smart quotes in message text" do
            let msg =
                    Diagnostic
                        { severity = SWarning
                        , file = "<interactive>"
                        , line = 2
                        , col = 8
                        , endLine = 2
                        , endCol = 8
                        , title = "Found \8216qualified\8217 in prepositive position"
                        , text = "Found \8216qualified\8217 in prepositive position\n    Suggested fixes:\n      \8226 Place \8216qualified\8217 after the module name."
                        }
                bs = mkBuildState [msg]
            eitherDecode (encode bs) `shouldBe` Right bs

        it "survives control characters in message text" do
            let msg =
                    Diagnostic
                        { severity = SWarning
                        , file = "<interactive>"
                        , line = 1
                        , col = 1
                        , endLine = 1
                        , endCol = 1
                        , title = "text with \CAN control \EM chars and \ESC[1m ANSI \ESC[0m codes"
                        , text = "text with \CAN control \EM chars and \ESC[1m ANSI \ESC[0m codes"
                        }
                bs = mkBuildState [msg]
            eitherDecode (encode bs) `shouldBe` Right bs

        it "survives curly double quotes in message text" do
            let msg =
                    Diagnostic
                        { severity = SWarning
                        , file = "<interactive>"
                        , line = 1
                        , col = 1
                        , endLine = 1
                        , endCol = 1
                        , title = "\8220Place qualified after the module name.\8221"
                        , text = "\8220Place qualified after the module name.\8221"
                        }
                bs = mkBuildState [msg]
            eitherDecode (encode bs) `shouldBe` Right bs

        -- Guards the wire format for the BuildFailed cycle arm: the captured
        -- cabal/build error (multi-line, Unicode) must round-trip intact so
        -- the CLI/UI clients can render it.
        it "survives a BuildFailed cycle with a multi-line message" do
            let bs =
                    mkBuildState [] :: BuildState
                failed =
                    bs
                        { cycle =
                            BuildFailed
                                "cabal: Could not resolve dependencies:\n[__0] trying: \8216base\8217\nrejecting: ..."
                        }
            eitherDecode (encode failed) `shouldBe` Right failed

        -- Guards the buildId-keyed history: the Map BuildId BuildRecord must
        -- round-trip, i.e. the BuildId newtype's ToJSONKey/FromJSONKey work.
        it "survives a multi-build history (K=2)" do
            let bs = mkBuildState []
                twoBuilds =
                    bs
                        { history =
                            Map.fromList
                                [ (BuildId 2, BuildRecord (Built (mkResult [])) (TestsDone (Test.Suites mempty)))
                                , (BuildId 3, BuildRecord (Built (mkResult [])) TestsIdle)
                                ]
                        }
            eitherDecode (encode twoBuilds) `shouldBe` Right twoBuilds

        -- The wire envelope: daemon config joined onto the reduced state at the
        -- edge. Guards that the whole Status DTO round-trips.
        it "survives a full Status envelope" do
            let st = Status {daemon = emptyDaemonInfo, build = mkBuildState []}
            eitherDecode (encode st) `shouldBe` Right st

    -- The single suites extractor shared by every reader (CLI, TUI). Adding a
    -- new 'TestOutput' constructor forces a change here rather than silently
    -- returning 'mempty' in one copy.
    describe "suitesOf" do
        it "unwraps a running register" do
            suitesOf (TestsRunning sampleSuites) `shouldBe` sampleSuites
        it "unwraps a done register" do
            suitesOf (TestsDone sampleSuites) `shouldBe` sampleSuites
        it "is empty for the idle register" do
            suitesOf TestsIdle `shouldBe` Test.Suites mempty

    -- The projection streamed on each live 'watchStream' transition: a live
    -- (non-terminal) cycle renders only the current record, so the retained
    -- previous build's diagnostics must not be re-encoded on every progress
    -- line. Terminal frames keep the full history.
    describe "liveSnapshot" do
        it "trims retained history to the current record while Building" do
            let s = twoBuildHistory (Building Nothing)
            Map.keys (liveSnapshot s).history `shouldBe` [currentId s]

        it "trims retained history to the current record while Analysing" do
            let s = twoBuildHistory Analysing
            Map.keys (liveSnapshot s).history `shouldBe` [currentId s]

        it "keeps the full history once terminal (Idle)" do
            let s = twoBuildHistory Idle
            liveSnapshot s `shouldBe` s

        it "keeps the full history on BuildFailed" do
            let s = twoBuildHistory (BuildFailed "boom")
            liveSnapshot s `shouldBe` s


-- | A state whose history retains two builds (a previous build carrying
-- diagnostics, plus the current one), under the given cycle phase.
twoBuildHistory :: CyclePhase -> BuildState
twoBuildHistory phase =
    BuildState
        { cycle = phase
        , history =
            Map.fromList
                [ (BuildId 1, BuildRecord (Built (mkResult [warnMsg])) (TestsDone (Test.Suites mempty)))
                , (BuildId 2, BuildRecord NotBuilt TestsIdle)
                ]
        }
  where
    warnMsg =
        Diagnostic
            { severity = SWarning
            , file = "src/Foo.hs"
            , line = 1
            , col = 1
            , endLine = 1
            , endCol = 1
            , title = "redundant import"
            , text = "redundant import"
            }


sampleSuites :: Test.Suites
sampleSuites = Test.Suites $ Map.fromList [(tgt, Test.SuiteRunning Nothing)]
  where
    tgt = case (parseTestTargets ["test:foo"]).getTestTargets of
        (t : _) -> t
        [] -> error "sampleSuites: no test target parsed"


mkResult :: [Diagnostic] -> BuildResult
mkResult msgs =
    BuildResult
        { completedAt = epoch
        , duration = 0
        , moduleCount = 0
        , diagnostics = msgs
        }


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0


emptyDaemonInfo :: DaemonInfo
emptyDaemonInfo =
    DaemonInfo
        { targets = []
        , watchDirs = []
        , sockPath = ""
        , logFile = ""
        , metricsPort = Nothing
        }


mkBuildState :: [Diagnostic] -> BuildState
mkBuildState msgs =
    BuildState
        { cycle = Idle
        , history =
            Map.singleton (BuildId 1)
                $ BuildRecord (Built (mkResult msgs))
                $ TestsDone
                $ Test.Suites mempty
        }
