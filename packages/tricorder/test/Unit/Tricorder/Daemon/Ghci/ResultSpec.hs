module Unit.Tricorder.Daemon.Ghci.ResultSpec (test_Result) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?), (@?=))

import Tricorder.Build (Severity (..))
import Tricorder.Daemon.Ghci.LoadResult (LoadResult (..))
import Tricorder.Daemon.Ghci.Loading (Loading (..))
import Tricorder.Daemon.Ghci.Message (Message (..))
import Tricorder.Daemon.Ghci.Position (Position (..))
import Tricorder.Daemon.Ghci.Result (collectResult, collectResultCustom, extractTitle, parseReload)

import Tricorder.Build qualified as Build.Diagnostic
import Tricorder.Daemon.Ghci.Load qualified as Load
import Tricorder.Daemon.Ghci.LoadOutcome qualified as LoadOutcome
import Tricorder.Daemon.Ghci.Severity qualified as Severity


test_Result :: TestTree
test_Result =
    testGroup
        "Result"
        [ testGroup "extractTitle" testExtractTitle
        , testGroup "parseReload" testParseReload
        , testGroup "collectResultCustom" testCollectResultCustom
        , testGroup "collectResult" testCollectResult
        ]


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


testParseReload :: [TestTree]
testParseReload =
    [ testGroup "clean build" testCleanBuild
    , testGroup "with errors and warnings" testErrors
    , testGroup "with -fhide-source-paths (no Loading items)" testHideSourcePaths
    , testGroup "with <no location info> errors" testNoLocationInfo
    , testGroup "with Loaded GHCi configuration" testLoadedConfig
    ]


testCleanBuild :: [TestTree]
testCleanBuild =
    [ testCase "produces GLoading items for each compiled module" do
        let input =
                [ "[1 of 3] Compiling Tricorder.Build ( src/Tricorder.Build.hs, interpreted )"
                , "[2 of 3] Compiling Tricorder.Session    ( src/Tricorder/Session.hs, interpreted )"
                , "[3 of 3] Compiling Main                 ( app/Main.hs, interpreted )"
                , "Ok, 3 modules loaded."
                ]
        parseReload input
            @?= [ Load.Loading
                    Loading
                        { index = 1
                        , total = 3
                        , moduleName = "Tricorder.Build"
                        , sourceFile = "src/Tricorder.Build.hs"
                        }
                , Load.Loading
                    Loading
                        { index = 2
                        , total = 3
                        , moduleName = "Tricorder.Session"
                        , sourceFile = "src/Tricorder/Session.hs"
                        }
                , Load.Loading Loading {index = 3, total = 3, moduleName = "Main", sourceFile = "app/Main.hs"}
                , Load.Summary LoadOutcome.LoadSucceeded
                ]
    , testCase "handles padded module index (e.g. [ 1 of 47])" do
        let input =
                [ "[ 1 of 47] Compiling Main              ( app/Main.hs, interpreted )"
                , "Ok, 1 module loaded."
                ]
        parseReload input
            @?= [ Load.Loading Loading {index = 1, total = 47, moduleName = "Main", sourceFile = "app/Main.hs"}
                , Load.Summary LoadOutcome.LoadSucceeded
                ]
    , testGroup
        "when only summary line"
        [ testCase "returns the summary outcome" do
            parseReload ["Ok, 0 modules loaded."] @?= [Load.Summary LoadOutcome.LoadSucceeded]
        ]
    ]


testErrors :: [TestTree]
testErrors =
    [ testCase "parses a single-line error" do
        let input = ["src/Foo.hs:10:5: error: Variable not in scope: foo"]
        parseReload input
            @?= [ Load.Message
                    Message
                        { severity = Severity.Error
                        , file = "src/Foo.hs"
                        , startPos = Position 10 5
                        , endPos = Position 10 5
                        , messageLines = ["src/Foo.hs:10:5: error: Variable not in scope: foo"]
                        }
                ]
    , testCase "parses a warning with continuation lines" do
        let input =
                [ "src/Bar.hs:20:3: warning: [-Wunused-imports]"
                , "    Redundant import: Data.List"
                , "    Perhaps you want to remove it."
                ]
        parseReload input
            @?= [ Load.Message
                    Message
                        { severity = Severity.Warning
                        , file = "src/Bar.hs"
                        , startPos = Position 20 3
                        , endPos = Position 20 3
                        , messageLines =
                            [ "src/Bar.hs:20:3: warning: [-Wunused-imports]"
                            , "    Redundant import: Data.List"
                            , "    Perhaps you want to remove it."
                            ]
                        }
                ]
    , testCase "parses a span position (L:C-C2:)" do
        let input = ["src/Baz.hs:5:1-10: error: Parse error"]
        parseReload input
            @?= [ Load.Message
                    Message
                        { severity = Severity.Error
                        , file = "src/Baz.hs"
                        , startPos = Position 5 1
                        , endPos = Position 5 10
                        , messageLines = ["src/Baz.hs:5:1-10: error: Parse error"]
                        }
                ]
    , testCase "parses a span position ((L1,C1)-(L2,C2):)" do
        let input = ["src/Qux.hs:(3,1)-(5,20): error: Multi-line error"]
        parseReload input
            @?= [ Load.Message
                    Message
                        { severity = Severity.Error
                        , file = "src/Qux.hs"
                        , startPos = Position 3 1
                        , endPos = Position 5 20
                        , messageLines = ["src/Qux.hs:(3,1)-(5,20): error: Multi-line error"]
                        }
                ]
    , testCase "parses a span position with double-paren end ((L1,C1)-((L2,C2):)" do
        let input = ["src/Qux.hs:(3,1)-((5,20): error: Multi-line error"]
        parseReload input
            @?= [ Load.Message
                    Message
                        { severity = Severity.Error
                        , file = "src/Qux.hs"
                        , startPos = Position 3 1
                        , endPos = Position 5 20
                        , messageLines = ["src/Qux.hs:(3,1)-((5,20): error: Multi-line error"]
                        }
                ]
    , testCase "parses source-display continuation lines (pipe format)" do
        let input =
                [ "src/Foo.hs:10:5: error: Variable not in scope: foo"
                , "   |"
                , "10 | foo bar"
                , "   | ^^^"
                , "    Suggested fix: import Foo"
                ]
        parseReload input
            @?= [ Load.Message
                    Message
                        { severity = Severity.Error
                        , file = "src/Foo.hs"
                        , startPos = Position 10 5
                        , endPos = Position 10 5
                        , messageLines =
                            [ "src/Foo.hs:10:5: error: Variable not in scope: foo"
                            , "   |"
                            , "10 | foo bar"
                            , "   | ^^^"
                            , "    Suggested fix: import Foo"
                            ]
                        }
                ]
    , testCase "strips ANSI codes from header for matching but stores original in glMessage" do
        let ansiHeader = "\ESC[1msrc/Foo.hs:10:5:\ESC[0m \ESC[91merror:\ESC[0m Variable not in scope: foo"
        parseReload [ansiHeader]
            @?= [ Load.Message
                    Message
                        { severity = Severity.Error
                        , file = "src/Foo.hs"
                        , startPos = Position 10 5
                        , endPos = Position 10 5
                        , messageLines = [ansiHeader]
                        }
                ]
    , testCase "parses a Windows drive-letter path in a diagnostic" do
        let input = ["C:\\path\\file.hs:10:5: error: Variable not in scope: foo"]
        parseReload input
            @?= [ Load.Message
                    Message
                        { severity = Severity.Error
                        , file = "C:\\path\\file.hs"
                        , startPos = Position 10 5
                        , endPos = Position 10 5
                        , messageLines = ["C:\\path\\file.hs:10:5: error: Variable not in scope: foo"]
                        }
                ]
    , testCase "parses mixed Loading, Message, and summary items" do
        let input =
                [ "[1 of 2] Compiling Lib ( src/Lib.hs, interpreted )"
                , "src/Lib.hs:5:1: error: Oops"
                , "[2 of 2] Compiling Main ( app/Main.hs, interpreted )"
                , "Failed, 1 module loaded."
                ]
        parseReload input
            @?= [ Load.Loading Loading {index = 1, total = 2, moduleName = "Lib", sourceFile = "src/Lib.hs"}
                , Load.Message
                    Message
                        { severity = Severity.Error
                        , file = "src/Lib.hs"
                        , startPos = Position 5 1
                        , endPos = Position 5 1
                        , messageLines = ["src/Lib.hs:5:1: error: Oops"]
                        }
                , Load.Loading Loading {index = 2, total = 2, moduleName = "Main", sourceFile = "app/Main.hs"}
                , Load.Summary LoadOutcome.LoadFailed
                ]
    ]


testHideSourcePaths :: [TestTree]
testHideSourcePaths =
    [ testGroup
        "when source paths are hidden"
        [ testCase "produces no GLoading items" do
            let input =
                    [ "src/Foo.hs:10:5: error: Variable not in scope: foo"
                    , "    Perhaps you meant: 'bar'"
                    , "Failed, one module failed to load."
                    ]
            parseReload input
                @?= [ Load.Message
                        Message
                            { severity = Severity.Error
                            , file = "src/Foo.hs"
                            , startPos = Position 10 5
                            , endPos = Position 10 5
                            , messageLines =
                                [ "src/Foo.hs:10:5: error: Variable not in scope: foo"
                                , "    Perhaps you meant: 'bar'"
                                ]
                            }
                    , Load.Summary LoadOutcome.LoadFailed
                    ]
        ]
    , testGroup
        "when all modules are already up to date"
        [ testCase "returns the summary outcome" do
            -- GHCi with -fhide-source-paths and nothing to recompile
            parseReload ["Ok, 5 modules loaded."] @?= [Load.Summary LoadOutcome.LoadSucceeded]
        ]
    ]


testNoLocationInfo :: [TestTree]
testNoLocationInfo =
    [ testCase "handles <no location info>: error: with continuation" do
        let input =
                [ "<no location info>: error:"
                , "    Module `Tricorder.Missing' is not loaded."
                ]
        parseReload input
            @?= [ Load.Message
                    Message
                        { severity = Severity.Error
                        , file = "<no location info>"
                        , startPos = Position 0 0
                        , endPos = Position 0 0
                        , messageLines =
                            [ "<no location info>: error:"
                            , "    Module `Tricorder.Missing' is not loaded."
                            ]
                        }
                ]
    , testCase "handles <no location info>: error: with no continuation" do
        parseReload ["<no location info>: error: some error"]
            @?= [ Load.Message
                    Message
                        { severity = Severity.Error
                        , file = "<no location info>"
                        , startPos = Position 0 0
                        , endPos = Position 0 0
                        , messageLines = ["<no location info>: error: some error"]
                        }
                ]
    ]


testLoadedConfig :: [TestTree]
testLoadedConfig =
    [ testCase "parses a GHCi configuration line" do
        parseReload ["Loaded GHCi configuration from /home/user/project/.ghci"]
            @?= [Load.LoadConfig "/home/user/project/.ghci"]
    , testCase "parses a Windows-style GHCi configuration path" do
        parseReload ["Loaded GHCi configuration from C:\\Users\\user\\project\\.ghci"]
            @?= [Load.LoadConfig "C:\\Users\\user\\project\\.ghci"]
    , testCase "handles config line mixed with other output" do
        let input =
                [ "Loaded GHCi configuration from .ghci"
                , "[1 of 1] Compiling Main ( app/Main.hs, interpreted )"
                , "Ok, 1 module loaded."
                ]
        parseReload input
            @?= [ Load.LoadConfig ".ghci"
                , Load.Loading Loading {index = 1, total = 1, moduleName = "Main", sourceFile = "app/Main.hs"}
                , Load.Summary LoadOutcome.LoadSucceeded
                ]
    ]


testCollectResultCustom :: [TestTree]
testCollectResultCustom =
    [ testGroup "<no location info> plugin load failure" testPluginLoadFailure
    ]


-- | Regression test for the \"All good\" bug with home-unit GHC plugins.
--
-- Under @cabal repl --enable-multi-repl@ every unit is interpreted, so a
-- package used as a GHC plugin in the same project is not available as a
-- compiled plugin. The unit that depends on it fails to load, GHCi reports the
-- failure with @\<no location info\>@ (it has no source span), and the load
-- ends with @Failed, N modules loaded@. This output must still surface as an
-- error diagnostic — otherwise the build is silently reported as clean.
testPluginLoadFailure :: [TestTree]
testPluginLoadFailure =
    -- Shape of the GHCi output from `cabal repl --enable-multi-repl` when an
    -- executable loads a home-unit GHC plugin: the plugin package's modules
    -- compile, then the unit using the plugin fails with a location-less error.
    [ testCase "surfaces the plugin load failure as an error diagnostic" do
        Build.Diagnostic.SError `elem` map (.severity) result.diagnostics @? "expected an error diagnostic"
    , testCase "carries the plugin error message in the diagnostic title" do
        "Could not load module \8216My.Plugin\8217." `elem` map (.title) result.diagnostics
            @? "expected the plugin error message in a diagnostic title"
    ]
  where
    reloadOutput =
        [ "[3 of 5] Compiling My.Plugin       ( src/My/Plugin.hs, interpreted )[plugin-pkg-1.0.0-inplace]"
        , "<no location info>: error:"
        , "    Could not load module \8216My.Plugin\8217."
        , "It is a member of the hidden package \8216plugin-pkg-1.0.0\8217."
        , "Perhaps you need to add \8216plugin-pkg\8217 to the build-depends in your .cabal file."
        , "Use -v to see a list of the files searched for."
        , ""
        , "[5 of 5] Compiling Main            ( test/Tests.hs, interpreted )[app-pkg-0.1.0.0-inplace-test]"
        , "Failed, 4 modules loaded."
        ]
    result = collectResultCustom "/project" (parseReload reloadOutput) [] []


testCollectResult :: [TestTree]
testCollectResult =
    [ testGroup "failed load with no located error" testUnattributedFailure
    ]


-- 'collectResult' is the safety net: GHCi can end a load with @Failed, …@
-- without emitting any error that carries a source span. The build must never
-- read as clean in that case, so a synthetic error diagnostic is added.
testUnattributedFailure :: [TestTree]
testUnattributedFailure =
    [ testGroup
        "when the load failed but no error was located"
        [ testCase "adds a synthetic error" do
            let reloadOutput =
                    [ "[1 of 2] Compiling Lib  ( src/Lib.hs, interpreted )"
                    , "[2 of 2] Compiling Main ( app/Main.hs, interpreted )"
                    , "Failed, 1 module loaded."
                    ]
                result = collectResult "/project" reloadOutput [] []
            map (.severity) result.diagnostics @?= [SError]
        ]
    , testCase "does not duplicate a failure that already produced a located error" do
        let reloadOutput =
                [ "[1 of 1] Compiling Lib ( src/Lib.hs, interpreted )"
                , "src/Lib.hs:5:1: error: Oops"
                , "Failed, 0 modules loaded."
                ]
            result = collectResult "/project" reloadOutput [] []
        -- Only the real, located diagnostic — no synthetic one appended.
        map (.file) result.diagnostics @?= ["src/Lib.hs"]
    , testCase "adds nothing for a successful load" do
        let reloadOutput =
                [ "[1 of 1] Compiling Main ( app/Main.hs, interpreted )"
                , "Ok, 1 module loaded."
                ]
            result = collectResult "/project" reloadOutput [] []
        result.diagnostics @?= []
    , testGroup
        "when 'Failed,' appears off the summary line"
        [ testCase "does not flag a clean build" do
            -- The load outcome lives on GHCi's single summary line
            -- ("Ok, …" / "Failed, …"). Output printed *during* the load — e.g. a
            -- Template Haskell splice or top-level IO run while interpreting — can
            -- contain a line that happens to begin with "Failed,". That must not be
            -- mistaken for a failed load: the summary here is "Ok," so no synthetic
            -- error belongs.
            let reloadOutput =
                    [ "[1 of 1] Compiling Main ( app/Main.hs, interpreted )"
                    , "Failed, retrying with fallback" -- printed by a TH splice
                    , "Ok, 1 module loaded."
                    ]
                result = collectResult "/project" reloadOutput [] []
            result.diagnostics @?= []
        ]
    ]
