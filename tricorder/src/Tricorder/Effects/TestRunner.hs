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
       , Timeout :> es
       )
    => Eff (TestRunner : es) a -> Eff es a
runTestRunnerIO act = do
    ProjectRoot projectRoot <- ask
    currentProcRef <- newTVarIO (Nothing :: Maybe Repl)
    abortedRef <- newTVarIO False
    -- Turbo mode: one long-lived @cabal repl@ session per suite, kept between
    -- runs and driven with @:reload@ + @:main@. The stored action stops the
    -- session (terminates its group and awaits the teardown).
    turboCacheRef <- newTVarIO (Map.empty :: Map Text (Repl, Eff es ()))
    -- The scope turbo sessions are forked into. Captured here — outside the
    -- transient per-build-cycle scopes that 'runTestSuite' runs under — so a
    -- session survives across runs yet is still cancelled when this scope closes
    -- on daemon shutdown. Nothing is forked into the caller's transient scope.
    poolScope <- Conc.currentScope

    let
        -- Terminate a cached turbo session (prompt even if it is wedged
        -- mid-@:main@) and retire its background thread. Wrapped in 'trySync'
        -- so one stuck teardown can neither strand the rest of a sweep nor
        -- abort a respawn.
        stopSession :: (Repl, Eff es ()) -> Eff es ()
        stopSession (repl, stop) = void $ trySync (Repl.terminate repl >> stop)

        -- Stop and drop every cached turbo session. Runs on interpreter
        -- teardown (daemon shutdown) so we don't leak @cabal repl@ processes.
        sweepTurbo :: Eff es ()
        sweepTurbo = do
            entries <- atomically $ stateTVar turboCacheRef \m -> (Map.elems m, Map.empty)
            for_ entries stopSession

        -- Evict one cached turbo session. The next run for that suite respawns
        -- a fresh one.
        evictTurbo :: Text -> Eff es ()
        evictTurbo target = do
            entry <- atomically $ stateTVar turboCacheRef \m ->
                (Map.lookup target m, Map.delete target m)
            for_ entry stopSession

        -- Get a ready turbo session for the suite, spawning one if absent. A
        -- reused session is @:reload@ed to pick up edits; if that fails it is
        -- evicted and respawned so this run still produces a result.
        --
        -- [tag:turbo_cabal_staleness] @:reload@ rebuilds only the target's own
        -- modules — not sibling/dependency packages, which the session loaded as
        -- prebuilt artifacts. So a change *outside* the target (a dependency
        -- package's source, or a @.cabal@) is not seen by a reused session. Two
        -- things bound the staleness: a @.cabal@ change is swept proactively
        -- (see the 'CabalChangeDetected' listener), and a dependency change that
        -- makes @:main@ fail to compile triggers a fresh-session retry (see
        -- 'runTurboAttempt'). A dependency change that alters *behaviour* without
        -- breaking compilation is the residual gap — restart the daemon to be
        -- sure. This is inherent to reusing a non-multi-repl @cabal repl@.
        --
        -- Returns the session and whether it was reused (@True@) rather than
        -- freshly spawned (@False@) — the caller uses that to decide whether a
        -- crash is worth a fresh-session retry.
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
                -- An interrupt landed; the run loop discards the value once it
                -- sees 'abortedRef', so short-circuit without running @:main@.
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
            -- 'InterruptCurrent' (fired on the next source change) does not
            -- terminate the now-idle cached session. The session itself lives
            -- on in 'turboCacheRef'.
            bracket_ (pure ()) (atomically (writeTVar currentProcRef Nothing))
                $ runTurboAttempt target testTimeout True

        -- One turbo run, with a single fresh-session retry guarded by
        -- @allowRespawn@. Tests only run after a clean build, so if a *reused*
        -- session's @:main@ ends in a compile crash the session must be stale
        -- — e.g. a dependency package changed and @:reload@ (which rebuilds only
        -- the target's own modules) didn't pick it up. In that case we evict and
        -- retry once against a fresh session, which rebuilds its dependencies.
        -- A crash on a *fresh* session is a genuine failure and is reported.
        runTurboAttempt :: Text -> TestTimeout -> Bool -> Eff es TestRun
        runTurboAttempt target testTimeout allowRespawn = do
            let cmd = Command $ "cabal repl " <> target
                onProgress = abortGatedProgress abortedRef target
            result <- trySync do
                (repl, reused) <- acquireTurbo target cmd onProgress
                (reused,) <$> runMain repl testTimeout
            case result of
                -- The session died mid-command (or setup failed); drop it so the
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
                        -- Pass/fail: the session stays cached and healthy for the
                        -- next @:reload@.
                        run -> pure run

        -- Normal (non-turbo) mode: a fresh short-lived @cabal repl@ per run.
        runOneShot :: Text -> TestTimeout -> Eff es TestRun
        runOneShot target testTimeout = do
            let onProgress = abortGatedProgress abortedRef target
                -- Register the process as soon as 'Repl.withRepl' constructs it
                -- — before the initial @cabal repl@ compile drain runs. Without
                -- this, an interrupt during that drain would find
                -- 'currentProcRef' empty and have nothing to kill, so the new
                -- build's cycle would wait several seconds for the doomed
                -- @cabal repl@ to finish compiling before releasing the lock.
                onReady ghci = atomically (writeTVar currentProcRef (Just ghci))
            -- Outer bracket: always clear 'currentProcRef' on exit, whether
            -- 'Repl.withRepl' completed normally or threw.
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

    -- Proactively invalidate cached turbo sessions on a @.cabal@ change: a
    -- persistent @cabal repl@ won't reconfigure on @:reload@, so evict them all
    -- and let the next run respawn against the new config — mirroring how the
    -- build session restarts on the same event [ref:turbo_cabal_staleness]. The
    -- listener lives in 'poolScope', so it is cancelled on shutdown.
    void $ Conc.forkIn poolScope $ Sub.listen_ @CabalChangeDetected \_ -> sweepTurbo

    flip finally sweepTurbo $ interpretWith_ act \case
        InterruptCurrent -> do
            -- Terminate (not just SIGINT) the test process: hspec/tasty
            -- install their own SIGINT handlers that finalise the current
            -- run rather than aborting it, so killing it outright is the only
            -- way to get a prompt abort. 'Repl.exec' then raises
            -- 'UnexpectedExit', 'trySync' catches it, and the run loop
            -- short-circuits on @abortedRef@. Under turbo the terminated
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
    -- Mirror the IO interpreter's abort semantics so tests that drive
    -- 'runTestsIfClean' through an interrupt can actually observe the
    -- short-circuit via 'isAborted'. A hard-coded 'pure False' would
    -- silently mask any regression in that flow.
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
