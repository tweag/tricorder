module Tricorder.Builder
    ( component
    , BuildConfig (..)

      -- * Internals exposed for testing
    , NewLoadResult (..)
    , EnteringNewPhase (..)
    , GhciSessionHooks (..)
    , compileLoadResultsIntoBuildResults
    , requestTestRunsForNewBuildResults
    , buildWithGhciOnChange
    , watchSourceChanges
    , interruptCurrent
    , onRestart
    , reloadOnSourceChange
    , setNewPhase
    , restartOnCabalChange
    ) where

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.Clock (Clock, UTCTime)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Debounce (Debounce, debounced)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Publishing (Sub)
import Atelier.Time (Millisecond, nominalDiffTime)
import Control.Concurrent.STM (check, readTVar, retry, writeTVar)
import Data.Default (Default (..))
import Data.Time (diffUTCTime)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically, newTVar)
import Effectful.Exception (finally, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, get, modify, put, state)
import System.FilePath (normalise)

import Atelier.Effects.Clock qualified as Clock
import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Publishing qualified as Sub
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Tricorder.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildResult (..)
    , CabalChangeDetected (..)
    , Diagnostic (..)
    , PostBuild (..)
    , Severity (..)
    , SourceChangeDetected (..)
    )
import Tricorder.Builder.Dispatch
    ( BuilderState (..)
    , DispatchAction (..)
    , KnownTargetNames (..)
    , dispatch
    , emptyBuilderState
    , filterToWatchDirs
    , mergeDiagnostics
    , preserveFailureVisibility
    )
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.GhciSession (GhciSession, LoadResult (..))
import Tricorder.Effects.GhciSession.GhciParser (resolveKnownTargets)
import Tricorder.Effects.GhciSession.GhciProcess (GhciProcessError (..))
import Tricorder.Effects.PostBuildStore (PostBuildStore, runPostBuildStore)
import Tricorder.Effects.SessionStore (SessionStore)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session
    ( Command (..)
    , Session (..)
    , Target
    , TestTargets
    , WatchDirs
    , getTestTargets
    , renderTestTarget
    )

import Tricorder.BuildState.Test qualified as Test
import Tricorder.Effects.BuildStore qualified as BuildStore
import Tricorder.Effects.GhciSession qualified as GhciSession
import Tricorder.Effects.PostBuildStore qualified as PostBuild
import Tricorder.Effects.SessionStore qualified as SessionStore
import Tricorder.Effects.TestRunner qualified as TestRunner


-- | Builder component.
-- Starts a GHCi session, performs an initial load, then listens for changes
-- from the watcher.
component
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , GhciSession :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub CabalChangeDetected :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => Component es
component =
    defaultComponent
        { name = "Builder"
        , listeners = pure [runBuilder defaultGhciSessionHooks]
        }


-- | A subset of 'Session' with just the properties that 'Builder' cares about.
data BuildConfig = BuildConfig
    { command :: Command
    , targets :: [Target]
    , testTargets :: TestTargets
    , watchDirs :: WatchDirs
    }
    deriving stock (Eq)


instance Default BuildConfig where
    def =
        BuildConfig
            { command = session.command
            , targets = session.targets
            , testTargets = session.testTargets
            , watchDirs = session.watchDirs
            }
      where
        session = def @Session


--------------------------------------------------------------------------------
-- Level 1 — Builder lifecycle: supervise the tricorder session
--------------------------------------------------------------------------------

-- | Level 1 — supervise the /tricorder session/ (the project config). For the
-- current config, run successive GHCi sessions; whenever a @.cabal@ file
-- changes, reload the config and restart everything.
--
-- Cabal-change events flip a TVar; 'restartOnCabalChange' consumes the flag,
-- runs @preRestart@ (transition to 'Restarting', reload the config),
-- then exits the inner scope which cancels the in-flight GHCi session. The next
-- iteration reloads the config via 'loadBuildConfig' and forks a fresh
-- 'runGhciSessions'.
runBuilder
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , GhciSession :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub CabalChangeDetected :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => GhciSessionHooks es
    -> Eff es Void
runBuilder hooks =
    restartOnCabalChange preRestart loadBuildConfig session
  where
    -- The tricorder session's restart hook: the outer loop reloading *its own*
    -- config. This is not a GHCi-session concern, so it lives here rather than
    -- in 'GhciSessionHooks'.
    preRestart = do
        -- Flip the UI to 'Restarting' immediately so the user sees the change
        -- has been picked up before scope teardown (which kills cabal repl and
        -- waits for graceful exit).
        enterPhase Restarting
        -- Pick up cabal/package.yaml edits before the next iteration.
        SessionStore.rawReload

    session config = runGhciSessions hooks config `finally` onRestart


-- | Read the current tricorder 'Session' and project the parts the Builder
-- cares about. Runs at the start of each restart iteration.
loadBuildConfig
    :: ( Log :> es
       , SessionStore :> es
       )
    => Eff es BuildConfig
loadBuildConfig = do
    session <- SessionStore.get
    let config =
            BuildConfig
                { command = session.command
                , targets = session.targets
                , testTargets = session.testTargets
                , watchDirs = session.watchDirs
                }
    Log.info $ "Builder.component: resolved command = " <> coerce config.command
    pure config


onRestart
    :: ( BuildStore :> es
       , Log :> es
       , State BuildId :> es
       )
    => Eff es ()
onRestart = do
    Log.info "Restarting builder..."
    buildId <- get
    modify @BuildId (+ 1)
    setNewPhase $ EnteringNewPhase buildId $ Building Nothing


--------------------------------------------------------------------------------
-- Level 2 — GHCi-session lifecycle
--------------------------------------------------------------------------------

-- | The lifecycle hooks for one /GHCi session/. Each field is one moment in a
-- GHCi session's life; the coordinators below (@runGhciSessions@ /
-- @watchSourceChanges@) own the /when/, these own the /what/.
--
-- These are deliberately GHCi-session hooks only. Reloading the /tricorder
-- session/ (the project config) on a @.cabal@ change belongs to the outer loop
-- and lives inline in 'runBuilder' — keeping it out of here is what stops a
-- \"child restarting its parent\". Tests supply their own record to observe a
-- single hook in isolation.
data GhciSessionHooks es = GhciSessionHooks
    { onStart :: Eff es ()
    -- ^ A fresh GHCi session is about to launch: reset accumulated state.
    , onInitialLoad :: BuildConfig -> NewLoadResult -> Eff es ()
    -- ^ The initial load finished: run the post-load pipeline.
    , onSourceChange :: BuildConfig -> GhciSession.Controls (Eff es) -> SourceChangeDetected -> Eff es ()
    -- ^ A debounced source change arrived: run one build/test cycle.
    , onStartupFail :: SomeException -> Eff es ()
    -- ^ GHCi failed to start: surface 'BuildFailed' and wait to retry.
    }


-- | The default GHCi-session hooks.
defaultGhciSessionHooks
    :: ( BuildStore :> es
       , Clock :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => GhciSessionHooks es
defaultGhciSessionHooks =
    GhciSessionHooks
        { onStart = put emptyBuilderState
        , onInitialLoad = afterLoad
        , onSourceChange = reloadOnSourceChange
        , onStartupFail = recoverFromStartupFailure
        }


-- | Level 2 — run successive /GHCi sessions/ for one tricorder session, each
-- retried on startup failure. Reads top-to-bottom as a GHCi session's phases:
--
--   1. 'onStart' — reset accumulated state.
--   2. launch GHCi; on its initial load, 'onInitialLoad' runs the pipeline.
--   3. 'watchSourceChanges' — the inner loop, until the session is torn down.
--   4. 'onStartupFail' — if the launch itself threw, recover and retry.
runGhciSessions
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , GhciSession :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => GhciSessionHooks es
    -> BuildConfig
    -> Eff es Void
runGhciSessions hooks config = forever do
    hooks.onStart
    root@(ProjectRoot rootPath) <- ask
    BuildId n <- get
    Log.info $ "Starting GHCi session #" <> show n <> ": " <> coerce config.command

    startTime <- Clock.currentTime
    result <- trySync $ GhciSession.withGhci config.command root \initialLoad controls -> do
        endTime <- Clock.currentTime
        let filteredMsgs = filterToWatchDirs rootPath config.watchDirs initialLoad.diagnostics
        Log.info
            $ mconcat
                ["GHCi started (session #", show n, "): ", show (length filteredMsgs), " diagnostics"]
        hooks.onInitialLoad config NewLoadResult {startTime, endTime, loadResult = initialLoad}
        modify \s ->
            s
                { loadedModules = resolveKnownTargets Map.empty initialLoad
                , knownTargets = KnownTargetNames (Set.fromList initialLoad.targetNames)
                }
        watchSourceChanges hooks config controls
    case result of
        Right _ -> pure ()
        Left ex -> hooks.onStartupFail ex


-- | The GHCi-session loop with the default 'defaultGhciSessionHooks'. Kept as a
-- named entry point for tests; 'runBuilder' wraps this with the tricorder
-- session's cabal-restart handling.
buildWithGhciOnChange
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , GhciSession :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => BuildConfig
    -> Eff es Void
buildWithGhciOnChange = runGhciSessions defaultGhciSessionHooks


-- | Default 'onStartupFail': surface 'BuildFailed', then wait for a source
-- change to retry the launch.
--
-- A cabal change is handled out-of-band by 'runBuilder' cancelling this scope.
-- Without the wait, a startup failure was a dead end: the user could fix the
-- offending source file and nothing would happen, because no
-- 'SourceChangeDetected' listener is active on this path.
recoverFromStartupFailure
    :: ( BuildStore :> es
       , Log :> es
       , State BuildId :> es
       , Sub SourceChangeDetected :> es
       )
    => SomeException -> Eff es ()
recoverFromStartupFailure ex = do
    Log.err $ "GHCi session failed to start: " <> show ex
    enterPhase $ BuildFailed $ renderStartupError ex
    Log.info "Build command failed; waiting for a source change to retry"
    void $ Sub.listenOnce_ @SourceChangeDetected


--------------------------------------------------------------------------------
-- Level 3 — Source-change loop and build/test cycle
--------------------------------------------------------------------------------

-- | Level 3 — the inner loop. Wait for source changes and drive one build/test
-- cycle ('onSourceChange') per change.
watchSourceChanges
    :: ( BuildStore :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , Log :> es
       , State BuildId :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => GhciSessionHooks es
    -> BuildConfig
    -> GhciSession.Controls (Eff es)
    -> Eff es Void
watchSourceChanges hooks config controls = Conc.scoped do
    BuildId n <- get
    Log.debug $ "Builder: waiting for dirty flag (build #" <> show n <> ")"
    forever $ Conc.scoped do
        pending <- atomically (newTVar @(Maybe SourceChangeDetected) Nothing)
        -- Write the latest event into a `TVar`, and a single worker fork
        -- drains it when it is ready to process a new event. Events that
        -- arrive while the worker is processing the previous one simply
        -- overwrite the slot, so a burst of N touches collapses into exactly
        -- one trailing cycle (carrying the most recent event) rather than
        -- queueing N back-to-back cycles. This matters whenever
        -- 'interruptCurrent' can't drop the in-flight cycle promptly — e.g.
        -- when a 'status --wait' caller has registered as a waiter, gating
        -- 'interruptCurrent' to a no-op.
        Conc.fork_ $ Sub.listen_ \ev ->
            debounced 200 "source_change_reloader" do
                atomically (writeTVar pending (Just ev))
                -- Interrupts the currently running build as long as there are
                -- no waiters.
                interruptCurrent controls
        -- The worker that actually handles each event. This only loops when
        -- `hooks.onSourceChange` returns, which it will do once it completes
        -- or when it is interrupted. Only one worker should be running at any
        -- given time.
        Conc.fork_ $ forever do
            ev <- atomically do
                readTVar pending >>= \case
                    Nothing -> retry
                    Just e -> writeTVar pending Nothing >> pure e
            hooks.onSourceChange config controls ev
        Conc.awaitAll


-- 'controls.interrupt' is a safe no-op when GHCi is idle, and 'GhciSession'
-- serialises subsequent reloads through its own STM state.
interruptCurrent
    :: ( BuildStore :> es
       , Log :> es
       , TestRunner :> es
       )
    => GhciSession.Controls (Eff es) -> Eff es ()
interruptCurrent controls = do
    hasWaiters <- BuildStore.hasWaiters
    unless hasWaiters do
        Log.info "Change detected with no waiters. Interrupting current build/tests."
        controls.interrupt
        TestRunner.interruptCurrent


reloadOnSourceChange
    :: ( BuildStore :> es
       , Clock :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , TestRunner :> es
       )
    => BuildConfig
    -> GhciSession.Controls (Eff es)
    -> SourceChangeDetected
    -> Eff es ()
reloadOnSourceChange config controls (SourceChangeDetected fp event) = do
    Log.debug $ "Builder: source change detected " <> show event <> " " <> toText fp
    builderState <- get @BuilderState
    let known = Map.lookup (normalise fp) builderState.loadedModules
    case dispatch builderState.knownTargets known fp event of
        Nothing ->
            Log.debug
                $ "Builder: no-op for "
                    <> show event
                    <> " of file not loaded in GHCi: "
                    <> toText fp
        Just action -> do
            enterPhase $ Building Nothing

            res <- trySync do
                startTime <- Clock.currentTime
                res <- runAction controls action
                endTime <- Clock.currentTime
                pure (startTime, endTime, res)

            case res of
                Left e -> do
                    now <- Clock.currentTime
                    Log.err $ show now <> " Reload errored: " <> show e
                    -- Resolve the UI instead of stranding it in 'Building': a
                    -- reload that errors (rather than producing a result) must
                    -- not leave the daemon stuck until the next source change
                    -- happens to arrive and succeed.
                    enterPhase $ BuildFailed $ "Reload failed: " <> toText (displayException e)
                Right (startTime, endTime, loadResult) -> do
                    modify \s ->
                        s
                            { loadedModules = resolveKnownTargets s.loadedModules loadResult
                            , knownTargets = KnownTargetNames (Set.fromList loadResult.targetNames)
                            }
                    afterLoad config NewLoadResult {startTime, endTime, loadResult}


runAction :: GhciSession.Controls (Eff es) -> DispatchAction -> Eff es LoadResult
runAction controls = \case
    Reload -> controls.reload
    Add fp -> controls.add fp
    Unadd mn -> controls.unadd mn


-- | Run the post-load pipeline synchronously: compile diagnostics into a
-- 'BuildResult', then (optionally) run tests and transition through the
-- corresponding phases.
afterLoad
    :: ( BuildStore :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , State BuilderState :> es
       , TestRunner :> es
       )
    => BuildConfig -> NewLoadResult -> Eff es ()
afterLoad config newLoadResult = do
    buildResult <- compileLoadResultsIntoBuildResults config newLoadResult
    runPostBuildStore buildResult do
        if hasTargets config.testTargets && noErrors buildResult then
            requestTestRunsForNewBuildResults config.testTargets
        else do
            PostBuild.modifyPostBuild \pb -> pb {testSuites = Test.Suites mempty}
  where
    hasTargets testTargets = not $ null testTargets.getTestTargets
    noErrors result = all (\d -> d.severity /= SError) result.diagnostics


compileLoadResultsIntoBuildResults
    :: ( Reader ProjectRoot :> es
       , State BuilderState :> es
       )
    => BuildConfig
    -> NewLoadResult
    -> Eff es BuildResult
compileLoadResultsIntoBuildResults session newLoadResult = do
    ProjectRoot projectRoot <- ask
    let filteredResult =
            loadResult
                { GhciSession.diagnostics =
                    preserveFailureVisibility loadResult.diagnostics
                        $ filterToWatchDirs projectRoot watchDirs loadResult.diagnostics
                }

    newAccumulated <- state \s ->
        let merged = mergeDiagnostics s.diagnosticMap filteredResult
        in  (merged, s {diagnosticMap = merged})

    pure
        BuildResult
            { completedAt = endTime
            , duration = nominalDiffTime (diffUTCTime endTime startTime) :: Millisecond
            , moduleCount = loadResult.moduleCount
            , diagnostics = sortOn (\d -> (d.severity, d.file, d.line, d.col)) $ concat (Map.elems newAccumulated)
            }
  where
    BuildConfig {watchDirs} = session
    NewLoadResult {startTime, endTime, loadResult} = newLoadResult


requestTestRunsForNewBuildResults
    :: ( Log :> es
       , PostBuildStore :> es
       , TestRunner :> es
       )
    => TestTargets
    -> Eff es ()
requestTestRunsForNewBuildResults testTargets =
    runTestsForTargets testTargets >>= \case
        Aborted -> Log.info "Test run aborted by source change; skipping Done transition."
        NotAborted -> pure ()


data TestRunAborted = NotAborted | Aborted


-- Run all configured test suites if the build has no errors.
-- Transitions to 'Testing' phase while suites are running.
--
-- Returns 'Nothing' if the run was aborted mid-flight by a source change
-- (the caller should not transition to a Done phase in that case). Returns
-- 'Just' with the collected results otherwise.
runTestsForTargets
    :: ( Log :> es
       , PostBuildStore :> es
       , TestRunner :> es
       )
    => TestTargets
    -> Eff es TestRunAborted
runTestsForTargets testTargets = do
    TestRunner.resetAbort
    PostBuild.modifyPostBuild \pb -> pb {testSuites = Test.Suites $ Map.fromList $ (,Test.SuiteRunning Nothing) <$> tgts}

    Log.info $ "Running " <> show (length tgts) <> " test suite(s)"

    runLoop tgts
  where
    tgts = testTargets.getTestTargets
    runLoop [] = pure NotAborted
    runLoop (target : rest) = do
        Log.info $ "Running tests: " <> renderTestTarget target
        result' <- TestRunner.runTestSuite target
        aborted <- TestRunner.isAborted
        if aborted then
            pure Aborted
        else do
            PostBuild.modifyPostBuild \pb ->
                pb
                    { testSuites = Test.Suites $ Map.insert target result' pb.testSuites.getSuites
                    }

            runLoop rest


--------------------------------------------------------------------------------
-- Restart machinery
--------------------------------------------------------------------------------

-- | Run @action@ in a loop that restarts whenever a 'CabalChangeDetected'
-- event arrives. At most one iteration of @action@ runs at any moment: cabal
-- events arriving during a restart collapse into a single next iteration.
--
-- A TVar flag funnels the events: the cabal listener writes 'True' to it; a
-- single coordinator drains it via 'restartableForkWith', runs @preRestart@,
-- and exits the inner scope. Scope teardown cancels the current @action@
-- (including the 'cabal repl' subprocess via its bracket) and waits for it to
-- finish before the next iteration starts — so we never have two builders
-- racing for the same dist-newstyle directory.
restartOnCabalChange
    :: ( Conc :> es
       , Concurrent :> es
       , Log :> es
       , Sub CabalChangeDetected :> es
       )
    => Eff es ()
    -- ^ Pre-restart hook: runs in the coordinator thread after the flag has
    -- been drained but before the inner scope is torn down. Use this to set
    -- the UI to 'Restarting' and reload the session.
    -> Eff es r
    -- ^ Setup: runs at the start of each iteration, before @action@ is forked.
    -> (r -> Eff es Void)
    -- ^ Inner action. Must never return.
    -> Eff es Void
restartOnCabalChange preRestart setup action = do
    needsRestart <- atomically (newTVar False)
    Conc.scoped do
        Conc.fork_ $ Conc.restartableForkWith (signal needsRestart) setup action
        Sub.listen_ @CabalChangeDetected $ \(CabalChangeDetected path event) -> do
            Log.info $ "Cabal file changed (" <> show event <> " " <> toText path <> "); queued restart"
            atomically (writeTVar needsRestart True)
  where
    signal needsRestart = do
        atomically do
            check =<< readTVar needsRestart
            writeTVar needsRestart False
        preRestart


--------------------------------------------------------------------------------
-- Phase-transition helpers
--------------------------------------------------------------------------------

setNewPhase
    :: (BuildStore :> es)
    => EnteringNewPhase -> Eff es ()
setNewPhase (EnteringNewPhase bid phase) =
    BuildStore.setPhase bid phase


-- | Transition the /current/ build into @phase@.
enterPhase
    :: ( BuildStore :> es
       , State BuildId :> es
       )
    => BuildPhase -> Eff es ()
enterPhase phase = do
    buildId <- get
    setNewPhase $ EnteringNewPhase buildId phase


renderStartupError :: SomeException -> Text
renderStartupError ex = case fromException ex of
    Just (StartupFailed msg) -> msg
    Just StartupTimeout -> "Build command did not produce a GHCi banner before timing out."
    Just (UnexpectedExit cmd lastLine) ->
        "Build command exited unexpectedly: "
            <> cmd
            <> maybe "" (\l -> "\n" <> l) lastLine
    Nothing -> toText (displayException ex)


--------------------------------------------------------------------------------
-- Supporting types
--------------------------------------------------------------------------------

data NewLoadResult = NewLoadResult
    { startTime :: UTCTime
    , endTime :: UTCTime
    , loadResult :: LoadResult
    }
    deriving stock (Eq, Show)


-- | A pending phase transition. Carried by 'setNewPhase' into the 'BuildStore'.
data EnteringNewPhase = EnteringNewPhase BuildId BuildPhase
    deriving stock (Eq, Show)
