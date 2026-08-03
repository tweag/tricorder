module Unit.Tricorder.TestOutputSpec (spec_TestOutput) where

import Test.Hspec

import Tricorder.TestOutput (parseHspecDuration, parseHspecOutput, stripGhciNoise)

import Tricorder.Build.Test qualified as Test


spec_TestOutput :: Spec
spec_TestOutput = do
    describe "parseHspecOutput" do
        it "returns empty list for empty output" do
            parseHspecOutput "" `shouldBe` []

        it "parses a passing test" do
            let output = "  foo\n    bar baz:                                      OK\n"
            parseHspecOutput output
                `shouldBe` [Test.Case {description = "bar baz:", outcome = Test.Passed}]

        it "parses a failing test" do
            let output = "  foo\n    bar baz:                                      FAIL\n"
            parseHspecOutput output
                `shouldBe` [Test.Case {description = "bar baz:", outcome = Test.Failed ""}]

        it "captures failure details" do
            let output =
                    "    a test:                                            FAIL\n"
                        <> "      expected: 1\n"
                        <> "       but got: 2\n"
                        <> "    another test:                                       OK\n"
            parseHspecOutput output
                `shouldBe` [ Test.Case
                                { description = "a test:"
                                , outcome = Test.Failed "expected: 1\nbut got: 2"
                                }
                           , Test.Case {description = "another test:", outcome = Test.Passed}
                           ]

        it "stops collecting details when indentation returns to test level" do
            let output =
                    "    failing:                                           FAIL\n"
                        <> "      detail line\n"
                        <> "    passing:                                          OK\n"
            let cases = parseHspecOutput output
            length cases `shouldBe` 2
            case cases of
                (c : _) -> c.outcome `shouldBe` Test.Failed "detail line"
                [] -> expectationFailure "expected at least one test case"

        it "skips group header lines" do
            let output =
                    "  MyModule\n"
                        <> "    someFunction\n"
                        <> "      does the thing:                                  OK\n"
            parseHspecOutput output
                `shouldBe` [Test.Case {description = "does the thing:", outcome = Test.Passed}]

        it "parses mixed passing and failing tests" do
            let output =
                    "  Suite\n"
                        <> "    passes:                                            OK\n"
                        <> "    fails:                                             FAIL\n"
                        <> "      reason\n"
                        <> "    also passes:                                       OK\n"
            parseHspecOutput output
                `shouldBe` [ Test.Case {description = "passes:", outcome = Test.Passed}
                           , Test.Case {description = "fails:", outcome = Test.Failed "reason"}
                           , Test.Case {description = "also passes:", outcome = Test.Passed}
                           ]

        it "parses a passing test with a timing annotation" do
            let output = "  slow test:                                          OK (0.05s)\n"
            parseHspecOutput output
                `shouldBe` [Test.Case {description = "slow test:", outcome = Test.Passed}]

        it "parses a passing test with a millisecond annotation" do
            let output = "  fast property:                                      OK (12ms)\n"
            parseHspecOutput output
                `shouldBe` [Test.Case {description = "fast property:", outcome = Test.Passed}]

        it "parses a failing test with a timing annotation" do
            let output = "  slow fail:                                          FAIL (0.03s)\n"
            parseHspecOutput output
                `shouldBe` [Test.Case {description = "slow fail:", outcome = Test.Failed ""}]

        it "does not strip a non-timing parenthetical in the description" do
            let output = "  test (corner case):                                 OK\n"
            parseHspecOutput output
                `shouldBe` [Test.Case {description = "test (corner case):", outcome = Test.Passed}]

    describe "parseHspecDuration" do
        it "returns Nothing for empty output" do
            parseHspecDuration "" `shouldBe` Nothing

        it "returns Nothing when no timing line is present" do
            parseHspecDuration "2 examples, 0 failures\n" `shouldBe` Nothing

        it "parses duration from passing summary line" do
            parseHspecDuration "All 177 tests passed (0.05s)\n"
                `shouldBe` Just 50

        it "parses duration from failing summary line" do
            parseHspecDuration "1 out of 177 tests failed (0.06s)\n"
                `shouldBe` Just 60

        it "does not match indented individual test timing lines" do
            parseHspecDuration "      entry is evicted after cleanup thread fires past TTL:  OK (0.05s)\n"
                `shouldBe` Nothing

        it "parses duration embedded in full hspec output" do
            let output =
                    "  Suite\n"
                        <> "    passes:                                          OK\n"
                        <> "    slow test:                                       OK (0.05s)\n"
                        <> "\n"
                        <> "All 2 tests passed (0.5s)\n"
            parseHspecDuration output `shouldBe` Just 500

    describe "stripGhciNoise" do
        it "passes through empty list" do
            stripGhciNoise [] `shouldBe` []

        it "passes through output with no ghci prompt" do
            let ls = ["line one", "line two", "line three"]
            stripGhciNoise ls `shouldBe` ls

        it "strips cabal build preamble" do
            let ls =
                    [ "Resolving dependencies..."
                    , "Build profile: -w ghc-9.6.3 -O1"
                    , "ghci> :reload"
                    , "  test one:                                          OK"
                    , "  test two:                                          OK"
                    ]
            stripGhciNoise ls
                `shouldBe` [ "  test one:                                          OK"
                           , "  test two:                                          OK"
                           ]

        it "strips trailing ghci prompt" do
            let ls =
                    [ "ghci> :reload"
                    , "  a test:                                            OK"
                    , "ghci> "
                    ]
            stripGhciNoise ls `shouldBe` ["  a test:                                            OK"]

        it "strips trailing \"Leaving GHCi.\" line" do
            let ls =
                    [ "ghci> :reload"
                    , "  a test:                                            OK"
                    , "Leaving GHCi."
                    ]
            stripGhciNoise ls `shouldBe` ["  a test:                                            OK"]

        it "strips trailing \"*** Exception: ...\" lines" do
            let ls =
                    [ "ghci> :reload"
                    , "  a test:                                            OK"
                    , "*** Exception: ExitSuccess"
                    ]
            stripGhciNoise ls `shouldBe` ["  a test:                                            OK"]

        it "full round-trip strips build noise, keeps test output" do
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
                `shouldBe` [ "  Suite"
                           , "    passes:                                          OK"
                           , "    fails:                                           FAIL"
                           , "      some detail"
                           , ""
                           , "Finished in 0.0001 seconds"
                           ]
