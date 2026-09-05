module Unit.Tricorder.Daemon.DispatchSpec (spec_Dispatch) where

import Test.Hspec (Spec, describe, it, shouldBe, shouldMatchList, shouldSatisfy)

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Tricorder.Build (Diagnostic (..), Severity (..))
import Tricorder.Daemon.Dispatch
    ( KnownTargetNames (..)
    , fileMatchesAnyTarget
    , filterToWatchDirs
    , mergeDiagnostics
    , preserveFailureVisibility
    )
import Tricorder.Daemon.GhciSession.GhciParser (LoadResult (..), collectResult)
import Tricorder.Session.WatchDirs (WatchDirs (..))


spec_Dispatch :: Spec
spec_Dispatch = do
    describe "fileMatchesAnyTarget" testFileMatchesAnyTarget
    describe "mergeDiagnostics" testMergeDiagnostics
    describe "filterToWatchDirs" testFilterToWatchDirs


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

    it "keeps diagnostics under \".\" watched directory" do
        let d = errMsg {file = "src/Foo.hs"}
        filterToWatchDirs root (WatchDirs ["."]) [d] `shouldMatchList` [d]

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
