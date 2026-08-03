module Unit.Tricorder.Daemon.TestRunnerSpec (spec_TestRunner) where

import Control.Exception (ErrorCall (..))
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Exception (try)
import Test.Hspec

import Tricorder.Daemon.TestRunner
    ( GhciOutcome (..)
    , TestRunner
    , detectOutcome
    , runTestSuite
    )
import Tricorder.Session (Target (..), TestTarget (..), TestTimeout (..))

import Tricorder.Build.Test qualified as Test
import Tricorder.Daemon.TestRunner qualified as TestRunner


spec_TestRunner :: Spec
spec_TestRunner = do
    describe "detectOutcome" testDetectOutcome
    describe "runScripted" testScripted


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
        result <-
            runScripted [Right passingRun]
                $ runTestSuite noProgress testTimeout
                $ mkTestTarget "test:foo"
        result `shouldBe` passingRun

    it "ignores the target name argument" do
        result <-
            runScripted [Right failingRun]
                $ runTestSuite noProgress testTimeout
                $ mkTestTarget "test:anything"
        result `shouldBe` failingRun

    it "throws when scripted result is Left" do
        result <-
            runScripted [Left (toException boom)]
                $ try @ErrorCall
                $ runTestSuite noProgress testTimeout
                $ mkTestTarget "test:foo"
        result `shouldBe` Left boom

    describe "sequencing" do
        it "consumes results in order across multiple calls" do
            (a, b) <- runScripted [Right passingRun, Right failingRun] do
                a <- runTestSuite noProgress testTimeout $ mkTestTarget "test:foo"
                b <- runTestSuite noProgress testTimeout $ mkTestTarget "test:bar"
                pure (a, b)
            a `shouldBe` passingRun
            b `shouldBe` failingRun

        it "recover scenario: error then success" do
            result <- runScripted [Left (toException boom), Right passingRun] do
                r1 <- try @ErrorCall $ runTestSuite noProgress testTimeout $ mkTestTarget "test:foo"
                r2 <- runTestSuite noProgress testTimeout $ mkTestTarget "test:bar"
                pure (r1, r2)
            fst result `shouldBe` Left boom
            snd result `shouldBe` passingRun


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
runScripted results = runEff . runConcurrent . TestRunner.runScripted results


mkTestTarget :: Text -> TestTarget
mkTestTarget = TestTarget . Bare


testTimeout :: TestTimeout
testTimeout = TestTimeout (-1)


noProgress :: b -> Eff es ()
noProgress = const $ pure ()
