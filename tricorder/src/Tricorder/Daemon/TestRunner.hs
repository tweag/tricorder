module Tricorder.Daemon.TestRunner
    ( -- * Effect
      TestRunner (..)
    , runTestSuite

      -- * Interpreters
    , run
    , runScripted

      -- * Parsing utilities
    , GhciOutcome (..)
    , detectOutcome

      -- * Internal helpers (exported for testing)
    , loadingToProgress
    ) where

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.File (File)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process)
import Atelier.Effects.Timeout (Timeout, timeout)
import Control.Exception (throwIO)
import Data.Default (def)
import Data.Time.Units (Second)
import Effectful (Effect, IOE, Limit (..), Persistence (..), UnliftStrategy (ConcUnlift))
import Effectful.Concurrent (Concurrent)
import Effectful.Dispatch.Dynamic (interpretWith, localUnlift, reinterpret_)
import Effectful.Exception (trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, evalState, get, put)
import Effectful.TH (makeEffect)

import Atelier.Effects.Log qualified as Log
import Data.List qualified as List
import Data.Text qualified as T

import Tricorder.Daemon.GhciSession.GhciParser (GhciLoading (..))
import Tricorder.Daemon.GhciSession.GhciProcess
    ( execGhci
    , withGhciProcess
    )
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session
    ( Command (..)
    , TestTarget
    , TestTimeout (..)
    , renderTestTarget
    )
import Tricorder.TestOutput (parseHspecDuration, parseHspecOutput)

import Tricorder.Build.Test qualified as Test


data TestRunner :: Effect where
    -- | Run a single test suite in a short-lived @cabal repl@ process and
    -- return the captured output and detected outcome.
    RunTestSuite
        :: (Test.Suite -> m ())
        -- ^ Handler for test run progress
        -> TestTimeout
        -> TestTarget
        -> TestRunner m Test.Suite


makeEffect ''TestRunner


-- | Production interpreter that spawns a short-lived @cabal repl test:\<name\>@
-- process for each suite, feeds @:main\\n:quit\\n@ to stdin, captures combined
-- stdout+stderr, and detects the outcome via 'detectOutcome'.
run
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       , Log :> es
       , Process :> es
       , Reader ProjectRoot :> es
       , Timeout :> es
       )
    => Eff (TestRunner : es) a -> Eff es a
run act = do
    interpretWith act \env -> \case
        RunTestSuite progressHandler testTimeout target ->
            localUnlift env (ConcUnlift Persistent Unlimited) \unlift -> do
                let onProgress = unlift . progressHandler . loadingToProgress
                    noProgress _ = pure ()
                    noReady _ = pure ()
                ProjectRoot projectRoot <- ask
                result <- trySync
                    $ withGhciProcess def (Command $ "cabal repl " <> renderTestTarget target) projectRoot onProgress noReady \ghci _ ->
                        case testTimeout of
                            TestTimeout secs | secs <= 0 -> Right <$> execGhci ghci ":main" noProgress
                            TestTimeout secs ->
                                let duration = fromIntegral secs :: Second
                                in  maybeToRight secs
                                        <$> timeout duration (execGhci ghci ":main" noProgress)
                case result of
                    Left ex ->
                        pure
                            $ Test.SuiteErrored
                            $ Test.SuiteError {message = show ex}
                    Right (Left secs) -> do
                        Log.warn
                            $ mconcat
                                [ "Test suite "
                                , renderTestTarget target
                                , " timed out after "
                                , show secs
                                , "s"
                                ]
                        pure
                            $ Test.SuiteErrored
                            $ Test.SuiteError
                                { message = "Test suite timed out after " <> show secs <> "s"
                                }
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
runScripted
    :: forall es a
     . (IOE :> es)
    => [Either SomeException Test.Suite]
    -> Eff (TestRunner : es) a
    -> Eff es a
runScripted results =
    reinterpret_
        (evalState results)
        (\(RunTestSuite _ _ _) -> popResult)
  where
    popResult :: Eff (State [Either SomeException Test.Suite] : es) Test.Suite
    popResult =
        get >>= \case
            [] -> error "TestRunnerScripted: no more results in queue"
            Left ex : rest -> put rest >> liftIO (throwIO ex)
            Right r : rest -> put rest >> pure r


loadingToProgress :: GhciLoading -> Test.Suite
loadingToProgress loading =
    Test.SuiteRunning
        $ Just
        $ Test.Progress {compiled = loading.index, total = loading.total}


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
