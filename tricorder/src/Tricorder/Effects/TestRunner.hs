module Tricorder.Effects.TestRunner
    ( -- * Effect
      TestRunner (..)
    , runTestSuite
    , interruptCurrent
    , resetAbort
    , isAborted

      -- * Interpreters
    , runTestRunnerIO
    , runTestRunnerScripted

      -- * Parsing utilities
    , GhciOutcome (..)
    , detectOutcome

      -- * Internal helpers (exported for testing)
    , abortGatedProgress
    , reportTestProgress
    ) where

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.File (File)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process)
import Atelier.Effects.Publishing (Sub)
import Atelier.Effects.Timeout (Timeout, timeout)
import Control.Concurrent.STM (TVar, modifyTVar', readTVar, stateTVar, writeTVar)
import Control.Exception (throwIO)
import Data.Default (def)
import Data.Time.Units (Second)
import Effectful (Effect, IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically, newTVarIO)
import Effectful.Dispatch.Dynamic (interpretWith_, reinterpret)
import Effectful.Exception (bracket_, finally, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, evalState, get, put)
import Effectful.TH (makeEffect)
import System.FilePath (addTrailingPathSeparator, normalise)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Publishing qualified as Sub
import Data.List qualified as List
import Data.Map.Strict qualified as Map
import Data.Text qualified as T

import Tricorder.BuildState
    ( BuildPhase (..)
    , BuildProgress (..)
    , BuildResult (..)
    , BuildState (..)
    , CabalChangeDetected
    , PostBuild (..)
    , SourceChangeDetected (..)
    , TestPhase (..)
    , TestRun (..)
    , TestRunCompletion (..)
    , TestRunError (..)
    )
import Tricorder.Effects.BuildStore (BuildStore, modifyPhase)
import Tricorder.Effects.GhciSession.GhciParser (GhciLoading (..))
import Tricorder.Effects.Repl (Repl)
import Tricorder.Effects.SessionStore (SessionStore)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Command (..), Session (..), TestTimeout (..))
import Tricorder.TestOutput (parseHspecDuration, parseHspecOutput)

import Tricorder.Effects.Repl qualified as Repl
import Tricorder.Effects.SessionStore qualified as SessionStore


data TestRunner :: Effect where
    -- | Run a single test suite in a short-lived @cabal repl@ process and
    -- return the captured output and detected outcome.
    RunTestSuite :: Text -> TestRunner m TestRun
    -- | Interrupt the test currently in flight (if any) and latch an abort
    -- flag so that subsequent 'RunTestSuite' calls short-circuit until
    -- 'ResetAbort' is called.
    InterruptCurrent :: TestRunner m ()
    -- | Clear the abort flag. Call this at the start of a new test run.
    ResetAbort :: TestRunner m ()
    -- | Read the abort flag without clearing it.
    IsAborted :: TestRunner m Bool


makeEffect ''TestRunner


-- | Production interpreter that spawns a short-lived @cabal repl test:\<name\>@
-- process for each suite, feeds @:main\\n:quit\\n@ to stdin, captures combined
-- stdout+stderr, and detects the outcome via 'detectOutcome'.
runTestRunnerIO
    :: forall es a
     . ( BuildStore :> es
       , Conc :> es
       , Concurrent :> es
       , File :> es
       , Log :> es
       , Process :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , Sub CabalChangeDetected :> es
       , Sub SourceChangeDetected :> es
       , Timeout :> es
       )
    => Eff (TestRunner : es) a -> Eff es a
runTestRunnerIO act = do
    ProjectRoot projectRoot <- ask
    currentProcRef <- newTVarIO (Nothing :: Maybe Repl)
    abortedRef <- newTVarIO False
    -- Turbo mode: one long-lived session per suite, driven with @:reload@ +
    -- @:main@. The stored action stops the session and awaits its teardown.
    turboCacheRef <- newTVarIO (Map.empty :: Map Text (Repl, Eff es ()))
    -- The scope turbo sessions are forked into: captured outside the transient
    -- per-build-cycle scopes so a session survives across runs, yet is still
    -- cancelled when this scope closes on daemon shutdown.
    poolScope <- Conc.currentScope

    let
        -- Terminate a cached session and retire its background thread. 'trySync'
        -- so one stuck teardown can neither strand a sweep nor abort a respawn.
        stopSession :: (Repl, Eff es ()) -> Eff es ()
        stopSession (repl, stop) = void $ trySync (Repl.terminate repl >> stop)

        -- Stop and drop every cached session; runs on daemon shutdown.
        sweepTurbo :: Eff es ()
        sweepTurbo = do
            entries <- atomically $ stateTVar turboCacheRef \m -> (Map.elems m, Map.empty)
            for_ entries stopSession

        -- Evict one cached session; the next run for that suite respawns.
        evictTurbo :: Text -> Eff es ()
        evictTurbo target = do
            entry <- atomically $ stateTVar turboCacheRef \m ->
                (Map.lookup target m, Map.delete target m)
            for_ entry stopSession

        -- Evict cached sessions that do not own the changed file: a change in a
        -- suite's own @hs-source-dirs@ is handled by @:reload@, but a change
        -- elsewhere may be a dependency that a single-target @:reload@ cannot
        -- rebuild, so respawn [ref:turbo_cabal_staleness]. Over-inclusive but
        -- safe: an unrelated change costs at most one respawn.
        evictForeignChange :: FilePath -> Eff es ()
        evictForeignChange path = do
            Session {testTargetSourceDirs} <- SessionStore.get
            targets <- atomically $ Map.keys <$> readTVar turboCacheRef
            for_ targets \target -> do
                let ownDirs = Map.findWithDefault [] target testTargetSourceDirs
                unless (any (`fileWithinDir` path) ownDirs) (evictTurbo target)

        -- Get a ready session for the suite, spawning one if absent. A reused
        -- session is @:reload@ed to pick up edits; if that fails it is evicted
        -- and respawned. Returns the session and whether it was reused, which the
        -- caller uses to decide whether a crash warrants a fresh-session retry.
        --
        -- [tag:turbo_cabal_staleness] @:reload@ rebuilds only the target's own
        -- modules, not its dependency packages (loaded as prebuilt artifacts), so
        -- a change outside the target is invisible to a reused session. Three
        -- guards keep sessions fresh: a @.cabal@ change sweeps all sessions
        -- ('CabalChangeDetected'); a source change outside the suite's own
        -- @hs-source-dirs@ evicts it ('evictForeignChange'); and a dependency
        -- change that breaks compilation triggers a fresh-session retry
        -- ('runTurboAttempt'). This staleness is inherent to reusing a
        -- non-multi-repl @cabal repl@ — multi-repl fixes reloads but cannot run
        -- @:main@ before GHC 9.14.
        acquireTurbo :: Text -> Command -> (GhciLoading -> Eff es ()) -> Eff es (Repl, Bool)
        acquireTurbo target cmd onProgress = do
            let register repl = atomically (writeTVar currentProcRef (Just repl))
                spawn = do
                    (repl, _initial, stop) <-
                        Repl.spawnPersistentRepl poolScope def cmd projectRoot onProgress register
                    atomically $ modifyTVar' turboCacheRef (Map.insert target (repl, stop))
                    pure (repl, False)
            cached <- atomically $ Map.lookup target <$> readTVar turboCacheRef
            case cached of
                Nothing -> spawn
                Just (repl, _stop) -> do
                    register repl
                    trySync (Repl.exec repl ":reload" onProgress) >>= \case
                        Right _ -> pure (repl, True)
                        Left (_ :: SomeException) -> evictTurbo target >> spawn

        -- Run @:main@ under the configured timeout, short-circuiting if an
        -- interrupt has already landed. 'Left' is a timeout (seconds); 'Right'
        -- is the captured output. Shared by the turbo and one-shot paths.
        runMain :: Repl -> TestTimeout -> Eff es (Either Int [Text])
        runMain repl testTimeout =
            atomically (readTVar abortedRef) >>= \case
                -- Interrupt already landed; short-circuit without running @:main@.
                True -> pure (Right [])
                False -> case testTimeout of
                    TestTimeout secs | secs <= 0 -> Right <$> Repl.exec repl ":main" noProgress
                    TestTimeout secs ->
                        timeout (fromIntegral secs :: Second) (Repl.exec repl ":main" noProgress) >>= \case
                            Nothing -> pure (Left secs)
                            Just ls -> pure (Right ls)
          where
            noProgress = \_ -> pure ()

        timedOut :: Text -> Int -> Eff es TestRun
        timedOut target secs = do
            Log.warn $ "Test suite " <> target <> " timed out after " <> show secs <> "s"
            pure $ TestRunErrored $ TestRunError {target, message = "Test suite timed out after " <> show secs <> "s"}

        runTurbo :: Text -> TestTimeout -> Eff es TestRun
        runTurbo target testTimeout =
            -- Clear 'currentProcRef' when the run ends so a later
            -- 'InterruptCurrent' does not terminate the now-idle cached session,
            -- which lives on in 'turboCacheRef'.
            bracket_ (pure ()) (atomically (writeTVar currentProcRef Nothing))
                $ runTurboAttempt target testTimeout True

        -- One turbo run, with a single fresh-session retry guarded by
        -- @allowRespawn@. Tests only run after a clean build, so a compile crash
        -- from a reused session means it is stale (a dependency changed that
        -- @:reload@ missed): evict and retry once against a fresh session. A
        -- crash on a fresh session is a genuine failure and is reported.
        runTurboAttempt :: Text -> TestTimeout -> Bool -> Eff es TestRun
        runTurboAttempt target testTimeout allowRespawn = do
            let cmd = Command $ "cabal repl " <> target
                onProgress = abortGatedProgress abortedRef target
            result <- trySync do
                (repl, reused) <- acquireTurbo target cmd onProgress
                (reused,) <$> runMain repl testTimeout
            case result of
                -- Session died mid-command (or setup failed); drop it so the
                -- next run respawns.
                Left ex ->
                    evictTurbo target
                        >> pure (TestRunErrored (TestRunError {target, message = show ex}))
                -- A stuck session can't be reused; evict it.
                Right (_, Left secs) -> evictTurbo target >> timedOut target secs
                Right (reused, Right mainLines) ->
                    case testRunFromOutput target mainLines of
                        run@(TestRunErrored _)
                            | allowRespawn && reused ->
                                evictTurbo target >> runTurboAttempt target testTimeout False
                            | otherwise -> pure run
                        -- Pass/fail: the session stays cached for the next @:reload@.
                        run -> pure run

        -- Normal (non-turbo) mode: a fresh short-lived @cabal repl@ per run.
        runOneShot :: Text -> TestTimeout -> Eff es TestRun
        runOneShot target testTimeout = do
            let onProgress = abortGatedProgress abortedRef target
                -- Register the process before the initial compile drain, so an
                -- interrupt during that drain has something to kill instead of
                -- waiting several seconds for the doomed @cabal repl@ to finish.
                onReady ghci = atomically (writeTVar currentProcRef (Just ghci))
            -- Always clear 'currentProcRef' on exit, whether 'Repl.withRepl'
            -- completed normally or threw.
            result <- trySync
                $ bracket_
                    (pure ())
                    (atomically (writeTVar currentProcRef Nothing))
                $ Repl.withRepl def (Command $ "cabal repl " <> target) projectRoot onProgress onReady \ghci _ ->
                    runMain ghci testTimeout
            case result of
                Left ex -> pure $ TestRunErrored $ TestRunError {target, message = show ex}
                Right (Left secs) -> timedOut target secs
                Right (Right mainLines) -> pure $ testRunFromOutput target mainLines

    -- A @.cabal@ change is not picked up by @:reload@, so evict all sessions and
    -- let the next run respawn against the new config [ref:turbo_cabal_staleness].
    -- The listener lives in 'poolScope', cancelled on shutdown.
    void $ Conc.forkIn poolScope $ Sub.listen_ @CabalChangeDetected \_ -> sweepTurbo

    -- A dependency's source change is invisible to a reused single-target session,
    -- so evict any suite that does not own the changed file
    -- [ref:turbo_cabal_staleness].
    void $ Conc.forkIn poolScope $ Sub.listen_ @SourceChangeDetected \(SourceChangeDetected path _) ->
        evictForeignChange path

    flip finally sweepTurbo $ interpretWith_ act \case
        InterruptCurrent -> do
            -- Terminate (not just SIGINT) the test process: hspec/tasty install
            -- SIGINT handlers that finalise the run rather than abort it, so an
            -- outright kill is the only prompt abort. Under turbo the terminated
            -- session is evicted and respawned on the next run.
            mProc <- atomically do
                writeTVar abortedRef True
                readTVar currentProcRef
            for_ mProc Repl.terminate
        ResetAbort -> atomically (writeTVar abortedRef False)
        IsAborted -> atomically (readTVar abortedRef)
        RunTestSuite target -> do
            alreadyAborted <- atomically (readTVar abortedRef)
            if alreadyAborted then
                pure $ TestRunErrored $ TestRunError {target, message = "Test run aborted"}
            else do
                Session {turboTests, testTimeout} <- SessionStore.get
                if turboTests then runTurbo target testTimeout else runOneShot target testTimeout


-- | Scripted interpreter for testing.
--
-- Each call to 'runTestSuite' pops the next result from the pre-loaded list.
-- 'Left' results are re-thrown as exceptions, simulating process failures.
runTestRunnerScripted
    :: forall es a
     . (Concurrent :> es, IOE :> es)
    => [Either SomeException TestRun]
    -> Eff (TestRunner : es) a
    -> Eff es a
runTestRunnerScripted results act = do
    -- Mirror the IO interpreter's abort semantics so tests driving an interrupt
    -- can observe the short-circuit via 'isAborted'.
    abortedRef <- newTVarIO False
    reinterpret
        (evalState results)
        ( \_ -> \case
            RunTestSuite _ -> popResult
            InterruptCurrent -> atomically (writeTVar abortedRef True)
            ResetAbort -> atomically (writeTVar abortedRef False)
            IsAborted -> atomically (readTVar abortedRef)
        )
        act
  where
    popResult :: Eff (State [Either SomeException TestRun] : es) TestRun
    popResult =
        get >>= \case
            [] -> error "TestRunnerScripted: no more results in queue"
            Left ex : rest -> put rest >> liftIO (throwIO ex)
            Right r : rest -> put rest >> pure r


-- | Progress callback used while a test suite is running. Reads the test
-- runner's abort flag before applying the update so that pipe-buffered
-- '[N of M] Compiling' lines emitted by a dying test process — after the
-- user has already touched a file — do not push the counter forward.
abortGatedProgress
    :: (BuildStore :> es, Concurrent :> es)
    => TVar Bool -> Text -> GhciLoading -> Eff es ()
abortGatedProgress abortedRef target loading = do
    aborted <- atomically (readTVar abortedRef)
    unless aborted $ reportTestProgress target loading


-- | Patch live compile progress for a test suite into the current 'Testing'
-- phase of the build state.
--
-- A test suite's @cabal repl@ session typically recompiles a slice of the
-- project before running @:main@. Mirroring the main-build progress bar, we
-- update the matching 'TestRunning' entry as each @[N of M] Compiling …@
-- line arrives so the UI shows @running... (N/M)@ live.
--
-- The update is best-effort: if the phase has moved on (e.g. a source change
-- triggered 'Restarting' or 'Building'), the progress event is dropped rather
-- than reverting the phase.
reportTestProgress
    :: (BuildStore :> es) => Text -> GhciLoading -> Eff es ()
reportTestProgress target loading =
    modifyPhase \state -> case state.phase of
        BuildComplete (PostBuild Testing partialResult) ->
            let progress = BuildProgress {compiled = loading.index, total = loading.total}
                updateRun (TestRunning t _) | t == target = TestRunning t (Just progress)
                updateRun r = r
                newRuns = map updateRun partialResult.testRuns
            in  BuildComplete (PostBuild Testing partialResult {testRuns = newRuns})
        other -> other


-- | Does @file@ lie within @dir@ (or equal it)? Compares normalised paths on a
-- path-component boundary, so @\/a\/b@ does not spuriously match @\/a\/bcd@.
fileWithinDir :: FilePath -> FilePath -> Bool
fileWithinDir dir file =
    let normalisedDir = normalise dir
        normalisedFile = normalise file
    in  normalisedDir == normalisedFile
            || addTrailingPathSeparator normalisedDir `List.isPrefixOf` normalisedFile


-- | Assemble a 'TestRun' from a suite's captured @:main@ output, classifying
-- the outcome with 'detectOutcome'. A crash (compile error or @main@ not in
-- scope) becomes a 'TestRunErrored'; anything else a 'TestRunCompleted' whose
-- @passed@ reflects the exit code. Shared by the turbo and one-shot paths.
testRunFromOutput :: Text -> [Text] -> TestRun
testRunFromOutput target mainLines =
    let output = T.unlines mainLines
    in  case detectOutcome output of
            GhciCrashed msg -> TestRunErrored $ TestRunError {target, message = msg}
            outcome ->
                TestRunCompleted
                    $ TestRunCompletion
                        { target
                        , passed = outcome == GhciPassed
                        , output
                        , testCases = parseHspecOutput output
                        , duration = parseHspecDuration output
                        }


data GhciOutcome
    = GhciPassed
    | GhciFailed
    | GhciCrashed Text
    deriving stock (Eq, Show)


-- | Detect the test outcome from raw GHCi output.
--
-- All major test frameworks (@hspec@, @tasty@, @HUnit@) call
-- 'System.Exit.exitWith' on completion. GHCi surfaces this as a line
-- matching @*** Exception: ExitSuccess@ (pass) or
-- @*** Exception: ExitFailure N@ (fail). Any other @*** Exception:@ line
-- means the runner crashed.
--
-- When no exception line is present, the absence is ambiguous: either the
-- test ran and printed nothing exit-related, or @:main@ never ran at all
-- (e.g. the test target failed to compile, so @main@ is not in scope).
-- A line containing @": error:"@ in the captured output is treated as the
-- latter — a GHC compile/load error that prevented the suite from running.
detectOutcome :: Text -> GhciOutcome
detectOutcome output =
    case List.find ("*** Exception: " `T.isPrefixOf`) outputLines of
        Just line ->
            case T.stripPrefix "*** Exception: " line of
                Nothing -> GhciPassed
                Just rest ->
                    let r = T.strip rest
                    in  if r == "ExitSuccess" then
                            GhciPassed
                        else
                            if "ExitFailure" `T.isPrefixOf` r then
                                GhciFailed
                            else
                                GhciCrashed r
        Nothing -> case List.find isCompileErrorLine outputLines of
            Just errLine -> GhciCrashed (T.strip errLine)
            Nothing -> GhciPassed
  where
    outputLines = T.lines output
    -- GHC compile/load errors are formatted as
    -- @<file-or-loc>:L:C: error: …@ (with at least one space after the colon).
    -- The substring @": error:"@ is the canonical marker for these.
    isCompileErrorLine line = ": error:" `T.isInfixOf` line
