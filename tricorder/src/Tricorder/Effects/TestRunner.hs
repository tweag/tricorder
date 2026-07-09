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
import Atelier.Effects.Timeout (Timeout, timeout)
import Control.Concurrent.STM (TVar, readTVar, writeTVar)
import Control.Exception (throwIO)
import Data.Default (def)
import Data.Time.Units (Second)
import Effectful (Effect, IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically, newTVarIO)
import Effectful.Dispatch.Dynamic (interpretWith_, reinterpret)
import Effectful.Exception (bracket_, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, evalState, get, put)
import Effectful.TH (makeEffect)

import Atelier.Effects.Log qualified as Log
import Data.List qualified as List
import Data.Map.Strict qualified as Map
import Data.Text qualified as T

import Tricorder.BuildState
    ( BuildPhase (..)
    , BuildState (..)
    , PostBuild (..)
    )
import Tricorder.BuildState.BuildProgress (BuildProgress (..))
import Tricorder.Effects.BuildStore (BuildStore, modifyPhase)
import Tricorder.Effects.GhciSession.GhciParser (GhciLoading (..))
import Tricorder.Effects.GhciSession.GhciProcess
    ( GhciProcess
    , execGhci
    , terminateGhciProcess
    , withGhciProcess
    )
import Tricorder.Effects.SessionStore (SessionStore)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session
    ( Command (..)
    , Session (..)
    , TestTarget
    , TestTimeout (..)
    , renderTestTarget
    )
import Tricorder.TestOutput (parseHspecDuration, parseHspecOutput)

import Tricorder.BuildState.Test qualified as Test
import Tricorder.Effects.SessionStore qualified as SessionStore


data TestRunner :: Effect where
    -- | Run a single test suite in a short-lived @cabal repl@ process and
    -- return the captured output and detected outcome.
    RunTestSuite :: TestTarget -> TestRunner m Test.Suite
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
    :: ( BuildStore :> es
       , Conc :> es
       , Concurrent :> es
       , File :> es
       , Log :> es
       , Process :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , Timeout :> es
       )
    => Eff (TestRunner : es) a -> Eff es a
runTestRunnerIO act = do
    ProjectRoot projectRoot <- ask
    currentProcRef <- newTVarIO (Nothing :: Maybe GhciProcess)
    abortedRef <- newTVarIO False
    interpretWith_ act \case
        InterruptCurrent -> do
            -- Terminate (not just SIGINT) the test process: hspec/tasty
            -- install their own SIGINT handlers that finalise the current
            -- run rather than aborting it. Each test runs in its own
            -- short-lived @cabal repl@ process, so killing it outright is
            -- safe and gets a prompt abort. 'execGhci' then raises
            -- 'UnexpectedExit', 'trySync' catches it, and the run loop
            -- short-circuits on @abortedRef@.
            mProc <- atomically do
                writeTVar abortedRef True
                readTVar currentProcRef
            for_ mProc terminateGhciProcess
        ResetAbort -> atomically (writeTVar abortedRef False)
        IsAborted -> atomically (readTVar abortedRef)
        RunTestSuite target -> do
            alreadyAborted <- atomically (readTVar abortedRef)
            if alreadyAborted then
                pure $ Test.SuiteErrored $ Test.SuiteError {message = "Test run aborted"}
            else do
                Session {testTimeout} <- SessionStore.get
                let onProgress = abortGatedProgress abortedRef target
                    noProgress = \_ -> pure ()
                    -- Register the process as soon as 'setupGhciProcess'
                    -- constructs it — before the initial @cabal repl@
                    -- compile drain runs. Without this, an interrupt that
                    -- arrives during that drain would find
                    -- 'currentProcRef' empty and have nothing to kill, so
                    -- the new build's cycle would have to wait several
                    -- seconds for the doomed @cabal repl@ to finish
                    -- compiling its test code before the cycle lock was
                    -- released.
                    onReady ghci = atomically (writeTVar currentProcRef (Just ghci))
                -- Outer bracket: always clear 'currentProcRef' on exit,
                -- whether 'withGhciProcess' completed normally or threw.
                result <- trySync
                    $ bracket_
                        (pure ())
                        (atomically (writeTVar currentProcRef Nothing))
                    $ withGhciProcess def (Command $ "cabal repl " <> renderTestTarget target) projectRoot onProgress onReady \ghci _ ->
                        atomically (readTVar abortedRef) >>= \case
                            -- An interrupt may have landed during the
                            -- @cabal repl@ load. The returned value is
                            -- discarded by the run loop once it sees
                            -- 'abortedRef'.
                            True -> pure (Right [])
                            False -> case testTimeout of
                                TestTimeout secs | secs <= 0 -> Right <$> execGhci ghci ":main" noProgress
                                TestTimeout secs ->
                                    timeout (fromIntegral secs :: Second) (execGhci ghci ":main" noProgress) >>= \case
                                        Nothing -> pure (Left secs)
                                        Just ls -> pure (Right ls)
                case result of
                    Left ex ->
                        pure
                            $ Test.SuiteErrored
                            $ Test.SuiteError {message = show ex}
                    Right (Left secs) -> do
                        Log.warn $ "Test suite " <> renderTestTarget target <> " timed out after " <> show secs <> "s"
                        pure
                            $ Test.SuiteErrored
                            $ Test.SuiteError {message = "Test suite timed out after " <> show secs <> "s"}
                    Right (Right mainLines) ->
                        pure
                            $ let output = T.unlines mainLines
                              in  case detectOutcome output of
                                    GhciCrashed msg ->
                                        Test.SuiteErrored $ Test.SuiteError {message = msg}
                                    outcome ->
                                        Test.SuiteCompleted
                                            $ Test.SuiteCompletion
                                                { passed = outcome == GhciPassed
                                                , output
                                                , testCases = parseHspecOutput output
                                                , duration = parseHspecDuration output
                                                }


-- | Scripted interpreter for testing.
--
-- Each call to 'runTestSuite' pops the next result from the pre-loaded list.
-- 'Left' results are re-thrown as exceptions, simulating process failures.
runTestRunnerScripted
    :: forall es a
     . (Concurrent :> es, IOE :> es)
    => [Either SomeException Test.Suite]
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
    popResult :: Eff (State [Either SomeException Test.Suite] : es) Test.Suite
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
    => TVar Bool -> TestTarget -> GhciLoading -> Eff es ()
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
    :: (BuildStore :> es) => TestTarget -> GhciLoading -> Eff es ()
reportTestProgress target loading =
    modifyPhase \state -> case state.phase of
        BuildComplete result postBuild
            | Test.anyRunningTests postBuild.testSuites ->
                let progress = BuildProgress {compiled = loading.index, total = loading.total}
                    updateRun (Test.SuiteRunning _) = Test.SuiteRunning (Just progress)
                    updateRun r = r
                    newRuns = Test.Suites $ Map.adjust updateRun target postBuild.testSuites.getSuites
                in  BuildComplete result postBuild {testSuites = newRuns}
        other -> other


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
