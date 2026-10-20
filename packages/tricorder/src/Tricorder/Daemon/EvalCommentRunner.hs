module Tricorder.Daemon.EvalCommentRunner
    ( -- * Effect
      EvalCommentRunner (..)
    , evaluateComments
    , findEvalCommentsInModules

      -- * Interpreters
    , run
    )
where

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem, readFileBs)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process)
import Atelier.Effects.Timeout (Timeout)
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

import Tricorder.Daemon.Ghci.LoadedModule (LoadedModule (..))
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Stage.Eval.Session (EvalSession (..))

import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Daemon.Ghci.LoadedModule qualified as Ghci (LoadedModule)
import Tricorder.Daemon.Ghci.Process qualified as Ghci.Process
import Tricorder.Session.Stage.Eval.Command qualified as EvalCommand
import Tricorder.Session.Target qualified as Target


data EvalCommentRunner :: Effect where
    -- | Scan all loaded source files for eval comments and evaluate them, each
    -- in a fresh GHCi session started in that file's module context.
    EvaluateComments
        :: EvalSession
        -> NonEmpty (Ghci.LoadedModule, NonEmpty Eval.Comment)
        -> EvalCommentRunner m (NonEmpty Eval.Evaluation)
    -- | Extract eval comments from provided source files. Returns a map of all
    -- files that have at least 1 eval comment.
    FindEvalCommentsInModules
        :: Map FilePath Ghci.LoadedModule
        -> EvalCommentRunner m [(Ghci.LoadedModule, NonEmpty Eval.Comment)]


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
        EvaluateComments session moduleComments -> do
            fmap sconcat $ for moduleComments \(lm, comments) ->
                runFileEvals session lm.relPath lm.moduleName comments


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
    => EvalSession
    -> FilePath
    -- ^ Relative path to the source file (stored in results).
    -> Text
    -> NonEmpty Eval.Comment
    -> Eff es (NonEmpty Eval.Evaluation)
runFileEvals session relPath moduleName comments = do
    ProjectRoot projectRoot <- ask
    let noProgress = \_ -> pure ()
        noSetup = \_ -> pure ()
        wrapForGhci expr
            | T.elem '\n' expr = ":{" <> "\n" <> expr <> "\n" <> ":}"
            | otherwise = expr
        command = EvalCommand.render session.commandTemplate [Target.Bare moduleName]
    sessionResult <- trySync
        $ Ghci.Process.with session.ghci command projectRoot noProgress noSetup \ghci _ -> do
            _ <- Ghci.Process.exec ghci (":m *" <> moduleName) noProgress
            for comments \comment -> do
                outputResult <- trySync $ Ghci.Process.exec ghci (wrapForGhci comment.expression) noProgress
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
