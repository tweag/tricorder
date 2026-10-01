module Unit.Tricorder.Daemon.TestRunnerSpec (test_TestRunner) where

import Control.Exception (ErrorCall (..))
import Data.Default (def)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Exception (try)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Daemon.TestRunner
    ( GhciOutcome (..)
    , TestRunner
    , detectOutcome
    , runTestSuite
    )
import Tricorder.Session.Command.RenderedCommand (RenderedCommand (..))
import Tricorder.Session.Stage.Test.Command (RenderedTestCommand (..))
import Tricorder.Session.TestTimeout (TestTimeout (..))

import Tricorder.Build.Test qualified as Test
import Tricorder.Daemon.TestRunner qualified as TestRunner
import Tricorder.Session.Stage qualified as Stage


test_TestRunner :: TestTree
test_TestRunner =
    testGroup
        "TestRunner"
        [ testGroup "detectOutcome" testDetectOutcome
        , testGroup "runScripted" testScripted
        ]


--------------------------------------------------------------------------------
-- detectOutcome tests
--------------------------------------------------------------------------------

testDetectOutcome :: [TestTree]
testDetectOutcome =
    [ testGroup
        "no exception line"
        [ testCase "treats empty output as pass" do
            detectOutcome "" @?= GhciPassed
        , testCase "treats output with no exception as pass" do
            detectOutcome "2 examples, 0 failures\n" @?= GhciPassed
        , testCase "does not match 'ExitSuccess' without the exception prefix" do
            detectOutcome "ExitSuccess\n" @?= GhciPassed
        ]
    , testGroup
        "ExitSuccess"
        [ testCase "detects ExitSuccess as pass" do
            detectOutcome "*** Exception: ExitSuccess\n" @?= GhciPassed
        , testCase "detects ExitSuccess anywhere in output" do
            detectOutcome "All tests passed\n*** Exception: ExitSuccess\n"
                @?= GhciPassed
        ]
    , testGroup
        "ExitFailure"
        [ testCase "detects ExitFailure 1 as fail" do
            detectOutcome "1 failure\n*** Exception: ExitFailure 1\n"
                @?= GhciFailed
        , testCase "detects ExitFailure with any exit code as fail" do
            detectOutcome "*** Exception: ExitFailure 42\n" @?= GhciFailed
        , testCase "detects ExitFailure anywhere in output" do
            detectOutcome "Some output\n*** Exception: ExitFailure 1\nMore output\n"
                @?= GhciFailed
        ]
    , testGroup
        "other exception"
        [ testCase "classifies unknown exception as error with message" do
            detectOutcome "*** Exception: SomeException \"oops\"\n"
                @?= GhciCrashed "SomeException \"oops\""
        , testCase "trims trailing whitespace from the error message" do
            detectOutcome "*** Exception: Crashed  \n"
                @?= GhciCrashed "Crashed"
        ]
    , testGroup
        "compile failure (no exception line, but GHC errors present)"
        [ testCase "flags ':main not in scope' as crashed" do
            detectOutcome "<interactive>:1:1: error: [GHC-76037] Not in scope: 'main'\n"
                @?= GhciCrashed
                    "<interactive>:1:1: error: [GHC-76037] Not in scope: 'main'"
        , testCase "flags a source-file compile error as crashed" do
            detectOutcome "src/Foo.hs:42:5: error: Variable not in scope: foo\n"
                @?= GhciCrashed "src/Foo.hs:42:5: error: Variable not in scope: foo"
        , testCase "reports the first error line when multiple are present" do
            detectOutcome
                "src/Foo.hs:42:5: error: Variable not in scope: foo\nsrc/Bar.hs:10:1: error: Parse error\n"
                @?= GhciCrashed "src/Foo.hs:42:5: error: Variable not in scope: foo"
        , testCase "prefers exit exception over compile-error heuristic when both appear" do
            -- A real failing run could plausibly mention 'error:' in its
            -- captured output (e.g. logged messages); the ExitFailure line
            -- still wins.
            detectOutcome "log: error: something happened\n*** Exception: ExitFailure 1\n"
                @?= GhciFailed
        ]
    ]


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: [TestTree]
testScripted =
    [ testCase "returns scripted TestRun" do
        result <-
            runScripted [Right passingRun]
                $ runTestSuite noProgress testTimeout
                $ mkResolved
                $ RenderedCommand
                $ "cabal repl test:foo"
        result @?= passingRun
    , testCase "ignores the target name argument" do
        result <-
            runScripted [Right failingRun]
                $ runTestSuite noProgress testTimeout
                $ mkResolved
                $ RenderedCommand
                $ "cabal repl test:anything"
        result @?= failingRun
    , testCase "throws when scripted result is Left" do
        result <-
            runScripted [Left (toException boom)]
                $ try @ErrorCall
                $ runTestSuite noProgress testTimeout
                $ mkResolved
                $ RenderedCommand
                $ "cabal repl test:foo"
        result @?= Left boom
    , testGroup
        "sequencing"
        [ testCase "consumes results in order across multiple calls" do
            (a, b) <- runScripted [Right passingRun, Right failingRun] do
                a <-
                    runTestSuite noProgress testTimeout
                        $ mkResolved
                        $ RenderedCommand
                        $ "cabal repl test:foo"
                b <-
                    runTestSuite noProgress testTimeout
                        $ mkResolved
                        $ RenderedCommand
                        $ "cabal repl test:bar"
                pure (a, b)
            a @?= passingRun
            b @?= failingRun
        , testCase "recover scenario: error then success" do
            result <- runScripted [Left (toException boom), Right passingRun] do
                r1 <-
                    try @ErrorCall
                        $ runTestSuite noProgress testTimeout
                        $ mkResolved
                        $ RenderedCommand
                        $ "cabal repl test:foo"
                r2 <-
                    runTestSuite noProgress testTimeout
                        $ mkResolved
                        $ RenderedCommand
                        $ "cabal repl test:bar"
                pure (r1, r2)
            fst result @?= Left boom
            snd result @?= passingRun
        ]
    ]


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


mkResolved :: RenderedCommand 'Stage.Test -> RenderedTestCommand
mkResolved cmd = RenderedTestCommand cmd def


testTimeout :: TestTimeout
testTimeout = TestTimeout (-1)


noProgress :: b -> Eff es ()
noProgress = const $ pure ()
