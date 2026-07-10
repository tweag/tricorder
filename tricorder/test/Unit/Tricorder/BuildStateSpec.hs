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
    , currentId
    , liveSnapshot
    )
import Tricorder.BuildState.BuildProgress (BuildProgress (..))
import Tricorder.Session (TestTarget, getTestTargets, parseTestTargets)

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
                                [ (BuildId 2, BuildRecord (Built (mkResult [])) sampleSuites)
                                , (BuildId 3, BuildRecord (Built (mkResult [])) (Test.Suites mempty))
                                ]
                        }
            eitherDecode (encode twoBuilds) `shouldBe` Right twoBuilds

        -- The wire envelope: daemon config joined onto the reduced state at the
        -- edge. Guards that the whole Status DTO round-trips.
        it "survives a full Status envelope" do
            let st = Status {daemon = emptyDaemonInfo, build = mkBuildState []}
            eitherDecode (encode st) `shouldBe` Right st

    -- The per-suite merge is where monotonicity lives: a suite advances
    -- SuiteRunning -> terminal and a terminal never regresses to running; the
    -- newest terminal (and newest running tick) wins. 'Suites' inherits this via
    -- MonoidalMap's unionWith.
    describe "Semigroup Suite" do
        it "is associative over the representative suite states" do
            sequence_
                [ ((a <> b) <> c) `shouldBe` (a <> (b <> c))
                | a <- suiteReps
                , b <- suiteReps
                , c <- suiteReps
                ]

        it "a running suite yields to a terminal (completed / errored)" do
            (running0 <> completedPass) `shouldBe` completedPass
            (runningTick <> erroredBoom) `shouldBe` erroredBoom

        it "a terminal suite never regresses to running" do
            (completedPass <> running0) `shouldBe` completedPass
            (erroredBoom <> runningTick) `shouldBe` erroredBoom

        it "the newest terminal wins on a terminal/terminal merge" do
            (completedPass <> completedFail) `shouldBe` completedFail
            (completedFail <> completedPass) `shouldBe` completedPass

        it "keeps the latest running progress tick" do
            (running0 <> runningTick) `shouldBe` runningTick

    describe "Semigroup Suites (per-target monoidal merge)" do
        it "merges per target: seed running, then a terminal delta advances one suite" do
            let seeded =
                    Test.suitesFromList
                        [ (fooTarget, Test.SuiteRunning Nothing)
                        , (barTarget, Test.SuiteRunning Nothing)
                        ]
                delta = Test.suitesFromList [(fooTarget, completedPass)]
            Test.suitesToList (seeded <> delta)
                `shouldBe` [ (barTarget, Test.SuiteRunning Nothing)
                           , (fooTarget, completedPass)
                           ]

    -- The running/done phase is a pure derivation of the register, not a stored
    -- tag. The one edge: an empty register is 'NoTests', never 'Tested'.
    describe "testPhase" do
        it "an empty register is NoTests (not Tested)" do
            Test.testPhase (Test.Suites mempty) `shouldBe` Test.NoTests

        it "any running suite is Testing" do
            Test.testPhase
                ( Test.suitesFromList
                    [ (fooTarget, completedPass)
                    , (barTarget, Test.SuiteRunning Nothing)
                    ]
                )
                `shouldBe` Test.Testing

        it "all-terminal suites are Tested" do
            Test.testPhase
                ( Test.suitesFromList
                    [ (fooTarget, completedPass)
                    , (barTarget, erroredBoom)
                    ]
                )
                `shouldBe` Test.Tested

        it "phase advances monotonically Testing -> Tested as terminal deltas land" do
            let seeded =
                    Test.suitesFromList
                        [ (fooTarget, Test.SuiteRunning Nothing)
                        , (barTarget, Test.SuiteRunning Nothing)
                        ]
                afterFoo = seeded <> Test.suitesFromList [(fooTarget, completedPass)]
                afterBar = afterFoo <> Test.suitesFromList [(barTarget, completedFail)]
            Test.testPhase seeded `shouldBe` Test.Testing
            -- One suite done, one still running: still Testing.
            Test.testPhase afterFoo `shouldBe` Test.Testing
            -- Both terminal: Tested.
            Test.testPhase afterBar `shouldBe` Test.Tested
            -- A late running tick for a finished suite cannot pull it back.
            Test.testPhase (afterBar <> Test.suitesFromList [(fooTarget, runningTick)])
                `shouldBe` Test.Tested

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
                [ (BuildId 1, BuildRecord (Built (mkResult [warnMsg])) (Test.Suites mempty))
                , (BuildId 2, BuildRecord NotBuilt (Test.Suites mempty))
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
sampleSuites = Test.suitesFromList [(fooTarget, Test.SuiteRunning Nothing)]


--------------------------------------------------------------------------------
-- Suite / Suites semigroup fixtures
--------------------------------------------------------------------------------

fooTarget :: TestTarget
fooTarget = mkTestTarget "test:foo"


barTarget :: TestTarget
barTarget = mkTestTarget "test:bar"


mkTestTarget :: Text -> TestTarget
mkTestTarget name = case (parseTestTargets [name]).getTestTargets of
    (t : _) -> t
    [] -> error "mkTestTarget: no test target parsed"


running0 :: Test.Suite
running0 = Test.SuiteRunning Nothing


runningTick :: Test.Suite
runningTick = Test.SuiteRunning (Just BuildProgress {compiled = 3, total = 10})


completedPass :: Test.Suite
completedPass =
    Test.SuiteCompleted
        Test.SuiteCompletion {passed = True, output = "ok", testCases = [], duration = Nothing}


completedFail :: Test.Suite
completedFail =
    Test.SuiteCompleted
        Test.SuiteCompletion {passed = False, output = "boom", testCases = [], duration = Nothing}


erroredBoom :: Test.Suite
erroredBoom = Test.SuiteErrored Test.SuiteError {message = "crashed"}


-- | Representative suite states covering every 'Semigroup' 'Suite' clause.
suiteReps :: [Test.Suite]
suiteReps = [running0, runningTick, completedPass, completedFail, erroredBoom]


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
                $ Test.Suites mempty
        }
