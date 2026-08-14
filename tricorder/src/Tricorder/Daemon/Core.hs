module Tricorder.Daemon.Core (main) where

import Atelier.Config (LoadedConfig)
import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.FileWatcher (FileEvent, FileWatcher)
import Atelier.Effects.Input (Input)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Publishing (runPubSub)
import Atelier.Effects.Publishing.Pub (Pub)
import Atelier.Effects.Publishing.Sub (Sub)
import Data.List (isSuffixOf)
import Effectful.Concurrent.MVar (newEmptyMVar, takeMVar, tryPutMVar)
import Effectful.Concurrent.STM (Concurrent, atomically, newEmptyTMVar, takeTMVar, writeTMVar)
import Effectful.Reader.Static (Reader)
import Effectful.State.Static.Shared (State)
import Relude.Extra.Tuple (dup)
import System.FilePath ((</>))

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.FileSystem qualified as FileSystem
import Atelier.Effects.FileWatcher qualified as FileWatcher
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Publishing.Pub qualified as Pub
import Atelier.Effects.Publishing.Sub qualified as Sub
import Data.Map.Strict qualified as Map
import Effectful.Reader.Static qualified as Reader
import Effectful.State.Static.Shared qualified as State

import Tricorder.Build (BuildId, BuildPhase, BuildResult, PostBuild (..), Severity (..))
import Tricorder.Build.Changes (CabalChangeDetected (..), SourceChangeDetected (..))
import Tricorder.Daemon.Builder
    ( BuildConsideration (..)
    , BuildFailure
    , Builder
    , NewLoadResult
    , compileBuildResults
    )
import Tricorder.Daemon.Dispatch
    ( BuilderState (..)
    , DispatchAction
    , emptyBuilderState
    )
import Tricorder.Daemon.EvalCommentRunner
    ( EvalCommentRunner
    , findEvalCommentsInModules
    )
import Tricorder.Daemon.GhciSession (GhciSession)
import Tricorder.Daemon.GhciSession.GhciParser
    ( LoadResult
    , LoadedModule (..)
    , resolveKnownTargets
    )
import Tricorder.Daemon.Hpack.Effect (Hpack)
import Tricorder.Daemon.TestRunner (TestRunner)
import Tricorder.Daemon.Watch (WatchedFile)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..), loadSession)
import Tricorder.Session.CabalFile (CabalFile)
import Tricorder.Session.Command (Command (..))
import Tricorder.Session.GenerateWithHpack (GenerateWithHpack (..))
import Tricorder.Session.TestTarget (TestTarget, renderTestTarget)
import Tricorder.Session.TestTimeout (TestTimeout)
import Tricorder.Waiters (Waiters)

import Tricorder.Build qualified as Build
import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Test qualified as Test
import Tricorder.Config qualified as Config
import Tricorder.Daemon.Builder qualified as Builder
import Tricorder.Daemon.EvalCommentRunner qualified as EvalCommentRunner
import Tricorder.Daemon.Hpack qualified as Hpack
import Tricorder.Daemon.TestRunner qualified as TestRunner
import Tricorder.Daemon.Watch qualified as Watch
import Tricorder.Waiters qualified as Waiters


data ReloadSession = ReloadSession
data RestartBuilder = RestartBuilder
data ReloadBuilder = ReloadBuilder FilePath FileEvent


-- | Top of the build loop. Responsible for handling changes to the Tricorder
-- config, as well as setting up other build-specific effects.
main
    :: ( Chan :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce FilePath :> es
       , EvalCommentRunner :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhciSession :> es
       , Hpack :> es
       , Input LoadedConfig :> es
       , Input [CabalFile] :> es
       , Log :> es
       , Pub BuildPhase :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , TestRunner :> es
       , Waiters :> es
       )
    => Eff es Void
main = runPubSub @ReloadSession
    . runPubSub @WatchedFile
    . runPubSub @CabalChangeDetected
    . runPubSub @SourceChangeDetected
    . runPubSub @RestartBuilder
    . runPubSub @ReloadBuilder
    $ Conc.restartableFork waitForReloadSession do
        root <- Reader.ask
        session <- loadSession
        Conc.fork_ $ watchConfigFile root
        conditionallyWatchStackYaml root

        Conc.fork_ $ Watch.files root session
        Conc.fork_ $ Sub.listen_ Watch.publishChange

        Conc.fork_ $ Sub.listen_ \(CabalChangeDetected _ _) -> do
            needsSessionReload <- shouldReloadSession session
            if needsSessionReload then
                Pub.publish ReloadSession
            else
                Pub.publish RestartBuilder

        Conc.fork_ $ Sub.listen_ \(SourceChangeDetected fp event) ->
            Pub.publish $ ReloadBuilder fp event

        when session.generateWithHpack.getGenerateWithHpack do
            void $ Conc.fork Hpack.main

        State.evalState emptyBuilderState $ withSession session
  where
    waitForReloadSession = Waiters.wait $ Sub.listenOnce_ @ReloadSession


shouldReloadSession
    :: ( FileSystem :> es
       , Input LoadedConfig :> es
       , Input [CabalFile] :> es
       , Log :> es
       , Reader ProjectRoot :> es
       )
    => Session -> Eff es Bool
shouldReloadSession oldSession = do
    newSession <- loadSession
    pure $ newSession /= oldSession


watchConfigFile
    :: ( Debounce FilePath :> es
       , FileWatcher :> es
       , Pub ReloadSession :> es
       )
    => ProjectRoot -> Eff es Void
watchConfigFile root = do
    FileWatcher.watchFilePathsDebounced
        [FileWatcher.dirWhere root.getProjectRoot (Config.configFileName `isSuffixOf`)]
        \_ _ -> Pub.publish ReloadSession


conditionallyWatchStackYaml
    :: ( Conc :> es
       , Debounce FilePath :> es
       , FileSystem :> es
       , FileWatcher :> es
       , Pub RestartBuilder :> es
       )
    => ProjectRoot -> Eff es ()
conditionallyWatchStackYaml root = do
    exists <- FileSystem.doesFileExist $ root.getProjectRoot </> "stack.yaml"
    when exists do
        Conc.fork_ $ FileWatcher.watchFilePathsDebounced
            [FileWatcher.dirWhere root.getProjectRoot ("stack.yaml" `isSuffixOf`)]
            \_ _ -> Pub.publish RestartBuilder


-- | For a given session, handles controlling the build process itself,
-- restarting it as necessary.
withSession
    :: ( Clock :> es
       , Conc :> es
       , Concurrent :> es
       , EvalCommentRunner :> es
       , GhciSession :> es
       , Log :> es
       , Pub BuildPhase :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub ReloadBuilder :> es
       , Sub RestartBuilder :> es
       , TestRunner :> es
       , Waiters :> es
       )
    => Session -> Eff es Void
withSession session = do
    Conc.restartableFork (Waiters.wait $ Sub.listenOnce_ @RestartBuilder) do
        buildId <- State.state (\s -> (s, s + 1))
        runSession buildId session


-- | Starts the initial build with GHCi, and waits for source changes.
runSession
    :: ( Clock :> es
       , Conc :> es
       , Concurrent :> es
       , EvalCommentRunner :> es
       , GhciSession :> es
       , Log.Log :> es
       , Pub BuildPhase :> es
       , Reader ProjectRoot :> es
       , State BuilderState :> es
       , Sub ReloadBuilder :> es
       , TestRunner :> es
       , Waiters :> es
       )
    => BuildId -> Session -> Eff es ()
runSession buildId session = do
    Log.info $ "Starting session " <> show buildId.getBuildId
    Pub.publish Build.Starting
    startupError <- fmap (either id absurd)
        $ Pub.map (Build.Building session.testTargets)
        $ Builder.with buildId session.command session.watchDirs \_ initialLoad -> do
            processPostBuild session $ Right initialLoad
            Log.debug "Waiting for reload"
            newestReloadEvent <- atomically newEmptyTMVar
            cancelSem <- newEmptyMVar
            let requestCancel = tryPutMVar cancelSem ()
                checkCancel = takeMVar cancelSem
            Conc.fork_ $ Sub.listen_ @ReloadBuilder \event -> do
                atomically $ writeTMVar newestReloadEvent event
                Waiters.without do
                    Pub.publish Build.Starting
                    Log.debug "Cancelling current build"
                    requestCancel
            forever do
                event <- atomically $ takeTMVar newestReloadEvent
                Conc.restartableFork checkCancel
                    $ waitForReload session event

    Pub.publish $ Build.Failed $ show startupError


-- | Handles source changes as they come, determining whether the source change
-- detected warrants a rebuild.
waitForReload
    :: ( Builder :> es
       , Conc :> es
       , EvalCommentRunner :> es
       , Log :> es
       , Pub BuildPhase :> es
       , Reader ProjectRoot :> es
       , State BuilderState :> es
       , TestRunner :> es
       )
    => Session -> ReloadBuilder -> Eff es ()
waitForReload session (ReloadBuilder fp event) = do
    Log.debug $ "Considering " <> toText fp
    consideration <- Builder.consider fp event
    case consideration of
        SkipBuilding -> do
            Log.debug $ "Skipping " <> toText fp
            pure ()
        ShouldBuild action -> do
            Log.debug $ "Should build " <> toText fp
            processSource session action
    Log.info "Reload finished"


-- | Rebuilds the project on source change.
processSource
    :: ( Builder :> es
       , Conc :> es
       , EvalCommentRunner :> es
       , Log :> es
       , Pub BuildPhase :> es
       , Reader ProjectRoot :> es
       , State BuilderState :> es
       , TestRunner :> es
       )
    => Session
    -> DispatchAction
    -> Eff es ()
processSource session action = do
    res <- Builder.build action
    Log.debug "Finished build"
    processPostBuild session res


processPostBuild
    :: ( Conc :> es
       , EvalCommentRunner :> es
       , Log :> es
       , Pub BuildPhase :> es
       , Reader ProjectRoot :> es
       , State BuilderState :> es
       , TestRunner :> es
       )
    => Session -> Either BuildFailure NewLoadResult -> Eff es ()
processPostBuild session = \case
    Left buildFailure -> do
        Log.debug "Build failure"
        Pub.publish $ Build.Failed $ show buildFailure
    Right newLoadResult -> do
        Log.debug "Built"
        buildResult <- newLoadResultToBuildResult session newLoadResult
        let initialPostBuild = PostBuild mempty Eval.Looking
        Pub.publish $ Build.PostBuilding buildResult initialPostBuild
        State.evalState initialPostBuild $ Conc.scoped do
            evalCommentsP <-
                Conc.fork
                    $ Pub.consume (updateEvalComments buildResult)
                    $ runEvalComments session newLoadResult.loadResult
            testsP <-
                Conc.fork
                    $ Pub.consume (updateTestSuites buildResult)
                    $ runTests session buildResult
            evalComments <- Conc.await evalCommentsP
            Log.debug "Eval comments finished"
            tests <- Conc.await testsP
            Log.debug "Tests finished"
            Pub.publish $ Build.Finished buildResult $ PostBuild tests evalComments
  where
    updateEvalComments buildResult evalComments = do
        newPostBuild <- State.state \postBuild -> dup $ postBuild {evalComments}
        Pub.publish $ Build.PostBuilding buildResult newPostBuild
    updateTestSuites buildResult testSuites = do
        newPostBuild <- State.state \postBuild -> dup $ postBuild {testSuites}
        Pub.publish $ Build.PostBuilding buildResult newPostBuild


runEvalComments
    :: ( EvalCommentRunner :> es
       , Pub Eval.Phase :> es
       , State BuilderState :> es
       )
    => Session -> LoadResult -> Eff es Eval.Phase
runEvalComments session loadResult = do
    builderState <- State.get @BuilderState
    evalComments <- findEvalCommentsInModules $ resolveKnownTargets builderState.loadedModules loadResult

    case nonEmpty evalComments of
        Nothing -> pure Eval.NoneFound
        Just nonEmptyComments -> do
            let pendingComments =
                    sconcat $ (\(lm, ecs) -> toPending lm.relPath <$> ecs) <$> nonEmptyComments
            Pub.publish $ Eval.Found $ Eval.Comments pendingComments
            evaluatedComments <- EvalCommentRunner.evaluateComments session.command.repl nonEmptyComments
            pure $ Eval.Found $ Eval.Comments evaluatedComments
  where
    toPending file comment =
        Eval.Evaluation
            { file
            , comment
            , state = Eval.Pending
            }


runTests
    :: ( Log :> es
       , Pub Test.Suites :> es
       , TestRunner :> es
       )
    => Session -> BuildResult -> Eff es Test.Suites
runTests session buildResult
    | hasTargets session.testTargets && noErrors buildResult.diagnostics =
        runTestsForTargets session.command session.testTimeout session.testTargets
    | otherwise = pure mempty
  where
    hasTargets = not . null
    noErrors = all \d -> d.severity /= SError


runTestsForTargets
    :: ( Log :> es
       , Pub Test.Suites :> es
       , TestRunner :> es
       )
    => Command
    -> TestTimeout
    -> [TestTarget]
    -> Eff es Test.Suites
runTestsForTargets command testTimeout testTargets = do
    Pub.publish $ Test.Suites initial
    Log.info $ "Running " <> show (length testTargets) <> " test suite(s)"
    fmap Test.Suites . State.execState initial $ traverse_ go testTargets
  where
    initial = Map.fromList $ (,Test.SuiteRunning Nothing) <$> testTargets
    go target = do
        Log.info $ "Running tests: " <> renderTestTarget target
        finishedSuite <-
            TestRunner.runTestSuite
                ( \suite -> do
                    updated <- State.state $ dup . Map.insert target suite
                    Pub.publish $ Test.Suites updated
                )
                command.repl
                testTimeout
                target
        updated <- State.state $ dup . Map.insert target finishedSuite
        Pub.publish $ Test.Suites updated


newLoadResultToBuildResult
    :: (Reader ProjectRoot :> es, State BuilderState :> es)
    => Session -> NewLoadResult -> Eff es BuildResult
newLoadResultToBuildResult session newLoadResult = do
    root <- Reader.ask
    State.state \s ->
        let (newDiagnosticMap, buildResult) =
                compileBuildResults
                    root
                    session.watchDirs
                    s.diagnosticMap
                    newLoadResult
        in  (buildResult, s {diagnosticMap = newDiagnosticMap})
