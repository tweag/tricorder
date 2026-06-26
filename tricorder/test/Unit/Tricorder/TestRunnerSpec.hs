module Unit.Tricorder.TestRunnerSpec (spec_TestRunner) where

import Atelier.Effects.Clock (runClockConst)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.Input (runInputConst)
import Atelier.Effects.Log (runLogNoOp)
import Control.Concurrent.STM (newTVarIO, writeTVar)
import Control.Exception (ErrorCall (..))
import Data.Time (UTCTime (..), fromGregorian)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Concurrent.STM (atomically)
import Effectful.Exception (try)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState)
import Test.Hspec

import Data.Map.Strict qualified as Map

import Tricorder.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , PostBuild (..)
    )
import Tricorder.BuildState.BuildProgress (BuildProgress (..))
import Tricorder.Effects.BuildStore (getState)
import Tricorder.Effects.GhciSession.GhciParser (GhciLoading (..))
import Tricorder.Effects.TestRunner
    ( GhciOutcome (..)
    , TestRunner
    , abortGatedProgress
    , detectOutcome
    , interruptCurrent
    , isAborted
    , resetAbort
    , runTestRunnerScripted
    , runTestSuite
    )
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Target (..), TestTarget (..))

import Tricorder.BuildState.Test qualified as Test
import Tricorder.Effects.BuildStore qualified as BuildStore


spec_TestRunner :: Spec
spec_TestRunner = do
    describe "detectOutcome" testDetectOutcome
    describe "runTestRunnerScripted" testScripted
    describe "abortGatedProgress" testAbortGatedProgress


--------------------------------------------------------------------------------
-- detectOutcome tests
--------------------------------------------------------------------------------

testDetectOutcome :: Spec
testDetectOutcome = do
    describe "no exception line" do
        it "treats empty output as pass" do
            detectOutcome "" `shouldBe` GhciPassed

        it "treats output with no exception as pass" do
            detectOutcome "2 examples, 0 failures\n" `shouldBe` GhciPassed

        it "does not match 'ExitSuccess' without the exception prefix" do
            detectOutcome "ExitSuccess\n" `shouldBe` GhciPassed

    describe "ExitSuccess" do
        it "detects ExitSuccess as pass" do
            detectOutcome "*** Exception: ExitSuccess\n" `shouldBe` GhciPassed

        it "detects ExitSuccess anywhere in output" do
            detectOutcome "All tests passed\n*** Exception: ExitSuccess\n"
                `shouldBe` GhciPassed

    describe "ExitFailure" do
        it "detects ExitFailure 1 as fail" do
            detectOutcome "1 failure\n*** Exception: ExitFailure 1\n"
                `shouldBe` GhciFailed

        it "detects ExitFailure with any exit code as fail" do
            detectOutcome "*** Exception: ExitFailure 42\n" `shouldBe` GhciFailed

        it "detects ExitFailure anywhere in output" do
            detectOutcome "Some output\n*** Exception: ExitFailure 1\nMore output\n"
                `shouldBe` GhciFailed

    describe "other exception" do
        it "classifies unknown exception as error with message" do
            detectOutcome "*** Exception: SomeException \"oops\"\n"
                `shouldBe` GhciCrashed "SomeException \"oops\""

        it "trims trailing whitespace from the error message" do
            detectOutcome "*** Exception: Crashed  \n"
                `shouldBe` GhciCrashed "Crashed"

    describe "compile failure (no exception line, but GHC errors present)" do
        it "flags ':main not in scope' as crashed" do
            detectOutcome "<interactive>:1:1: error: [GHC-76037] Not in scope: 'main'\n"
                `shouldBe` GhciCrashed
                    "<interactive>:1:1: error: [GHC-76037] Not in scope: 'main'"

        it "flags a source-file compile error as crashed" do
            detectOutcome "src/Foo.hs:42:5: error: Variable not in scope: foo\n"
                `shouldBe` GhciCrashed "src/Foo.hs:42:5: error: Variable not in scope: foo"

        it "reports the first error line when multiple are present" do
            detectOutcome
                "src/Foo.hs:42:5: error: Variable not in scope: foo\nsrc/Bar.hs:10:1: error: Parse error\n"
                `shouldBe` GhciCrashed "src/Foo.hs:42:5: error: Variable not in scope: foo"

        it "prefers exit exception over compile-error heuristic when both appear" do
            -- A real failing run could plausibly mention 'error:' in its
            -- captured output (e.g. logged messages); the ExitFailure line
            -- still wins.
            detectOutcome "log: error: something happened\n*** Exception: ExitFailure 1\n"
                `shouldBe` GhciFailed


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    it "returns scripted TestRun" do
        result <- runScripted [Right passingRun] $ runTestSuite $ mkTestTarget "test:foo"
        result `shouldBe` passingRun

    it "ignores the target name argument" do
        result <- runScripted [Right failingRun] $ runTestSuite $ mkTestTarget "test:anything"
        result `shouldBe` failingRun

    it "throws when scripted result is Left" do
        result <-
            runScripted [Left (toException boom)]
                $ try @ErrorCall
                $ runTestSuite
                $ mkTestTarget "test:foo"
        result `shouldBe` Left boom

    describe "sequencing" do
        it "consumes results in order across multiple calls" do
            (a, b) <- runScripted [Right passingRun, Right failingRun] do
                a <- runTestSuite $ mkTestTarget "test:foo"
                b <- runTestSuite $ mkTestTarget "test:bar"
                pure (a, b)
            a `shouldBe` passingRun
            b `shouldBe` failingRun

        it "recover scenario: error then success" do
            result <- runScripted [Left (toException boom), Right passingRun] do
                r1 <- try @ErrorCall $ runTestSuite $ mkTestTarget "test:foo"
                r2 <- runTestSuite $ mkTestTarget "test:bar"
                pure (r1, r2)
            fst result `shouldBe` Left boom
            snd result `shouldBe` passingRun

    describe "abort flag" do
        -- The scripted interpreter must mirror 'runTestRunnerIO': any test
        -- that exercises the 'runTestsIfClean' abort short-circuit through
        -- the scripted runner relies on 'isAborted' reflecting prior calls
        -- to 'interruptCurrent'/'resetAbort'. Hard-coding 'pure False' here
        -- silently masks regressions in that flow.
        it "defaults to not aborted" do
            aborted <- runScripted [] isAborted
            aborted `shouldBe` False

        it "interruptCurrent sets the flag" do
            aborted <- runScripted [] do
                interruptCurrent
                isAborted
            aborted `shouldBe` True

        it "resetAbort clears the flag" do
            aborted <- runScripted [] do
                interruptCurrent
                resetAbort
                isAborted
            aborted `shouldBe` False


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

boom :: ErrorCall
boom = ErrorCall "simulated process crash"


passingRun :: Test.Suite
passingRun =
    Test.SuiteCompleted
        $ Test.SuiteCompletion
            { passed = True
            , output = "2 examples, 0 failures\n"
            , testCases = []
            , duration = Nothing
            }


failingRun :: Test.Suite
failingRun =
    Test.SuiteCompleted
        $ Test.SuiteCompletion
            { passed = False
            , output = "1 example, 1 failure\n"
            , testCases = []
            , duration = Nothing
            }


runScripted :: [Either SomeException Test.Suite] -> Eff '[TestRunner, Concurrent, IOE] a -> IO a
runScripted results = runEff . runConcurrent . runTestRunnerScripted results


--------------------------------------------------------------------------------
-- abortGatedProgress tests
--
-- Regression for the "module counter glitches after interrupt" bug: after
-- the test runner sets 'abortedRef' = True and terminates a test process,
-- the dying process can still push pipe-buffered '[N of M] Compiling …'
-- lines through the drain, and each one used to call 'reportTestProgress'
-- and tick the UI counter forward. 'abortGatedProgress' must drop those
-- updates instead.
--------------------------------------------------------------------------------

testAbortGatedProgress :: Spec
testAbortGatedProgress = do
    it "applies the progress update when abortedRef is False" do
        finalRuns <- runProgress False progress42 startingSuites
        Map.toList finalRuns.getSuites
            `shouldMatchList` [(mkTestTarget "test:foo", Test.SuiteRunning (Just expected42))]

    it "drops the progress update when abortedRef is True" do
        finalRuns <- runProgress True progress42 startingSuites
        finalRuns `shouldBe` startingSuites

    it "drops every update applied while abortedRef stays True" do
        abortedRef <- newTVarIO True
        let loadings = [mkLoading i 10 | i <- [1 .. 5]]
        finalRuns <- runStore do
            BuildStore.setPhase (BuildId 1)
                $ BuildComplete result
                $ PostBuild startingSuites mempty

            for_ loadings $ abortGatedProgress abortedRef $ mkTestTarget "test:foo"
            phaseTestSuites <$> getState
        finalRuns `shouldBe` startingSuites

    it "flips behaviour mid-run if abortedRef is set between updates" do
        abortedRef <- newTVarIO False
        finalRuns <- runStore do
            BuildStore.setPhase
                (BuildId 1)
                $ BuildComplete result
                $ PostBuild startingSuites mempty

            -- This one applies.
            abortGatedProgress abortedRef (mkTestTarget "test:foo") (mkLoading 3 10)
            -- Simulate the interrupt firing.
            atomically (writeTVar abortedRef True)
            -- These should now be dropped.
            abortGatedProgress abortedRef (mkTestTarget "test:foo") (mkLoading 8 10)
            abortGatedProgress abortedRef (mkTestTarget "test:foo") (mkLoading 9 10)
            phaseTestSuites <$> getState
        Map.toList finalRuns.getSuites
            `shouldMatchList` [(mkTestTarget "test:foo", Test.SuiteRunning (Just BuildProgress {compiled = 3, total = 10}))]
  where
    startingSuites = Test.Suites $ Map.fromList [(mkTestTarget "test:foo", Test.SuiteRunning Nothing)]
    progress42 = mkLoading 4 10
    expected42 = BuildProgress {compiled = 4, total = 10}

    runProgress aborted loading suites = do
        abortedRef <- newTVarIO aborted
        runStore do
            BuildStore.setPhase (BuildId 1)
                $ BuildComplete result
                $ PostBuild suites mempty
            abortGatedProgress abortedRef (mkTestTarget "test:foo") loading
            phaseTestSuites <$> getState

    runStore =
        runEff
            . runConcurrent
            . runDelay
            . runClockConst epoch
            . runReader (ProjectRoot "/")
            . evalState (BuildId 1)
            . runLogNoOp
            . runInputConst emptyDaemonInfo
            . BuildStore.runBuildStore

    mkLoading i tot =
        GhciLoading
            { index = i
            , total = tot
            , moduleName = "Mod"
            , sourceFile = "Mod.hs"
            }

    result =
        BuildResult
            { completedAt = epoch
            , duration = 0
            , moduleCount = 0
            , diagnostics = []
            }

    phaseTestSuites :: BuildState -> Test.Suites
    phaseTestSuites s = case s.phase of
        BuildComplete _ (PostBuild testSuites _) -> testSuites
        _ -> Test.Suites mempty

    epoch :: UTCTime
    epoch = UTCTime (fromGregorian 2024 1 1) 0

    emptyDaemonInfo :: DaemonInfo
    emptyDaemonInfo =
        DaemonInfo
            { targets = []
            , watchDirs = []
            , sockPath = ""
            , logFile = ""
            , metricsPort = Nothing
            }


mkTestTarget :: Text -> TestTarget
mkTestTarget = TestTarget . Bare
