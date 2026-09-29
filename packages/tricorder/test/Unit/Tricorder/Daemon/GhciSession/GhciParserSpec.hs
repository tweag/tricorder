module Unit.Tricorder.Daemon.GhciSession.GhciParserSpec (test_GhciParser) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Tricorder.Build (Diagnostic (..), Severity (..))
import Tricorder.Daemon.GhciSession.GhciParser
    ( GhciLoad (..)
    , GhciLoading (..)
    , GhciMessage (..)
    , GhciSeverity (..)
    , LoadOutcome (..)
    , LoadResult (..)
    , Position (..)
    , collectResult
    , collectResultCustom
    , parseReload
    , parseShowModules
    , parseShowTargets
    )


test_GhciParser :: TestTree
test_GhciParser =
    testGroup
        "GhciParser"
        [ testGroup
            "parseReload"
            [ testGroup "clean build" testCleanBuild
            , testGroup "with errors and warnings" testErrors
            , testGroup "with -fhide-source-paths (no Loading items)" testHideSourcePaths
            , testGroup "with <no location info> errors" testNoLocationInfo
            , testGroup "with Loaded GHCi configuration" testLoadedConfig
            ]
        , testGroup
            "parseShowModules"
            [ testGroup "typical output" testShowModules
            , testGroup "empty / blank input" testShowModulesEmpty
            ]
        , testGroup "parseShowTargets" testShowTargets
        , testGroup
            "collectResultCustom"
            [ testGroup "<no location info> plugin load failure" testPluginLoadFailure
            ]
        , testGroup
            "collectResult"
            [ testGroup "failed load with no located error" testUnattributedFailure
            ]
        ]


--------------------------------------------------------------------------------
-- parseReload: clean build
--------------------------------------------------------------------------------

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
            @?= [ GLoading
                    GhciLoading
                        { index = 1
                        , total = 3
                        , moduleName = "Tricorder.Build"
                        , sourceFile = "src/Tricorder.Build.hs"
                        }
                , GLoading
                    GhciLoading
                        { index = 2
                        , total = 3
                        , moduleName = "Tricorder.Session"
                        , sourceFile = "src/Tricorder/Session.hs"
                        }
                , GLoading GhciLoading {index = 3, total = 3, moduleName = "Main", sourceFile = "app/Main.hs"}
                , GSummary LoadSucceeded
                ]
    , testCase "handles padded module index (e.g. [ 1 of 47])" do
        let input =
                [ "[ 1 of 47] Compiling Main              ( app/Main.hs, interpreted )"
                , "Ok, 1 module loaded."
                ]
        parseReload input
            @?= [ GLoading GhciLoading {index = 1, total = 47, moduleName = "Main", sourceFile = "app/Main.hs"}
                , GSummary LoadSucceeded
                ]
    , testGroup
        "when only summary line"
        [ testCase "returns the summary outcome" do
            parseReload ["Ok, 0 modules loaded."] @?= [GSummary LoadSucceeded]
        ]
    ]


--------------------------------------------------------------------------------
-- parseReload: errors and warnings
--------------------------------------------------------------------------------

testErrors :: [TestTree]
testErrors =
    [ testCase "parses a single-line error" do
        let input = ["src/Foo.hs:10:5: error: Variable not in scope: foo"]
        parseReload input
            @?= [ GMessage
                    GhciMessage
                        { severity = GError
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
            @?= [ GMessage
                    GhciMessage
                        { severity = GWarning
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
            @?= [ GMessage
                    GhciMessage
                        { severity = GError
                        , file = "src/Baz.hs"
                        , startPos = Position 5 1
                        , endPos = Position 5 10
                        , messageLines = ["src/Baz.hs:5:1-10: error: Parse error"]
                        }
                ]
    , testCase "parses a span position ((L1,C1)-(L2,C2):)" do
        let input = ["src/Qux.hs:(3,1)-(5,20): error: Multi-line error"]
        parseReload input
            @?= [ GMessage
                    GhciMessage
                        { severity = GError
                        , file = "src/Qux.hs"
                        , startPos = Position 3 1
                        , endPos = Position 5 20
                        , messageLines = ["src/Qux.hs:(3,1)-(5,20): error: Multi-line error"]
                        }
                ]
    , testCase "parses a span position with double-paren end ((L1,C1)-((L2,C2):)" do
        let input = ["src/Qux.hs:(3,1)-((5,20): error: Multi-line error"]
        parseReload input
            @?= [ GMessage
                    GhciMessage
                        { severity = GError
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
            @?= [ GMessage
                    GhciMessage
                        { severity = GError
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
            @?= [ GMessage
                    GhciMessage
                        { severity = GError
                        , file = "src/Foo.hs"
                        , startPos = Position 10 5
                        , endPos = Position 10 5
                        , messageLines = [ansiHeader]
                        }
                ]
    , testCase "parses a Windows drive-letter path in a diagnostic" do
        let input = ["C:\\path\\file.hs:10:5: error: Variable not in scope: foo"]
        parseReload input
            @?= [ GMessage
                    GhciMessage
                        { severity = GError
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
            @?= [ GLoading GhciLoading {index = 1, total = 2, moduleName = "Lib", sourceFile = "src/Lib.hs"}
                , GMessage
                    GhciMessage
                        { severity = GError
                        , file = "src/Lib.hs"
                        , startPos = Position 5 1
                        , endPos = Position 5 1
                        , messageLines = ["src/Lib.hs:5:1: error: Oops"]
                        }
                , GLoading GhciLoading {index = 2, total = 2, moduleName = "Main", sourceFile = "app/Main.hs"}
                , GSummary LoadFailed
                ]
    ]


--------------------------------------------------------------------------------
-- parseReload: -fhide-source-paths output
--------------------------------------------------------------------------------

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
                @?= [ GMessage
                        GhciMessage
                            { severity = GError
                            , file = "src/Foo.hs"
                            , startPos = Position 10 5
                            , endPos = Position 10 5
                            , messageLines =
                                [ "src/Foo.hs:10:5: error: Variable not in scope: foo"
                                , "    Perhaps you meant: 'bar'"
                                ]
                            }
                    , GSummary LoadFailed
                    ]
        ]
    , testGroup
        "when all modules are already up to date"
        [ testCase "returns the summary outcome" do
            -- GHCi with -fhide-source-paths and nothing to recompile
            parseReload ["Ok, 5 modules loaded."] @?= [GSummary LoadSucceeded]
        ]
    ]


--------------------------------------------------------------------------------
-- parseReload: <no location info> errors
--------------------------------------------------------------------------------

testNoLocationInfo :: [TestTree]
testNoLocationInfo =
    [ testCase "handles <no location info>: error: with continuation" do
        let input =
                [ "<no location info>: error:"
                , "    Module `Tricorder.Missing' is not loaded."
                ]
        parseReload input
            @?= [ GMessage
                    GhciMessage
                        { severity = GError
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
            @?= [ GMessage
                    GhciMessage
                        { severity = GError
                        , file = "<no location info>"
                        , startPos = Position 0 0
                        , endPos = Position 0 0
                        , messageLines = ["<no location info>: error: some error"]
                        }
                ]
    ]


--------------------------------------------------------------------------------
-- parseReload: Loaded GHCi configuration
--------------------------------------------------------------------------------

testLoadedConfig :: [TestTree]
testLoadedConfig =
    [ testCase "parses a GHCi configuration line" do
        parseReload ["Loaded GHCi configuration from /home/user/project/.ghci"]
            @?= [GLoadConfig "/home/user/project/.ghci"]
    , testCase "parses a Windows-style GHCi configuration path" do
        parseReload ["Loaded GHCi configuration from C:\\Users\\user\\project\\.ghci"]
            @?= [GLoadConfig "C:\\Users\\user\\project\\.ghci"]
    , testCase "handles config line mixed with other output" do
        let input =
                [ "Loaded GHCi configuration from .ghci"
                , "[1 of 1] Compiling Main ( app/Main.hs, interpreted )"
                , "Ok, 1 module loaded."
                ]
        parseReload input
            @?= [ GLoadConfig ".ghci"
                , GLoading GhciLoading {index = 1, total = 1, moduleName = "Main", sourceFile = "app/Main.hs"}
                , GSummary LoadSucceeded
                ]
    ]


--------------------------------------------------------------------------------
-- parseShowModules
--------------------------------------------------------------------------------

testShowModules :: [TestTree]
testShowModules =
    [ testCase "parses typical :show modules output" do
        let input =
                [ "Tricorder.Build     ( src/Tricorder.Build.hs, interpreted )"
                , "Tricorder.Session        ( src/Tricorder/Session.hs, interpreted )"
                , "Main                     ( app/Main.hs, interpreted )"
                ]
        parseShowModules input
            @?= [ ("Tricorder.Build", "src/Tricorder.Build.hs")
                , ("Tricorder.Session", "src/Tricorder/Session.hs")
                , ("Main", "app/Main.hs")
                ]
    , testCase "parses absolute paths" do
        parseShowModules ["Lib ( /home/user/project/src/Lib.hs, interpreted )"]
            @?= [("Lib", "/home/user/project/src/Lib.hs")]
    , testCase "strips ANSI codes before parsing" do
        parseShowModules ["\ESC[1mMain\ESC[0m                     ( app/Main.hs, interpreted )"]
            @?= [("Main", "app/Main.hs")]
    ]


testShowModulesEmpty :: [TestTree]
testShowModulesEmpty =
    [ testCase "returns empty list for empty input" do
        parseShowModules [] @?= []
    , testCase "returns empty list for blank lines" do
        parseShowModules ["", "   ", "\t"] @?= []
    , testCase "skips lines without '( '" do
        parseShowModules ["just some random text"] @?= []
    ]


--------------------------------------------------------------------------------
-- parseShowTargets
--------------------------------------------------------------------------------

testShowTargets :: [TestTree]
testShowTargets =
    [ testCase "parses module names emitted by cabal repl --enable-multi-repl" do
        parseShowTargets
            [ "Atelier.Effects.Cache"
            , "Atelier.Effects.Chan"
            , "Paths_tricorder"
            ]
            @?= ["Atelier.Effects.Cache", "Atelier.Effects.Chan", "Paths_tricorder"]
    , testCase "parses file-path targets emitted by plain ghci" do
        parseShowTargets ["src/Foo.hs", "test/Bar.hs"]
            @?= ["src/Foo.hs", "test/Bar.hs"]
    , testCase "strips the leading '*' marker for the active interactive target" do
        parseShowTargets ["*Main", "Foo.Bar"] @?= ["Main", "Foo.Bar"]
    , testCase "strips ANSI escape sequences" do
        parseShowTargets ["\ESC[1mFoo.Bar\ESC[0m"] @?= ["Foo.Bar"]
    , testCase "skips blank and whitespace-only lines" do
        parseShowTargets ["", "   ", "\t", "Real.Target"] @?= ["Real.Target"]
    , testCase "returns empty list for empty input" do
        parseShowTargets [] @?= []
    ]


--------------------------------------------------------------------------------
-- collectResultCustom: <no location info> plugin load failure
--------------------------------------------------------------------------------

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
        assertBool "expected an error diagnostic"
            $ SError `elem` map (.severity) result.diagnostics
    , testCase "carries the plugin error message in the diagnostic title" do
        assertBool "expected the plugin error message in a diagnostic title"
            $ "Could not load module \8216My.Plugin\8217." `elem` map (.title) result.diagnostics
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


--------------------------------------------------------------------------------
-- collectResult: failed load with no located error
--------------------------------------------------------------------------------

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
