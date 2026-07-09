module Unit.Tricorder.BuilderSpec (spec_Builder) where

import Atelier.Effects.Chan (runChan)
import Atelier.Effects.Clock (runClockConst)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Debounce (debounced, runDebounce, runDebounceNoOp)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.FileWatcher (FileEvent (..))
import Atelier.Effects.Input (runInputConst)
import Atelier.Effects.Log (runLogNoOp)
import Atelier.Effects.Monitoring.Tracing (runTracingNoOp)
import Atelier.Effects.Publishing (listen_, publish, runPubSub)
import Atelier.Time (Millisecond)
import Control.Concurrent.STM (modifyTVar', newTVarIO, readTVar, retry, writeTVar)
import Control.Exception (ErrorCall (..))
import Data.Default (def)
import Data.Time (UTCTime (..), addUTCTime, fromGregorian)
import Effectful (runEff, runPureEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Concurrent.STM (atomically)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.Error.Static (runErrorNoCallStack, throwError)
import Effectful.Exception (throwIO)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (State, evalState, get, put, runState)
import Effectful.Writer.Static.Shared (Writer, execWriter, tell)
import Test.Hspec (Spec, describe, it, shouldBe, shouldMatchList, shouldSatisfy)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Delay qualified as Delay
import Control.Concurrent.STM qualified as STM
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Tricorder.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , CabalChangeDetected (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , PostBuild (..)
    , Severity (..)
    , SourceChangeDetected (..)
    )
import Tricorder.Builder
    ( BuildConfig (..)
    , EnteringNewPhase (..)
    , GhciSessionHooks (..)
    , NewLoadResult (..)
    , compileLoadResultsIntoBuildResults
    , onRestart
    , reloadOnSourceChange
    , requestTestRunsForNewBuildResults
    , setNewPhase
    , watchSourceChanges
    )
import Tricorder.Builder.Dispatch
    ( BuilderState (..)
    , KnownTargetNames (..)
    , emptyBuilderState
    , fileMatchesAnyTarget
    , filterToWatchDirs
    , mergeDiagnostics
    , preserveFailureVisibility
    )
import Tricorder.Effects.GhciSession
    ( Controls (..)
    , LoadResult (..)
    , LoadedModule (..)
    , runGhciSessionScripted
    )
import Tricorder.Effects.GhciSession.GhciParser (collectResult, extractTitle, resolveKnownTargets)
import Tricorder.Effects.PostBuildStore (modifyPostBuild, runPostBuildCapture, runPostBuildState, runPostBuildStore)
import Tricorder.Effects.TestRunner (TestRunner (..), runTestRunnerScripted)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (TestTarget (..), WatchDirs (..), parseTarget, parseTestTargets)

import Tricorder.BuildState.Tests qualified as Test
import Tricorder.Builder qualified as Builder
import Tricorder.Effects.BuildStore qualified as BuildStore


spec_Builder :: Spec
spec_Builder = do
    describe "mergeDiagnostics" testMergeDiagnostics
    describe "filterToWatchDirs" testFilterToWatchDirs
    describe "extractTitle" testExtractTitle
    describe "compileLoadResultsIntoBuildResults" testCompileLoadResultsIntoBuildResults
    describe "requestTestRunsForNewBuildResults" testRequestTestRunsForNewBuildResults
    describe "runPostBuildStore" testPostBuildStoreFinalizer
    describe "setNewPhase" testSetNewPhase
    describe "onRestart" testOnRestart
    describe "restartOnCabalChange" testRestartOnCabalChange
    describe "buildWithGhciOnChange (startup-failure recovery)" testBuildWithGhciRecovery
    describe "reloadOnSourceChange" testReloadOnSourceChange
    describe "watchSourceChanges (event coalescing)" testEventCoalescing
    describe "interruptCurrent" testInterruptCurrent
    describe "resolveKnownTargets" testResolveKnownTargets
    describe "fileMatchesAnyTarget" testFileMatchesAnyTarget


testOnRestart :: Spec
testOnRestart = do
    it "transitions BuildStore to the Building phase" do
        (st, _) <- runTest
        st.phase `shouldBe` Building Nothing

    it "should increment the build ID" do
        (_, buildId) <- runTest
        buildId `shouldBe` BuildId 2
  where
    runTest =
        runEff
            . runConcurrent
            . runDelay
            . runLogNoOp
            . runInputConst emptyDaemonInfo
            . BuildStore.runBuildStore
            . runState (BuildId 1)
            $ do
                onRestart
                BuildStore.getState


testRestartOnCabalChange :: Spec
testRestartOnCabalChange = do
    it "restarts the supervised action when CabalChangeDetected is published" do
        countVar <- newTVarIO @Int 0

        runTest do
            Conc.scoped do
                _ <-
                    Conc.fork
                        $ Builder.restartOnCabalChange
                            (pure ())
                            (pure ())
                            ( \_ -> do
                                atomically (modifyTVar' countVar (+ 1))
                                -- Block forever; we want to verify the action is
                                -- cancelled and re-entered, not that it returns.
                                forever (Delay.wait (10 :: Millisecond))
                            )
                Delay.wait (20 :: Millisecond) -- let the first iteration land
                publish (CabalChangeDetected "foo.cabal" Modified)
                Delay.wait (50 :: Millisecond) -- let the restart land
        finalCount <- STM.atomically (readTVar countVar)
        finalCount `shouldBe` 2
  where
    runTest =
        runEff
            . runConcurrent
            . runTracingNoOp
            . runClockConst epoch
            . runChan
            . runDelay
            . runLogNoOp
            . runPubSub @CabalChangeDetected
            . runConc


-- | Regression for the startup-failure dead-end: when the build command
-- fails to start, 'buildWithGhciOnChange' must surface 'BuildFailed' and then
-- stay able to retry once a source file changes. The original code parked on
-- 'atomically retry' after 'BuildFailed', so it could only ever recover via a
-- *cabal* change (runBuilder cancelling its scope) — a source edit that
-- fixed the underlying problem was ignored and the daemon stayed stuck.
testBuildWithGhciRecovery :: Spec
testBuildWithGhciRecovery = do
    it "retries the build on a source change after a startup failure" do
        phases <-
            runTest
                completeBuildState
                -- First launch throws (startup failure); the retry succeeds.
                [ Left (toException (ErrorCall "ghci failed to start"))
                , Right successLoad
                ]
                do
                    Conc.scoped do
                        Conc.fork_ (Builder.buildWithGhciOnChange (def @BuildConfig))
                        Delay.wait (40 :: Millisecond) -- let the first launch fail + subscribe
                        publish (SourceChangeDetected "/abs/path/Foo.hs" Modified)
                        Delay.wait (60 :: Millisecond) -- let the retry land
                        -- The failed launch reports BuildFailed exactly once.
        length [() | EnteringNewPhase _ (BuildFailed _) <- phases] `shouldBe` 1
        -- The source change drove a second, successful launch to completion.
        -- With the bug the builder is parked, so no Done is ever emitted.
        length [() | EnteringNewPhase _ (BuildComplete _ _) <- phases] `shouldSatisfy` (>= 1)
  where
    successLoad =
        LoadResult
            { moduleCount = 1
            , compiledFiles = Set.empty
            , loadedModules = Map.empty
            , targetNames = []
            , diagnostics = []
            }

    runTest initialState script =
        runEff
            . runConcurrent
            . runTracingNoOp
            . runClockConst epoch
            . runChan
            . runDelay
            . runReader (ProjectRoot "/")
            . evalState (BuildId 1)
            . evalState emptyBuilderState
            . evalState initialState
            . runLogNoOp
            . execWriter @[EnteringNewPhase]
            . runBuildStoreCapture
            . runTestRunnerScripted []
            . runGhciSessionScripted script
            . runPubSub @SourceChangeDetected
            . runConc
            . runDebounceNoOp


--------------------------------------------------------------------------------
-- Effect stack for integration tests
--------------------------------------------------------------------------------

data StopSignal = StopSignal
    deriving stock (Show)


testReloadOnSourceChange :: Spec
testReloadOnSourceChange = do
    describe "Modified" do
        describe "when the file is loaded in GHCi" do
            it "transitions through Building then Done" do
                phases <- runTest knownFoo noTargets distinctCtrls (SourceChangeDetected "/abs/path/Foo.hs" Modified)
                phases `shouldBe` flow reloadLr

            it "calls controls.reload" do
                phases <- runTest knownFoo noTargets distinctCtrls (SourceChangeDetected "/abs/path/Foo.hs" Modified)
                buildResultsFrom phases `shouldMatchList` [resultFor reloadLr]

        describe "when the file is not loaded in GHCi" do
            it "calls controls.add (the editor just wrote a new file)" do
                phases <- runTest Map.empty noTargets distinctCtrls (SourceChangeDetected "/abs/path/New.hs" Modified)
                buildResultsFrom phases `shouldMatchList` [resultFor addLr]

        -- Regression test for stale-diagnostics bug: cold-start with a
        -- pre-existing error then fix it. Foo is in :show targets but
        -- not :show modules, so dispatch must consult KnownTargetNames to
        -- avoid issuing a no-op :add.
        describe "when the file is a known target that failed on initial load" do
            it "calls controls.reload, not controls.add" do
                phases <-
                    runTest
                        Map.empty
                        (KnownTargetNames (Set.singleton "Foo"))
                        distinctCtrls
                        (SourceChangeDetected "/abs/src/Foo.hs" Modified)
                buildResultsFrom phases `shouldMatchList` [resultFor reloadLr]

        -- A failed executable 'Main' appears in :show targets only as its
        -- path ("app/Main.hs", since the name 'Main' is ambiguous across home
        -- units), so dispatch must match that path form to Reload, not :add.
        describe "when the file is a path-shaped target that failed on initial load" do
            it "calls controls.reload, not controls.add" do
                phases <-
                    runTest
                        Map.empty
                        (KnownTargetNames (Set.singleton "app/Main.hs"))
                        distinctCtrls
                        (SourceChangeDetected "/abs/app/Main.hs" Modified)
                buildResultsFrom phases `shouldMatchList` [resultFor reloadLr]

    describe "Added" do
        describe "when the file is not loaded" $ it "calls controls.add" do
            phases <- runTest Map.empty noTargets distinctCtrls (SourceChangeDetected "/abs/path/Foo.hs" Added)
            buildResultsFrom phases `shouldMatchList` [resultFor addLr]

        describe "when the file is already loaded" $ it "calls controls.reload (re-add is a reload)" do
            phases <- runTest knownFoo noTargets distinctCtrls (SourceChangeDetected "/abs/path/Foo.hs" Added)
            buildResultsFrom phases `shouldMatchList` [resultFor reloadLr]

    describe "Removed" do
        describe "when the file is loaded" $ it "calls controls.unadd" do
            phases <- runTest knownFoo noTargets distinctCtrls (SourceChangeDetected "/abs/path/Foo.hs" Removed)
            buildResultsFrom phases `shouldMatchList` [resultFor unaddLr]

        describe "when the file is not loaded" $ it "is a no-op" do
            phases <- runTest Map.empty noTargets distinctCtrls (SourceChangeDetected "/abs/path/Unknown.hs" Removed)
            phases `shouldBe` []

    describe "when the reload throws (e.g. interrupted mid-flight)" do
        it "resolves to BuildFailed instead of stranding the UI in Building" do
            phases <- runTest knownFoo noTargets throwingCtrls (SourceChangeDetected "/abs/path/Foo.hs" Modified)
            -- Regression: a reload that errors must resolve the build, not
            -- leave 'Building' as the terminal phase (the daemon would be
            -- stuck until the next change happened to succeed).
            viaNonEmpty last [p | EnteringNewPhase _ p <- phases]
                `shouldSatisfy` \case
                    Just (BuildFailed _) -> True
                    _ -> False
  where
    runTest initialModuleMap initialTargets ctrls event =
        runEff
            . runConcurrent
            . runClockConst epoch
            . runReader (ProjectRoot "/")
            . evalState (BuildId 1)
            . evalState
                emptyBuilderState
                    { loadedModules = initialModuleMap
                    , knownTargets = initialTargets
                    }
            . evalState completeBuildState
            . runLogNoOp
            . execWriter @[EnteringNewPhase]
            . runBuildStoreCapture
            . runTestRunnerScripted []
            $ reloadOnSourceChange (def @BuildConfig) ctrls event

    flow lr =
        [ EnteringNewPhase (BuildId 1) $ Building Nothing
        , EnteringNewPhase (BuildId 1) $ BuildComplete (resultFor lr) $ PostBuild $ Test.Suites mempty
        ]

    buildResultsFrom phases = [r | EnteringNewPhase _ (BuildComplete r _) <- phases]

    resultFor lr =
        BuildResult
            { completedAt = epoch
            , duration = 0
            , moduleCount = lr.moduleCount
            , diagnostics = []
            }

    noTargets = KnownTargetNames Set.empty

    distinctCtrls =
        Controls
            { reload = pure reloadLr
            , interrupt = pure ()
            , add = \_ -> pure addLr
            , unadd = \_ -> pure unaddLr
            }

    -- A reload that throws, as if SIGINT'd by a second rapid source change.
    throwingCtrls = distinctCtrls {reload = throwIO (ErrorCall "reload interrupted")}

    knownFoo =
        Map.fromList
            [
                ( "/abs/path/Foo.hs"
                , LoadedModule {relPath = "./src/Foo.hs", moduleName = "MyModule"}
                )
            ]

    -- Distinct LoadResults so tests can identify which control was invoked.
    mkLr :: Int -> LoadResult
    mkLr n =
        LoadResult
            { moduleCount = n
            , compiledFiles = Set.singleton errMsg.file
            , loadedModules = Map.empty
            , targetNames = []
            , diagnostics = []
            }
    reloadLr = mkLr 10
    addLr = mkLr 20
    unaddLr = mkLr 30


testSetNewPhase :: Spec
testSetNewPhase = do
    it "should set build phase" do
        state <- runEff
            . runConcurrent
            . runDelay
            . runInputConst emptyDaemonInfo
            . BuildStore.runBuildStore
            $ do
                setNewPhase $ EnteringNewPhase (BuildId 1) (Building Nothing)
                BuildStore.getState
        state
            `shouldBe` BuildState
                { buildId = BuildId 1
                , phase = Building Nothing
                , daemonInfo = emptyDaemonInfo
                }


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


testRequestTestRunsForNewBuildResults :: Spec
testRequestTestRunsForNewBuildResults = do
    it "should emit EnteringNewPhase events for each test target" do
        phases <-
            runTest
                (parseTestTargets ["test:foo", "test:bar"])
                [ Right suiteCompleted
                , Right suiteCompleted
                ]
        length phases `shouldBe` 3
        let expectedPhases =
                [ postBuildWithTests
                    $ [ (mkTestTarget "test:foo", Test.SuiteRunning Nothing)
                      , (mkTestTarget "test:bar", Test.SuiteRunning Nothing)
                      ]
                , postBuildWithTests
                    $ [ (mkTestTarget "test:foo", suiteCompleted)
                      , (mkTestTarget "test:bar", Test.SuiteRunning Nothing)
                      ]
                , postBuildWithTests
                    $ [ (mkTestTarget "test:foo", suiteCompleted)
                      , (mkTestTarget "test:bar", suiteCompleted)
                      ]
                ]
        phases `shouldMatchList` expectedPhases

    -- Regression for the abort handling in 'runTestsIfClean': when an
    -- interrupt arrives mid-run loop, 'isAborted' becomes True and the loop
    -- returns 'Aborted'. The caller MUST then skip updating the 'PostBuild'
    -- — otherwise the BuildStore briefly publishes a BuildComplete
    -- with a partial 'Test.Suites', and a 'status --wait' caller reads that
    -- stale result before the new cycle starts.
    it "does not transition to BuildComplete when the run is aborted mid-flight" do
        phases <-
            runEff
                . runConcurrent
                . runLogNoOp
                . evalState (PostBuild $ Test.Suites mempty)
                . execWriter @[PostBuild]
                . runPostBuildState
                . runPostBuildCapture
                . runTestRunnerAbortAfterFirst suiteCompleted
                $ requestTestRunsForNewBuildResults
                $ parseTestTargets ["test:foo", "test:bar"]
        phases
            `shouldMatchList` [ PostBuild
                                    $ Test.Suites
                                    $ Map.fromList
                                        [ (mkTestTarget "test:bar", Test.SuiteRunning Nothing)
                                        , (mkTestTarget "test:foo", Test.SuiteRunning Nothing)
                                        ]
                              ]
  where
    runTest testTargets script =
        runEff
            . runConcurrent
            . runLogNoOp
            . evalState (PostBuild $ Test.Suites mempty)
            . execWriter @[PostBuild]
            . runPostBuildState
            . runPostBuildCapture
            . runTestRunnerScripted script
            $ requestTestRunsForNewBuildResults testTargets

    postBuildWithTests = PostBuild . Test.Suites . Map.fromList

    suiteCompleted =
        Test.SuiteCompleted
            $ Test.SuiteCompletion
                { passed = True
                , output = ""
                , testCases = []
                , duration = Nothing
                }


-- | [regression] A @.cabal@ change can fire while a post-build cycle is
-- finishing. The restart coordinator ('restartOnCabalChange' -> 'preRestart')
-- runs on a /separate/ fiber and flips the shared phase to 'Restarting'; it
-- does NOT latch the test-runner abort flag, so the post-build action on the
-- worker fiber runs to completion unaware of it.
--
-- 'runPostBuildStore' must leave that fresh 'Restarting' phase alone. Its
-- finalizer instead re-reads the phase, sees it is not 'BuildComplete', and
-- force-writes a stale empty 'BuildComplete' carrying the old build result.
-- That reads as "done" ('anyRunningTests' is False for empty suites), so
-- 'isBuilding' flips to False and a 'status --wait' caller wakes on the
-- previous build's result while a restart is actually in flight.
--
-- This drives the production 'runPostBuildStore' (via the stateful
-- 'runBuildStoreCapture', whose 'getState' the finalizer reads) — unlike the
-- abort test above, which runs under 'runPostBuildState' and never exercises
-- the finalizer.
testPostBuildStoreFinalizer :: Spec
testPostBuildStoreFinalizer =
    it "does not clobber a concurrently-set Restarting phase in its finalizer" do
        (_, finalState) <-
            runEff
                . runState initialState
                . execWriter @[EnteringNewPhase]
                . runBuildStoreCapture
                . runPostBuildStore buildResult
                $ do
                    -- afterLoad publishes the running suites on every clean
                    -- build with test targets, so the phase is BuildComplete
                    -- at this point...
                    modifyPostBuild \pb -> pb {testSuites = runningSuites}
                    -- ...and then a concurrent .cabal restart flips it to
                    -- Restarting just before this action returns.
                    BuildStore.setPhase (BuildId 1) Restarting
        finalState.phase `shouldBe` Restarting
  where
    initialState =
        BuildState
            { buildId = BuildId 1
            , phase = Building Nothing
            , daemonInfo = emptyDaemonInfo
            }

    buildResult =
        BuildResult
            { completedAt = epoch
            , duration = 0
            , moduleCount = 1
            , diagnostics = []
            }

    runningSuites =
        Test.Suites $ Map.fromList [(mkTestTarget "test:foo", Test.SuiteRunning Nothing)]


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
mkTestTarget = TestTarget . parseTarget


--------------------------------------------------------------------------------
-- Event coalescing (watchSourceChanges)
--
-- Regression for the parallel-cycles bug. When source-change events arrive
-- more than 200ms apart, debounce fires each callback separately. While one
-- cycle is in flight, the rest must collapse into AT MOST ONE trailing cycle
-- rather than queueing N back-to-back cycles — otherwise a 'status --wait'
-- caller wouldn't see "Done" until the last queued cycle finished. This
-- mirrors the single-slot register + single-worker pattern that
-- 'watchSourceChanges' uses to coalesce a burst into one trailing reload.
--------------------------------------------------------------------------------

testEventCoalescing :: Spec
testEventCoalescing = do
    -- Whenever 'interruptCurrent' cannot drop the in-flight cycle promptly
    -- (e.g. a 'status --wait' caller has registered as a waiter, gating
    -- 'interruptCurrent' to a no-op), additional source-change events would
    -- previously each queue their own follow-up cycle.
    -- N touches spaced wider than the 200ms debounce window therefore
    -- produced N back-to-back cycles after the in-flight one finished — and
    -- a 'status --wait' caller wouldn't see "Done" until the last queued
    -- cycle completed.
    --
    -- Desired behaviour: while a cycle is in flight, additional source
    -- changes coalesce into AT MOST ONE trailing cycle, regardless of how
    -- many events arrived. This mirrors the single-slot register +
    -- single-worker pattern that 'watchSourceChanges' uses.
    it "coalesces source-change events into one follow-up cycle while busy" do
        cycleRunsRef <- newTVarIO (0 :: Int)
        releaseFirst <- STM.newEmptyTMVarIO @()
        isFirstRef <- newTVarIO True
        let onEvent _ = do
                atomically (modifyTVar' cycleRunsRef (+ 1))
                -- The first invocation blocks until released, simulating
                -- the in-flight cycle. Subsequent invocations return
                -- immediately.
                wasFirst <- atomically (STM.swapTVar isFirstRef False)
                when wasFirst $ atomically (STM.takeTMVar releaseFirst)
        result <-
            runEff
                . runConcurrent
                . runTracingNoOp
                . runClockConst epoch
                . runChan
                . runDelay
                . runPubSub @SourceChangeDetected
                . runErrorNoCallStack @StopSignal
                . runConc
                . runDebounce @Text
                $ do
                    pending <- atomically (STM.newTVar @(Maybe SourceChangeDetected) Nothing)
                    Conc.scoped do
                        -- Listener: debounce + write the latest event into
                        -- the single-slot register.
                        Conc.fork_
                            $ listen_ \(ev :: SourceChangeDetected) ->
                                debounced
                                    (200 :: Millisecond)
                                    ("source_change_reloader" :: Text)
                                    (atomically (writeTVar pending (Just ev)))
                        -- Worker: drain the register, run the action.
                        -- Bursts of events that arrive while 'onEvent' is in
                        -- flight overwrite the slot, so the worker sees only
                        -- the most recent one.
                        Conc.fork_ $ forever do
                            ev <- atomically do
                                readTVar pending >>= \case
                                    Nothing -> retry
                                    Just e -> writeTVar pending Nothing >> pure e
                            onEvent ev
                        -- Let the listener's 'dupChan' subscribe before we
                        -- start publishing — otherwise the first event is
                        -- dropped because no subscriber sees it.
                        Delay.wait (50 :: Millisecond)
                        -- Four events spaced wider than 200ms so the
                        -- debounce window does NOT collapse them by itself.
                        -- The first becomes the in-flight cycle; the rest
                        -- must collapse into ONE trailing invocation.
                        publish (SourceChangeDetected "/x" Modified)
                        Delay.wait (250 :: Millisecond)
                        publish (SourceChangeDetected "/y" Modified)
                        Delay.wait (250 :: Millisecond)
                        publish (SourceChangeDetected "/z" Modified)
                        Delay.wait (250 :: Millisecond)
                        publish (SourceChangeDetected "/w" Modified)
                        -- Let the last debounce window expire so the latest
                        -- event lands in the slot.
                        Delay.wait (300 :: Millisecond)
                        -- Release the in-flight cycle; the slot drains and
                        -- the trailing cycle runs.
                        atomically (STM.putTMVar releaseFirst ())
                        Delay.wait (300 :: Millisecond)
                        throwError StopSignal
        case result of
            Left StopSignal -> pure ()
            Right () -> pure ()
        runs <- STM.atomically (readTVar cycleRunsRef)
        -- 1 in-flight + 1 coalesced trailing = 2.
        runs `shouldBe` 2

    -- Same scenario, but driving the REAL 'watchSourceChanges' rather than a
    -- hand-rolled mirror of its coalescing pattern. A 'status --wait' caller is
    -- registered (hasWaiters = True), so 'interruptCurrent' is a no-op and the
    -- in-flight cycle cannot be dropped. Four source changes arrive spaced wider
    -- than the 200ms debounce window while the first cycle is still running;
    -- they must collapse into AT MOST ONE trailing cycle.
    it "coalesces through watchSourceChanges while a waiter gates interruptCurrent" do
        cycleRunsRef <- newTVarIO (0 :: Int)
        releaseFirst <- STM.newEmptyTMVarIO @()
        isFirstRef <- newTVarIO True
        let blockingHooks =
                GhciSessionHooks
                    { onStart = pure ()
                    , onInitialLoad = \_ _ -> pure ()
                    , onStartupFail = \_ -> pure ()
                    , onSourceChange = \_ _ _ -> do
                        atomically (modifyTVar' cycleRunsRef (+ 1))
                        -- The first cycle blocks (simulating an uninterruptible
                        -- in-flight build); later cycles return immediately.
                        wasFirst <- atomically (STM.swapTVar isFirstRef False)
                        when wasFirst $ atomically (STM.takeTMVar releaseFirst)
                    }
            -- interruptCurrent is gated to a no-op by the waiter, so these are
            -- never invoked; wrap the bottoms in 'pure' (Controls is StrictData).
            noopCtrls =
                Controls
                    { reload = pure (error "watchSourceChanges test must not reload")
                    , interrupt = pure ()
                    , add = \_ -> pure (error "watchSourceChanges test must not add")
                    , unadd = \_ -> pure (error "watchSourceChanges test must not unadd")
                    }
        result <-
            runEff
                . runConcurrent
                . runTracingNoOp
                . runClockConst epoch
                . runChan
                . runDelay
                . evalState (BuildId 1)
                . runLogNoOp
                . runBuildStoreWaiterPresent
                . runTestRunnerScripted []
                . runPubSub @SourceChangeDetected
                . runErrorNoCallStack @StopSignal
                . runConc
                . runDebounce @Text
                $ Conc.scoped do
                    Conc.fork_ (watchSourceChanges blockingHooks (def @BuildConfig) noopCtrls)
                    -- Let the listener subscribe before publishing.
                    Delay.wait (50 :: Millisecond)
                    -- Four events spaced wider than the 200ms debounce window,
                    -- so debounce fires each callback separately. The first is
                    -- the in-flight cycle; the rest must coalesce into one.
                    publish (SourceChangeDetected "/x" Modified)
                    Delay.wait (250 :: Millisecond)
                    publish (SourceChangeDetected "/y" Modified)
                    Delay.wait (250 :: Millisecond)
                    publish (SourceChangeDetected "/z" Modified)
                    Delay.wait (250 :: Millisecond)
                    publish (SourceChangeDetected "/w" Modified)
                    Delay.wait (300 :: Millisecond)
                    -- Release the in-flight cycle; the trailing cycle drains.
                    atomically (STM.putTMVar releaseFirst ())
                    Delay.wait (300 :: Millisecond)
                    throwError StopSignal
        case result of
            Left StopSignal -> pure ()
            Right () -> pure ()
        runs <- STM.atomically (readTVar cycleRunsRef)
        -- 1 in-flight + 1 coalesced trailing = 2. Without the single-slot
        -- coalescing, each debounced event spawns its own cycle → 4.
        runs `shouldBe` 2

    -- The single worker also guarantees build/test cycles run STRICTLY ONE AT
    -- A TIME: 'onSourceChange' (the real reload → Testing → Done pipeline) is
    -- driven by a single fork draining the register, so a slow cycle blocks the
    -- next until it finishes. That serialization is what keeps phase writes from
    -- interleaving — two cycles racing their Building/Testing/Done transitions is
    -- how the daemon strands on a non-terminal phase (the "stuck Building" class
    -- of failure).
    --
    -- Here each cycle takes 400ms; events arrive 250ms apart (wider than the
    -- 200ms debounce, so each fires its own callback). With serialization at
    -- most one cycle is ever in flight. Without it, later callbacks start while
    -- an earlier cycle is still running.
    it "runs at most one build cycle at a time (no interleaved cycles)" do
        activeRef <- newTVarIO (0 :: Int)
        maxConcurrentRef <- newTVarIO (0 :: Int)
        let recordingHooks =
                GhciSessionHooks
                    { onStart = pure ()
                    , onInitialLoad = \_ _ -> pure ()
                    , onStartupFail = \_ -> pure ()
                    , onSourceChange = \_ _ _ -> do
                        atomically do
                            n <- (+ 1) <$> readTVar activeRef
                            writeTVar activeRef n
                            modifyTVar' maxConcurrentRef (max n)
                        -- Simulate a cycle that takes longer than the gap
                        -- between events, so overlap is observable if cycles
                        -- are not serialized.
                        Delay.wait (400 :: Millisecond)
                        atomically (modifyTVar' activeRef (subtract 1))
                    }
            noopCtrls =
                Controls
                    { reload = pure (error "serialization test must not reload")
                    , interrupt = pure ()
                    , add = \_ -> pure (error "serialization test must not add")
                    , unadd = \_ -> pure (error "serialization test must not unadd")
                    }
        result <-
            runEff
                . runConcurrent
                . runTracingNoOp
                . runClockConst epoch
                . runChan
                . runDelay
                . evalState (BuildId 1)
                . runLogNoOp
                . runBuildStoreWaiterPresent
                . runTestRunnerScripted []
                . runPubSub @SourceChangeDetected
                . runErrorNoCallStack @StopSignal
                . runConc
                . runDebounce @Text
                $ Conc.scoped do
                    Conc.fork_ (watchSourceChanges recordingHooks (def @BuildConfig) noopCtrls)
                    Delay.wait (50 :: Millisecond)
                    publish (SourceChangeDetected "/x" Modified)
                    Delay.wait (250 :: Millisecond)
                    publish (SourceChangeDetected "/y" Modified)
                    Delay.wait (250 :: Millisecond)
                    publish (SourceChangeDetected "/z" Modified)
                    -- Let every cycle finish before stopping.
                    Delay.wait (900 :: Millisecond)
                    throwError StopSignal
        case result of
            Left StopSignal -> pure ()
            Right () -> pure ()
        maxConcurrent <- STM.atomically (readTVar maxConcurrentRef)
        -- The single-worker design keeps this at 1. Running each debounced
        -- event in its own fork lets cycles overlap → 2 (or more).
        maxConcurrent `shouldBe` 1


-- | A 'BuildStore' interpreter that reports a waiter is present, so
-- 'interruptCurrent' short-circuits. Only 'HasWaiters' is reachable from the
-- 'watchSourceChanges' coalescing path; the rest are trapped.
runBuildStoreWaiterPresent
    :: Eff (BuildStore.BuildStore : es) a -> Eff es a
runBuildStoreWaiterPresent = interpret_ \case
    BuildStore.HasWaiters -> pure True
    BuildStore.SetPhase _ _ -> error "runBuildStoreWaiterPresent: SetPhase unsupported"
    BuildStore.MarkDirty _ -> error "runBuildStoreWaiterPresent: MarkDirty unsupported"
    BuildStore.GetState -> error "runBuildStoreWaiterPresent: GetState unsupported"
    BuildStore.ModifyPhase _ -> error "runBuildStoreWaiterPresent: ModifyPhase unsupported"
    BuildStore.WaitUntilDone -> error "runBuildStoreWaiterPresent: WaitUntilDone unsupported"
    BuildStore.WaitForNext _ -> error "runBuildStoreWaiterPresent: WaitForNext unsupported"
    BuildStore.WaitForAnyChange _ -> error "runBuildStoreWaiterPresent: WaitForAnyChange unsupported"
    BuildStore.WaitDirty -> error "runBuildStoreWaiterPresent: WaitDirty unsupported"


-- | Pins down the abort path on every source change: when no 'status --wait'
-- caller is holding the build, 'interruptCurrent' must drive both
-- 'controls.interrupt' (which terminates the in-flight GHCi command) and
-- 'TestRunner.interruptCurrent' (which terminates the in-flight test
-- process). When a waiter IS present, both are suppressed so the waiter
-- gets the result it's blocked on rather than a half-cancelled cycle.
testInterruptCurrent :: Spec
testInterruptCurrent = do
    it "drives controls.interrupt and TestRunner.interruptCurrent when no waiter" do
        (ctrls, testRun) <- runInterruptCurrent False
        ctrls `shouldBe` 1
        testRun `shouldBe` 1

    it "suppresses both interrupts when a waiter is present" do
        (ctrls, testRun) <- runInterruptCurrent True
        ctrls `shouldBe` 0
        testRun `shouldBe` 0
  where
    runInterruptCurrent waiterPresent = do
        ctrlsCalled <- newTVarIO (0 :: Int)
        trCalled <- newTVarIO (0 :: Int)
        -- Wrap the unused fields in 'pure' so the 'error' is the Eff
        -- \*action*, not the field value — Controls uses StrictData, which
        -- would otherwise force the bottoms when the record is constructed.
        let mockCtrls =
                Controls
                    { reload = pure (error "interruptCurrent must not call reload")
                    , interrupt = atomically (modifyTVar' ctrlsCalled (+ 1))
                    , add = \_ -> pure (error "interruptCurrent must not call add")
                    , unadd = \_ -> pure (error "interruptCurrent must not call unadd")
                    }
        runEff
            . runConcurrent
            . runLogNoOp
            . runHasWaitersConst waiterPresent
            . runTestRunnerInterruptCounter trCalled
            $ Builder.interruptCurrent mockCtrls
        (,)
            <$> STM.atomically (readTVar ctrlsCalled)
            <*> STM.atomically (readTVar trCalled)

    -- 'interruptCurrent' only calls 'hasWaiters' on the BuildStore — every
    -- other op is unreachable from this code path, so we trap them.
    runHasWaitersConst
        :: Bool
        -> Eff (BuildStore.BuildStore : es) a
        -> Eff es a
    runHasWaitersConst hasWaiters = interpret_ \case
        BuildStore.HasWaiters -> pure hasWaiters
        BuildStore.SetPhase _ _ -> error "interruptCurrent must not setPhase"
        BuildStore.MarkDirty _ -> error "interruptCurrent must not markDirty"
        BuildStore.GetState -> error "interruptCurrent must not getState"
        BuildStore.ModifyPhase _ -> error "interruptCurrent must not modifyPhase"
        BuildStore.WaitUntilDone -> error "interruptCurrent must not waitUntilDone"
        BuildStore.WaitForNext _ -> error "interruptCurrent must not waitForNext"
        BuildStore.WaitForAnyChange _ -> error "interruptCurrent must not waitForAnyChange"
        BuildStore.WaitDirty -> error "interruptCurrent must not waitDirty"

    -- Counts 'InterruptCurrent' invocations; the other ops are unreachable
    -- from 'Builder.interruptCurrent'.
    runTestRunnerInterruptCounter
        :: (Concurrent :> es)
        => STM.TVar Int
        -> Eff (TestRunner : es) a
        -> Eff es a
    runTestRunnerInterruptCounter counter = interpret_ \case
        InterruptCurrent -> atomically (modifyTVar' counter (+ 1))
        RunTestSuite _ -> error "Builder.interruptCurrent must not runTestSuite"
        ResetAbort -> error "Builder.interruptCurrent must not resetAbort"
        IsAborted -> error "Builder.interruptCurrent must not isAborted"


-- | A 'TestRunner' interpreter that returns the same result for every
-- 'RunTestSuite' call, but latches 'IsAborted' to True after the first one
-- — simulating an external interrupt that arrives between two test suites.
runTestRunnerAbortAfterFirst
    :: (Concurrent :> es)
    => Test.Suite -> Eff (TestRunner : es) a -> Eff es a
runTestRunnerAbortAfterFirst result act = do
    callCountRef <- atomically (STM.newTVar (0 :: Int))
    abortedRef <- atomically (STM.newTVar False)
    interpret_
        ( \case
            RunTestSuite _ -> do
                n <- atomically do
                    modifyTVar' callCountRef (+ 1)
                    readTVar callCountRef
                when (n == 1) $ atomically (writeTVar abortedRef True)
                pure result
            InterruptCurrent -> atomically (writeTVar abortedRef True)
            ResetAbort -> atomically (writeTVar abortedRef False)
            IsAborted -> atomically (readTVar abortedRef)
        )
        act


completeBuildState :: BuildState
completeBuildState =
    BuildState
        { buildId = BuildId 1
        , phase =
            BuildComplete
                ( BuildResult
                    { completedAt = epoch
                    , duration = 0
                    , moduleCount = 1
                    , diagnostics = []
                    }
                )
                $ PostBuild
                $ Test.Suites mempty
        , daemonInfo = emptyDaemonInfo
        }


-- | A 'BuildStore' interpreter that records every phase transition into a
-- 'Writer'. Captures both 'SetPhase' (used by 'enterPhase') and 'ModifyPhase'
-- (used by 'withPostBuildPhase' for BuildComplete transitions).
runBuildStoreCapture
    :: (State BuildState :> es, Writer [EnteringNewPhase] :> es)
    => Eff (BuildStore.BuildStore : es) a -> Eff es a
runBuildStoreCapture = interpret_ \case
    BuildStore.SetPhase bid phase -> do
        tell [EnteringNewPhase bid phase]
        put
            BuildState
                { buildId = bid
                , phase
                , daemonInfo = emptyDaemonInfo
                }
    BuildStore.HasWaiters -> pure False
    BuildStore.MarkDirty _ -> pure ()
    BuildStore.GetState -> get
    BuildStore.ModifyPhase f -> do
        curr <- get
        let new = f curr
        tell [EnteringNewPhase curr.buildId new]
        put $ curr {phase = new}
    BuildStore.WaitUntilDone -> get
    BuildStore.WaitForNext _ -> get
    BuildStore.WaitForAnyChange _ -> get
    BuildStore.WaitDirty -> error "runBuildStoreCapture: WaitDirty unsupported"
