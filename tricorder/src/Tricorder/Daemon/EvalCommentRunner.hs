module Tricorder.Daemon.EvalCommentRunner
    ( -- * Effect
      EvalCommentRunner (..)
    , evaluateComments
    , findEvalCommentsInModules

      -- * Interpreters
    , run
    ) where

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem, readFileBs)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process)
import Atelier.Effects.Timeout (Timeout)
import Data.Default (def)
import Data.Text.Encoding (decodeUtf8Lenient)
import Data.Traversable (for)
import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Dispatch.Dynamic (interpretWith_)
import Effectful.Exception (trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.TH (makeEffect)

import Atelier.Effects.Log qualified as Log
import Data.Map.Strict qualified as Map
import Data.Text qualified as T

import Tricorder.Daemon.GhciSession.GhciParser (LoadedModule (..))
import Tricorder.Daemon.GhciSession.GhciProcess (execGhci, withGhciProcess)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Command (Command (..), Repl)

import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Session.Target qualified as Target


data EvalCommentRunner :: Effect where
    -- | Scan all loaded source files for eval comments and evaluate them, each
    -- in a fresh GHCi session started in that file's module context.
    EvaluateComments
        :: Repl
        -> NonEmpty (LoadedModule, NonEmpty Eval.Comment)
        -> EvalCommentRunner m (NonEmpty Eval.Evaluation)
    -- | Extract eval comments from provided source files. Returns a map of all
    -- files that have at least 1 eval comment.
    FindEvalCommentsInModules
        :: Map FilePath LoadedModule
        -> EvalCommentRunner m [(LoadedModule, NonEmpty Eval.Comment)]


makeEffect ''EvalCommentRunner


-- | Production interpreter: spawns one short-lived @cabal repl@ session per
-- source file that contains at least one eval comment, then runs each
-- eval comment in that module's context.
run
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       , FileSystem :> es
       , Log :> es
       , Process :> es
       , Reader ProjectRoot :> es
       , Timeout :> es
       )
    => Eff (EvalCommentRunner : es) a -> Eff es a
run act = do
    interpretWith_ act \case
        FindEvalCommentsInModules loadedModules -> do
            concat <$> for (Map.toList loadedModules) \(absPath, lm) -> do
                fileResult <- trySync $ readFileBs absPath
                pure $ case fileResult of
                    Left _ -> []
                    Right bs ->
                        case Eval.findComments $ decodeUtf8Lenient bs of
                            [] -> []
                            x : xs -> [(lm, x :| xs)]
        EvaluateComments repl moduleComments -> do
            fmap sconcat $ for moduleComments \(lm, comments) -> do
                runFileEvals
                    repl
                    lm.relPath
                    lm.moduleName
                    comments


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
       , Reader ProjectRoot :> es
       , Timeout :> es
       )
    => Repl
    -> FilePath
    -- ^ Relative path to the source file (stored in results).
    -> Text
    -- ^ Module name (e.g. @"Tricorder.Builder"@), used to load the module
    -- in interpreted mode so that its full local scope is available.
    -> NonEmpty Eval.Comment
    -> Eff es (NonEmpty Eval.Evaluation)
runFileEvals repl relPath moduleName comments = do
    ProjectRoot projectRoot <- ask
    let noProgress = \_ -> pure ()
        noSetup = \_ -> pure ()
        wrapForGhci expr
            | T.elem '\n' expr = ":{" <> "\n" <> expr <> "\n" <> ":}"
            | otherwise = expr
    sessionResult <- trySync
        $ withGhciProcess def (Command repl [] [Target.Bare moduleName]) projectRoot noProgress noSetup \ghci _ -> do
            _ <- execGhci ghci (":m *" <> moduleName) noProgress
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
        Right results -> pure results
        Left ex -> do
            let errMsg =
                    "EvalRunner: session startup failed for "
                        <> toText relPath
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
