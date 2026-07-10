module Tricorder.Effects.EvalCommentRunner
    ( -- * Effect
      EvalCommentRunner (..)
    , evaluateComments
    , findEvalCommentsInModules
    , interruptCurrent
    , resetAbort
    , isAborted

      -- * Interpreters
    , runEvalCommentRunnerIO
    , runEvalCommentRunnerNoOp
    ) where

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem, readFileBs)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process)
import Atelier.Effects.Timeout (Timeout)
import Control.Concurrent.STM (TVar, readTVar, writeTVar)
import Data.Default (def)
import Data.Text.Encoding (decodeUtf8Lenient)
import Data.Traversable (for)
import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically, newTVarIO)
import Effectful.Dispatch.Dynamic (interpretWith_, interpret_)
import Effectful.Exception (bracket_, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.TH (makeEffect)

import Atelier.Effects.Log qualified as Log
import Data.Map.Strict qualified as Map
import Data.Text qualified as T

import Tricorder.Effects.GhciSession.GhciParser (LoadedModule (..))
import Tricorder.Effects.GhciSession.GhciProcess
    ( GhciProcess
    , execGhci
    , terminateGhciProcess
    , withGhciProcess
    )
import Tricorder.Effects.SessionStore (SessionStore)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Command, Session (..))

import Tricorder.BuildState.EvalComments qualified as Eval
import Tricorder.Effects.SessionStore qualified as SessionStore


data EvalCommentRunner :: Effect where
    -- | Scan all loaded source files for eval comments and evaluate them, each
    -- in a fresh GHCi session started in that file's module context.
    EvaluateComments
        :: Map FilePath (LoadedModule, NonEmpty Eval.Comment)
        -> EvalCommentRunner m [Eval.Evaluation]
    FindEvalCommentsInModules
        :: Map FilePath LoadedModule
        -> EvalCommentRunner m (Map FilePath (LoadedModule, NonEmpty Eval.Comment))
    -- | Terminate the GHCi process currently running an eval (if any) and
    -- latch the abort flag so that subsequent per-file evaluations
    -- short-circuit until 'ResetAbort' is called.
    InterruptCurrent :: EvalCommentRunner m ()
    -- | Clear the abort flag. Call this at the start of a new eval run.
    ResetAbort :: EvalCommentRunner m ()
    -- | Read the abort flag without clearing it.
    IsAborted :: EvalCommentRunner m Bool


makeEffect ''EvalCommentRunner


-- | Production interpreter: spawns one short-lived @cabal repl@ session per
-- source file that contains at least one eval comment, then runs each
-- eval comment in that module's context.
runEvalCommentRunnerIO
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       , FileSystem :> es
       , Log :> es
       , Process :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , Timeout :> es
       )
    => Eff (EvalCommentRunner : es) a -> Eff es a
runEvalCommentRunnerIO act = do
    currentProcRef <- newTVarIO (Nothing :: Maybe GhciProcess)
    abortedRef <- newTVarIO False
    interpretWith_ act \case
        InterruptCurrent -> do
            mProc <- atomically do
                writeTVar abortedRef True
                readTVar currentProcRef
            for_ mProc terminateGhciProcess
        ResetAbort -> atomically (writeTVar abortedRef False)
        IsAborted -> atomically (readTVar abortedRef)
        FindEvalCommentsInModules loadedModules -> do
            Map.fromList . concat <$> for (Map.toList loadedModules) \(absPath, lm) -> do
                fileResult <- trySync $ readFileBs absPath
                pure $ case fileResult of
                    Left _ -> []
                    Right bs ->
                        case Eval.findComments $ decodeUtf8Lenient bs of
                            [] -> []
                            x : xs -> [(absPath, (lm, x :| xs))]
        EvaluateComments modulesWithComments -> do
            ProjectRoot projectRoot <- ask
            session <- SessionStore.get
            let go [] acc = pure acc
                go ((absPath, (lm, comments)) : rest) acc = do
                    aborted <- atomically (readTVar abortedRef)
                    if aborted then
                        pure acc
                    else do
                        res <- runFileEvals currentProcRef session.command projectRoot absPath lm.relPath lm.moduleName comments
                        abortedNow <- atomically (readTVar abortedRef)
                        if abortedNow then
                            pure acc
                        else
                            go rest (acc <> toList res)
            go (Map.toList modulesWithComments) []


-- | Inert interpreter for testing: always returns empty results.
runEvalCommentRunnerNoOp :: Eff (EvalCommentRunner : es) a -> Eff es a
runEvalCommentRunnerNoOp = interpret_ \case
    EvaluateComments _ -> pure []
    FindEvalCommentsInModules _ -> pure Map.empty
    InterruptCurrent -> pure ()
    ResetAbort -> pure ()
    IsAborted -> pure False


-- ---------------------------------------------------------------------------
-- Internal helpers

-- | Spawn a fresh @cabal repl@ session for one source file and run all of its
-- eval comments in that module's context. Returns an 'Evaluation' for each
-- comment; on session startup failure returns a single error evaluation.
--
-- The process is registered in @currentProcRef@ as soon as @cabal repl@ has
-- it running (before the initial compile drain), so that a concurrent
-- 'InterruptCurrent' can terminate it promptly.
runFileEvals
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       , Log :> es
       , Process :> es
       , Timeout :> es
       )
    => TVar (Maybe GhciProcess)
    -> Command
    -> FilePath
    -- ^ Project root (working directory for the GHCi process).
    -> FilePath
    -- ^ Absolute path to the source file (for logging and error results).
    -> FilePath
    -- ^ Relative path to the source file (stored in results).
    -> Text
    -- ^ Module name (e.g. @"Tricorder.Builder"@), used to load the module
    -- in interpreted mode so that its full local scope is available.
    -> NonEmpty Eval.Comment
    -> Eff es (NonEmpty Eval.Evaluation)
runFileEvals currentProcRef cmd projectRoot absPath relPath moduleName comments = do
    let noProgress = \_ -> pure ()
        wrapForGhci expr
            | T.elem '\n' expr = ":{" <> "\n" <> expr <> "\n" <> ":}"
            | otherwise = expr
        onReady ghci = atomically (writeTVar currentProcRef (Just ghci))
    sessionResult <- trySync
        $ bracket_
            (pure ())
            (atomically (writeTVar currentProcRef Nothing))
        $ withGhciProcess def cmd projectRoot noProgress onReady \ghci _ -> do
            _ <- execGhci ghci (":load *" <> moduleName) noProgress
            for comments \comment -> do
                outputResult <- trySync $ execGhci ghci (wrapForGhci comment.expression) noProgress
                pure
                    Eval.Evaluation
                        { file = relPath
                        , comment
                        , state = Eval.Completed $ case outputResult of
                            Left ex -> "error: " <> toText (displayException ex)
                            Right ls -> T.unlines ls
                        }
    case sessionResult of
        Left ex -> do
            let errMsg =
                    "EvalRunner: session startup failed for "
                        <> toText absPath
                        <> ": "
                        <> toText (displayException ex)
            Log.warn errMsg
            pure
                $ Eval.Evaluation
                    { file = relPath
                    , comment =
                        Eval.Comment
                            { lineNumber = 0
                            , expression = "<no expression>"
                            }
                    , state = Eval.Completed errMsg
                    }
                    :| []
        Right results -> pure results
