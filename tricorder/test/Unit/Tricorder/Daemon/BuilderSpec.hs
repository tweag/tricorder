module Unit.Tricorder.Daemon.BuilderSpec (spec_Builder) where

import Data.Default (def)
import Data.Time (UTCTime (..), addUTCTime, fromGregorian)
import Effectful (runPureEff)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (runState)
import Test.Hspec (Spec, describe, it, shouldBe, shouldSatisfy)

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Tricorder.BuildState
    ( BuildResult (..)
    , Diagnostic (..)
    , Severity (..)
    )
import Tricorder.Daemon.Builder
    ( NewLoadResult (..)
    , compileLoadResultsIntoBuildResults
    )
import Tricorder.Daemon.Dispatch
    ( BuilderState (..)
    , KnownTargetNames (..)
    , emptyBuilderState
    , fileMatchesAnyTarget
    , filterToWatchDirs
    , mergeDiagnostics
    , preserveFailureVisibility
    )
import Tricorder.Effects.GhciSession.GhciParser
    ( LoadResult (..)
    , LoadedModule (..)
    , collectResult
    , extractTitle
    , resolveKnownTargets
    )
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (WatchDirs (..))

import Tricorder.Daemon.Builder qualified as Builder


spec_Builder :: Spec
spec_Builder = do
    describe "mergeDiagnostics" testMergeDiagnostics
    describe "filterToWatchDirs" testFilterToWatchDirs
    describe "extractTitle" testExtractTitle
    describe "compileLoadResultsIntoBuildResults" testCompileLoadResultsIntoBuildResults
    describe "resolveKnownTargets" testResolveKnownTargets
    describe "fileMatchesAnyTarget" testFileMatchesAnyTarget


data StopSignal = StopSignal
    deriving stock (Show)


testCompileLoadResultsIntoBuildResults :: Spec
testCompileLoadResultsIntoBuildResults = do
    it "uses NewLoadResult's times to calculate duration" do
        let (_, r) =
                runTest
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
        r.duration `shouldBe` 10_000
    it "merges with existing results" do
        let (m, _) =
                runTest (Map.fromList [(errMsg.file, [errMsg])])
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
            `shouldBe` fromList
                [ (warnMsg.file, [warnMsg])
                , (errMsg.file, [errMsg])
                ]

    it "returns a BuildResult" do
        let (_, r) =
                runTest mempty
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
                    , duration = 10_000
                    , moduleCount = 2
                    , diagnostics = [warnMsg]
                    }
        r `shouldBe` expected
  where
    runTest acc nlr =
        let (buildResult, builderState) =
                runPureEff
                    . runReader (ProjectRoot "/")
                    . runState (emptyBuilderState {diagnosticMap = acc})
                    $ compileLoadResultsIntoBuildResults (def {Builder.watchDirs = WatchDirs ["/src"]}) nlr
        in  (builderState.diagnosticMap, buildResult)


--------------------------------------------------------------------------------
-- resolveKnownTargets tests
--------------------------------------------------------------------------------

testResolveKnownTargets :: Spec
testResolveKnownTargets = do
    it "uses :show modules as the primary source for path↔name mapping" do
        let result =
                emptyLr
                    { loadedModules =
                        Map.fromList
                            [
                                ( "/abs/src/Foo.hs"
                                , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                                )
                            ]
                    , targetNames = ["Foo"]
                    }
        resolveKnownTargets Map.empty result
            `shouldBe` Map.fromList
                [
                    ( "/abs/src/Foo.hs"
                    , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                    )
                ]

    -- Regression test for the stale-results bug. After a failed compile, the
    -- module disappears from :show modules but stays in :show targets. The
    -- prior state's entry must be carried over so the dispatcher continues to
    -- see the file as "known" and issues :reload (not :add) when the user
    -- fixes the error.
    it "carries over prior state for targets that are no longer in :show modules" do
        let prev =
                Map.fromList
                    [
                        ( "/abs/src/Foo.hs"
                        , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                        )
                    ]
            result =
                emptyLr
                    { loadedModules = Map.empty -- Foo failed to compile
                    , targetNames = ["Foo"] -- but is still a target
                    }
        resolveKnownTargets prev result `shouldBe` prev

    it "drops targets that are no longer in :show targets" do
        let prev =
                Map.fromList
                    [
                        ( "/abs/src/Foo.hs"
                        , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                        )
                    ]
            result = emptyLr {loadedModules = Map.empty, targetNames = []}
        resolveKnownTargets prev result `shouldBe` Map.empty

    -- Dropped from the path-keyed map because we have no path↔name entry;
    -- the dispatcher still handles them via 'KnownTargetNames'.
    it "drops targets that have neither a current :show modules entry nor prior state" do
        let result = emptyLr {loadedModules = Map.empty, targetNames = ["BrandNew"]}
        resolveKnownTargets Map.empty result `shouldBe` Map.empty
  where
    emptyLr =
        LoadResult
            { moduleCount = 0
            , compiledFiles = Set.empty
            , loadedModules = Map.empty
            , targetNames = []
            , diagnostics = []
            }


--------------------------------------------------------------------------------
-- fileMatchesAnyTarget tests
--------------------------------------------------------------------------------

testFileMatchesAnyTarget :: Spec
testFileMatchesAnyTarget = do
    it "matches when the path's uppercase-suffix equals a target" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "Tricorder.Version"))
            "./tricorder/src/Tricorder/Version.hs"
            `shouldBe` True

    it "matches a single-segment module" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "Main"))
            "./app/Main.hs"
            `shouldBe` True

    it "does not match when no uppercase-suffix equals a target" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "Other.Module"))
            "./tricorder/src/Tricorder/Version.hs"
            `shouldBe` False

    it "does not match a lowercase-prefix even if textually contained" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "src.Tricorder.Version"))
            "./tricorder/src/Tricorder/Version.hs"
            `shouldBe` False

    it "handles .lhs extension" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "Foo.Bar"))
            "./src/Foo/Bar.lhs"
            `shouldBe` True

    -- GHCi renders a target whose module name is ambiguous across home units
    -- (every executable/test 'Main') as its source path, e.g. "app/Main.hs".
    it "matches a path-shaped target on directory-segment boundaries" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "app/Main.hs"))
            "./tricorder/app/Main.hs"
            `shouldBe` True

    it "does not match a path-shaped target on a partial segment" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "pp/Main.hs"))
            "./tricorder/app/Main.hs"
            `shouldBe` False

    it "does not match a path-shaped target for a different file" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "daemon/Main.hs"))
            "./tricorder/app/Main.hs"
            `shouldBe` False


--------------------------------------------------------------------------------
-- mergeDiagnostics tests
--------------------------------------------------------------------------------

testMergeDiagnostics :: Spec
testMergeDiagnostics = do
    it "retains diagnostics from files not in compiledFiles" do
        -- Foo has an error, Bar has a warning.
        -- Only Foo is recompiled (and fixed). Bar is unchanged, so Bar's
        -- warning must survive.
        let prev = Map.fromList [(errMsg.file, [errMsg]), (warnMsg.file, [warnMsg])]
            result =
                LoadResult
                    { moduleCount = 2
                    , compiledFiles = Set.singleton errMsg.file
                    , loadedModules = Map.empty
                    , targetNames = []
                    , diagnostics = []
                    }
        let merged = mergeDiagnostics prev result
        Map.lookup warnMsg.file merged `shouldBe` Just [warnMsg]

    it "clears diagnostics when a recompiled file now has no issues" do
        let prev = Map.fromList [(errMsg.file, [errMsg])]
            result =
                LoadResult
                    { moduleCount = 1
                    , compiledFiles = Set.singleton errMsg.file
                    , loadedModules = Map.empty
                    , targetNames = []
                    , diagnostics = []
                    }
        let merged = mergeDiagnostics prev result
        Map.lookup errMsg.file merged `shouldBe` Nothing

    it "replaces diagnostics for recompiled files" do
        let newErr = errMsg {title = "new error", text = "new error\n"}
            prev = Map.fromList [(errMsg.file, [errMsg])]
            result =
                LoadResult
                    { moduleCount = 1
                    , compiledFiles = Set.singleton errMsg.file
                    , loadedModules = Map.empty
                    , targetNames = []
                    , diagnostics = [newErr]
                    }
        let merged = mergeDiagnostics prev result
        Map.lookup errMsg.file merged `shouldBe` Just [newErr]

    it "accumulates diagnostics for newly seen files" do
        let result =
                LoadResult
                    { moduleCount = 1
                    , compiledFiles = Set.singleton warnMsg.file
                    , loadedModules = Map.empty
                    , targetNames = []
                    , diagnostics = [warnMsg]
                    }
        let merged = mergeDiagnostics Map.empty result
        Map.lookup warnMsg.file merged `shouldBe` Just [warnMsg]

    describe "when the cycle reports none" $ it "clears a stale location-less diagnostic" do
        -- <no location info> is never in compiledFiles, so without special
        -- handling it would persist forever. A cycle with no location-less
        -- diagnostic must evict it.
        let noLoc = errMsg {file = "<no location info>"}
            prev = Map.fromList [(noLoc.file, [noLoc])]
            result =
                LoadResult
                    { moduleCount = 1
                    , compiledFiles = Set.singleton errMsg.file
                    , loadedModules = Map.empty
                    , targetNames = []
                    , diagnostics = []
                    }
        let merged = mergeDiagnostics prev result
        Map.lookup noLoc.file merged `shouldBe` Nothing

    it "refreshes a location-less diagnostic that is still present" do
        let noLoc = errMsg {file = "<no location info>"}
            prev = Map.fromList [(noLoc.file, [noLoc])]
            result =
                LoadResult
                    { moduleCount = 1
                    , compiledFiles = Set.empty
                    , loadedModules = Map.empty
                    , targetNames = []
                    , diagnostics = [noLoc]
                    }
        let merged = mergeDiagnostics prev result
        Map.lookup noLoc.file merged `shouldBe` Just [noLoc]


--------------------------------------------------------------------------------
-- filterToWatchDirs tests
--------------------------------------------------------------------------------

testFilterToWatchDirs :: Spec
testFilterToWatchDirs = do
    let root = "/project"
        watchDirs = WatchDirs ["/project/src"]

    it "keeps diagnostics under a watched directory" do
        -- ./src/Foo.hs is what toRelative produces for an absolute project file
        let d = errMsg {file = "./src/Foo.hs"}
        filterToWatchDirs root watchDirs [d] `shouldBe` [d]

    it "drops diagnostics from outside the project (e.g. Nix store .h files)" do
        let d = errMsg {file = "/nix/store/abc123/ghcautoconf.h"}
        filterToWatchDirs root watchDirs [d] `shouldBe` []

    it "drops diagnostics with mangled CPP filenames" do
        -- The ghcid parser produces "In file included from <path>" as the file
        -- field for GCC-style CPP include-chain messages.
        let d = errMsg {file = "In file included from src/Foo.hs"}
        filterToWatchDirs root watchDirs [d] `shouldBe` []

    it "drops mangled CPP filenames when watchDirs is [\".\"] (project root)" do
        -- With watchDirs=["."], the watch dir resolves to projectRoot itself.
        -- A mangled path joined onto projectRoot would incorrectly start with
        -- projectRoot+"/", so this case requires an explicit guard.
        let d = errMsg {file = "In file included from src/Foo.hs"}
        filterToWatchDirs root (WatchDirs ["."]) [d] `shouldBe` []

    it "passes everything through when watchDirs is empty" do
        let d = errMsg {file = "/nix/store/abc123/ghcautoconf.h"}
        filterToWatchDirs root (WatchDirs []) [d] `shouldBe` [d]

    it "works with the '.' fallback watch dir (whole project root)" do
        let d = errMsg {file = "./src/Foo.hs"}
            nixD = errMsg {file = "/nix/store/abc123/ghcautoconf.h"}
        filterToWatchDirs root (WatchDirs ["."]) [d, nixD] `shouldBe` [d]

    describe "when diagnostic has no path it" $ it "keeps location-less <no location info> errors" do
        -- A home-unit GHC plugin that can't load under --enable-multi-repl
        -- produces a <no location info> error. It has no path to test against a
        -- watch dir, but must survive or the failed build reads as clean.
        let d = errMsg {file = "<no location info>"}
        filterToWatchDirs root watchDirs [d] `shouldBe` [d]

    it "does not treat a real <-prefixed path as a location-less marker" do
        -- isLocationLess requires a closing '>'. A real (if exotic) path that
        -- merely starts with '<' is an ordinary out-of-watch file and must be
        -- dropped, not kept as a build-level marker.
        let d = errMsg {file = "<generated>/Foo.hs"}
        filterToWatchDirs root watchDirs [d] `shouldBe` []

    describe "when its only error is out of watch dirs" $ it "a failed load does not read as clean" do
        -- collectResult only injects its synthetic failure when no SError is
        -- present. Here GHCi Failed with a single *located* error in a file
        -- outside the watch dirs, so collectResult adds no synthetic — and then
        -- filterToWatchDirs drops the out-of-watch error, leaving nothing. The
        -- Builder pipeline composes preserveFailureVisibility after filtering to
        -- re-attach the failure, so a failed build never survives with zero
        -- diagnostics.
        let reloadOutput =
                [ "/other/Dep.hs:5:1: error: boom"
                , "Failed, 0 modules loaded."
                ]
            result = collectResult root reloadOutput [] []
            filtered = filterToWatchDirs root watchDirs result.diagnostics
        preserveFailureVisibility result.diagnostics filtered
            `shouldSatisfy` (not . null)


--------------------------------------------------------------------------------
-- extractTitle tests
--------------------------------------------------------------------------------

testExtractTitle :: Spec
testExtractTitle = do
    it "returns empty string for empty message" do
        extractTitle [] `shouldBe` ""

    -- New GHC style: header ends with [GHC-XXXXX], content on body lines.
    -- Captured from GHC 9.10.2 with -Weverything.
    it "extracts first body line for error with [GHC-XXXXX] code" do
        extractTitle
            [ "src/Tricorder/Config.hs:39:20: error: [GHC-83865]"
            , "    \8226 Couldn't match expected type 'Int' with actual type 'Bool'"
            , "    \8226 In the expression: True"
            , "      In an equation for '_deliberateError': _deliberateError = True"
            , "   |"
            , "39 | _deliberateError = True"
            , "   |                    ^^^^"
            ]
            `shouldBe` "\8226 Couldn't match expected type 'Int' with actual type 'Bool'"

    it "extracts first body line for warning with [GHC-XXXXX] [-Wfoo] codes" do
        extractTitle
            [ "src/Tricorder/Config.hs:38:26: warning: [GHC-55631] [-Wmissing-deriving-strategies]"
            , "    No deriving strategy specified. Did you want stock, newtype, or anyclass?"
            , "   |"
            , "38 | data TestWarn = TestWarn deriving (Eq)"
            , "   |                          ^^^^^^^^^^^^^"
            ]
            `shouldBe` "No deriving strategy specified. Did you want stock, newtype, or anyclass?"

    -- Old GHC style: message text is inline on the header line.
    it "extracts inline content for old-style single-line error" do
        extractTitle ["GHCi.hs:70:1: error: Parse error: naked expression at top level"]
            `shouldBe` "Parse error: naked expression at top level"

    it "extracts inline content for old-style Warning (capital W)" do
        extractTitle ["GHCi.hs:81:1: Warning: Defined but not used: \8216foo\8217"]
            `shouldBe` "Defined but not used: \8216foo\8217"

    -- Multi-line without any inline message: position-only or "Warning:" header.
    it "extracts first body line when header has position only" do
        extractTitle
            [ "GHCi.hs:72:13:"
            , "    No instance for (Num ([String] -> [String]))"
            , "      arising from the literal '1'"
            ]
            `shouldBe` "No instance for (Num ([String] -> [String]))"

    it "extracts first body line when header ends with 'Warning:'" do
        extractTitle
            [ "/src/TrieSpec.hs:(192,7)-(193,76): Warning:"
            , "    A do-notation statement discarded a result of type '[()]'"
            ]
            `shouldBe` "A do-notation statement discarded a result of type '[()]'"

    -- Source display lines (pipe/caret) must be skipped.
    it "skips source display lines when scanning body" do
        extractTitle
            [ "file.hs:1:1: error: [GHC-12345]"
            , "   |"
            , "1 | foo bar"
            , "   |     ^^^"
            , "    actual content here"
            ]
            `shouldBe` "actual content here"

    -- ANSI-escaped header (colour output): strip escapes before searching.
    it "handles ANSI-escaped headers" do
        extractTitle
            [ "\ESC[;1msrc/Types.hs:11:1: \ESC[35mwarning:\ESC[0m \ESC[35m[-Wunused-imports]\ESC[0m"
            , "    The import of 'Data.Data' is redundant"
            ]
            `shouldBe` "The import of 'Data.Data' is redundant"


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
