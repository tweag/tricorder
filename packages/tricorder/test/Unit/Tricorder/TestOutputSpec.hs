module Unit.Tricorder.TestOutputSpec (test_TestOutput) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertFailure, testCase, (@?=))

import Tricorder.Build.Duration (Duration (..))
import Tricorder.TestOutput (parseHspecDuration, parseHspecOutput, stripGhciNoise)

import Tricorder.Build.Test qualified as Test


test_TestOutput :: TestTree
test_TestOutput =
    testGroup
        "TestOutput"
        [ testGroup
            "parseHspecOutput"
            [ testCase "returns empty list for empty output" do
                parseHspecOutput "" @?= []
            , testCase "parses a passing test" do
                let output = "  foo\n    bar baz:                                      OK\n"
                parseHspecOutput output
                    @?= [Test.Case {description = "bar baz:", outcome = Test.Passed}]
            , testCase "parses a failing test" do
                let output = "  foo\n    bar baz:                                      FAIL\n"
                parseHspecOutput output
                    @?= [Test.Case {description = "bar baz:", outcome = Test.Failed ""}]
            , testCase "captures failure details" do
                let output =
                        "    a test:                                            FAIL\n"
                            <> "      expected: 1\n"
                            <> "       but got: 2\n"
                            <> "    another test:                                       OK\n"
                parseHspecOutput output
                    @?= [ Test.Case
                            { description = "a test:"
                            , outcome = Test.Failed "expected: 1\nbut got: 2"
                            }
                        , Test.Case {description = "another test:", outcome = Test.Passed}
                        ]
            , testCase "stops collecting details when indentation returns to test level" do
                let output =
                        "    failing:                                           FAIL\n"
                            <> "      detail line\n"
                            <> "    passing:                                          OK\n"
                let cases = parseHspecOutput output
                length cases @?= 2
                case cases of
                    (c : _) -> c.outcome @?= Test.Failed "detail line"
                    [] -> assertFailure "expected at least one test case"
            , testCase "skips group header lines" do
                let output =
                        "  MyModule\n"
                            <> "    someFunction\n"
                            <> "      does the thing:                                  OK\n"
                parseHspecOutput output
                    @?= [Test.Case {description = "does the thing:", outcome = Test.Passed}]
            , testCase "parses mixed passing and failing tests" do
                let output =
                        "  Suite\n"
                            <> "    passes:                                            OK\n"
                            <> "    fails:                                             FAIL\n"
                            <> "      reason\n"
                            <> "    also passes:                                       OK\n"
                parseHspecOutput output
                    @?= [ Test.Case {description = "passes:", outcome = Test.Passed}
                        , Test.Case {description = "fails:", outcome = Test.Failed "reason"}
                        , Test.Case {description = "also passes:", outcome = Test.Passed}
                        ]
            , testCase "parses a passing test with a timing annotation" do
                let output = "  slow test:                                          OK (0.05s)\n"
                parseHspecOutput output
                    @?= [Test.Case {description = "slow test:", outcome = Test.Passed}]
            , testCase "parses a passing test with a millisecond annotation" do
                let output = "  fast property:                                      OK (12ms)\n"
                parseHspecOutput output
                    @?= [Test.Case {description = "fast property:", outcome = Test.Passed}]
            , testCase "parses a failing test with a timing annotation" do
                let output = "  slow fail:                                          FAIL (0.03s)\n"
                parseHspecOutput output
                    @?= [Test.Case {description = "slow fail:", outcome = Test.Failed ""}]
            , testCase "does not strip a non-timing parenthetical in the description" do
                let output = "  test (corner case):                                 OK\n"
                parseHspecOutput output
                    @?= [Test.Case {description = "test (corner case):", outcome = Test.Passed}]
            ]
        , testGroup
            "parseHspecDuration"
            [ testCase "returns Nothing for empty output" do
                parseHspecDuration "" @?= Nothing
            , testCase "returns Nothing when no timing line is present" do
                parseHspecDuration "2 examples, 0 failures\n" @?= Nothing
            , testCase "parses duration from passing summary line" do
                parseHspecDuration "All 177 tests passed (0.05s)\n"
                    @?= Just (Duration 50)
            , testCase "parses duration from failing summary line" do
                parseHspecDuration "1 out of 177 tests failed (0.06s)\n"
                    @?= Just (Duration 60)
            , testCase "does not match indented individual test timing lines" do
                parseHspecDuration "      entry is evicted after cleanup thread fires past TTL:  OK (0.05s)\n"
                    @?= Nothing
            , testCase "parses duration embedded in full hspec output" do
                let output =
                        "  Suite\n"
                            <> "    passes:                                          OK\n"
                            <> "    slow test:                                       OK (0.05s)\n"
                            <> "\n"
                            <> "All 2 tests passed (0.5s)\n"
                parseHspecDuration output @?= Just (Duration 500)
            ]
        , testGroup
            "stripGhciNoise"
            [ testCase "passes through empty list" do
                stripGhciNoise [] @?= []
            , testCase "passes through output with no ghci prompt" do
                let ls = ["line one", "line two", "line three"]
                stripGhciNoise ls @?= ls
            , testCase "strips cabal build preamble" do
                let ls =
                        [ "Resolving dependencies..."
                        , "Build profile: -w ghc-9.6.3 -O1"
                        , "ghci> :reload"
                        , "  test one:                                          OK"
                        , "  test two:                                          OK"
                        ]
                stripGhciNoise ls
                    @?= [ "  test one:                                          OK"
                        , "  test two:                                          OK"
                        ]
            , testCase "strips trailing ghci prompt" do
                let ls =
                        [ "ghci> :reload"
                        , "  a test:                                            OK"
                        , "ghci> "
                        ]
                stripGhciNoise ls @?= ["  a test:                                            OK"]
            , testCase "strips trailing \"Leaving GHCi.\" line" do
                let ls =
                        [ "ghci> :reload"
                        , "  a test:                                            OK"
                        , "Leaving GHCi."
                        ]
                stripGhciNoise ls @?= ["  a test:                                            OK"]
            , testCase "strips trailing \"*** Exception: ...\" lines" do
                let ls =
                        [ "ghci> :reload"
                        , "  a test:                                            OK"
                        , "*** Exception: ExitSuccess"
                        ]
                stripGhciNoise ls @?= ["  a test:                                            OK"]
            , testCase "full round-trip strips build noise, keeps test output" do
                let ls =
                        [ "Resolving dependencies..."
                        , "Build profile: -w ghc-9.6.3 -O1"
                        , "Preprocessing test suite 'spec' for tricorder-0.1.0.0..."
                        , "ghci> :reload"
                        , "  Suite"
                        , "    passes:                                          OK"
                        , "    fails:                                           FAIL"
                        , "      some detail"
                        , ""
                        , "Finished in 0.0001 seconds"
                        , "ghci> "
                        , "Leaving GHCi."
                        , "*** Exception: ExitFailure 1"
                        ]
                stripGhciNoise ls
                    @?= [ "  Suite"
                        , "    passes:                                          OK"
                        , "    fails:                                           FAIL"
                        , "      some detail"
                        , ""
                        , "Finished in 0.0001 seconds"
                        ]
            ]
        ]
