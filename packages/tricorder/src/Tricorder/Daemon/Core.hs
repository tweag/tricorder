module Tricorder.Daemon.Core (main) where

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.FileWatcher (FileEvent)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process)
import Atelier.Effects.PubSub.Pub (Pub)
import Atelier.Effects.PubSub.Sub (Sub)
import Effectful.Concurrent.MVar (newEmptyMVar, takeMVar, tryPutMVar)
import Effectful.Concurrent.STM (Concurrent, atomically, newEmptyTMVar, takeTMVar, writeTMVar)
import Effectful.Reader.Static (Reader)
import Effectful.State.Static.Shared (State)
import Relude.Extra.Tuple (dup)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.PubSub qualified as PubSub
import Atelier.Effects.PubSub.Pub qualified as Pub
import Atelier.Effects.PubSub.Sub qualified as Sub
import Data.Map.Strict qualified as Map
import Effectful.Reader.Static qualified as Reader
import Effectful.State.Static.Shared qualified as State

import Tricorder.Build (BuildId, BuildPhase, BuildResult, PostBuild (..), Severity (..))
import Tricorder.Build.ByteSize (ByteSize)
import Tricorder.Build.Changes (CabalChangeDetected (..), SourceChangeDetected (..))
import Tricorder.Daemon.Builder
    ( BuildConsideration (..)
    , BuildFailure
    , Builder
    , NewLoadResult
    , compileBuildResults
    )
import Tricorder.Daemon.Dispatch (BuilderState (..), DispatchAction, emptyBuilderState)
import Tricorder.Daemon.EvalCommentRunner (EvalCommentRunner, findEvalCommentsInModules)
import Tricorder.Daemon.Ghci.LoadedModule (LoadedModule (..))
import Tricorder.Daemon.TestRunner (TestRunner)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..))
import Tricorder.Session.Stage.Build.Session (BuildSession (..))
import Tricorder.Session.Stage.Test.Command (RenderedTestCommand (..))
import Tricorder.Session.Stage.Test.Session (TestSession (..))
import Tricorder.Session.TestTimeout (TestTimeout (..))
import Tricorder.Waiters (Waiters)

import Tricorder.Build qualified as Build
import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Test qualified as Test
import Tricorder.Daemon.Builder qualified as Builder
import Tricorder.Daemon.EvalCommentRunner qualified as EvalCommentRunner
import Tricorder.Daemon.Ghci.LoadResult qualified as Ghci (LoadResult)
import Tricorder.Daemon.Ghci.LoadResult qualified as Ghci.LoadResult
import Tricorder.Daemon.Ghci.Session qualified as Ghci (Session)
import Tricorder.Daemon.TestRunner qualified as TestRunner
import Tricorder.Session.Hook qualified as Hook
import Tricorder.Session.Hooks qualified as Hooks
import Tricorder.Session.Stage.Build.Command qualified as BuildCommand
import Tricorder.Session.Stage.Test.Command qualified as TestCommand
import Tricorder.Session.TestTarget qualified as TestTarget
import Tricorder.Waiters qualified as Waiters


data RestartBuilder = RestartBuilder


data ReloadBuilder = ReloadBuilder FilePath FileEvent


-- | Top of the build loop. Responsible for handling changes to the Tricorder
-- config, as well as setting up other build-specific effects.
main
    :: ( Chan :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , EvalCommentRunner :> es
       , Ghci.Session :> es
       , Log :> es
       , Process :> es
       , Pub BuildPhase :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , Sub CabalChangeDetected :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       , Waiters :> es
       )
    => Session -> Eff es Void
main session =
    PubSub.run @ReloadBuilder
        . PubSub.run @RestartBuilder
        $ Conc.restartableFork (Waiters.wait $ Sub.listenOnce_ @RestartBuilder) do
            buildId <- State.state (\s -> (s, s + 1))

            Conc.fork_ $ Sub.listen_ \(CabalChangeDetected _ _) ->
                Pub.publish RestartBuilder

            Conc.fork_ $ Sub.listen_ \(SourceChangeDetected path event) ->
                Pub.publish $ ReloadBuilder path event

            runBuilder buildId session


-- | Starts the initial build with GHCi, and waits for source changes.
runBuilder
    :: ( Clock :> es
       , Conc :> es
       , Concurrent :> es
       , EvalCommentRunner :> es
       , Ghci.Session :> es
       , Log.Log :> es
       , Process :> es
       , Pub BuildPhase :> es
       , Reader ProjectRoot :> es
       , Sub ReloadBuilder :> es
       , TestRunner :> es
       , Waiters :> es
       )
    => BuildId -> Session -> Eff es ()
runBuilder buildId session = State.evalState emptyBuilderState do
    Log.info $ "Starting session " <> show buildId.getBuildId
    Pub.publish Build.Starting
    whenJust (session.hooks.start >>= (.before)) Hook.run
    startupError <- fmap (either id absurd)
        $ Pub.map (Build.Building session.testSession.targets)
        $ Builder.with buildId buildCommand session.watchDirs \_ initialLoad -> do
            whenJust (session.hooks.start >>= (.after)) Hook.run
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

    Pub.publish $ Build.Failed $ toText $ displayException startupError
  where
    buildCommand = BuildCommand.render session.buildSession.commandTemplate session.buildSession.targets


-- | Handles source changes as they come, determining whether the source change
-- detected warrants a rebuild.
waitForReload
    :: ( Builder :> es
       , Conc :> es
       , EvalCommentRunner :> es
       , Log :> es
       , Process :> es
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
       , Process :> es
       , Pub BuildPhase :> es
       , Reader ProjectRoot :> es
       , State BuilderState :> es
       , TestRunner :> es
       )
    => Session
    -> DispatchAction
    -> Eff es ()
processSource session action = do
    whenJust (session.hooks.reload >>= (.before)) Hook.run
    res <- Builder.build action
    whenJust (session.hooks.reload >>= (.after)) Hook.run
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
    => Session -> Ghci.LoadResult -> Eff es Eval.Phase
runEvalComments session loadResult = do
    builderState <- State.get @BuilderState
    evalComments <-
        findEvalCommentsInModules
            $ Ghci.LoadResult.resolveKnownTargets builderState.loadedModules loadResult

    case nonEmpty evalComments of
        Nothing -> pure Eval.NoneFound
        Just nonEmptyComments -> do
            let pendingComments =
                    sconcat $ (\(lm, ecs) -> toPending lm.relPath <$> ecs) <$> nonEmptyComments
            Pub.publish $ Eval.Found $ Eval.Comments pendingComments
            evaluatedComments <- EvalCommentRunner.evaluateComments session.evalSession nonEmptyComments
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
    | hasTargets session.testSession.targets && noErrors buildResult.diagnostics =
        runTestsForTargets
            session.testSession
            session.testMemoryLimit
            session.testTimeout
    | otherwise = pure mempty
  where
    hasTargets = not . null
    noErrors = all \d -> d.severity /= SError


runTestsForTargets
    :: ( Log :> es
       , Pub Test.Suites :> es
       , TestRunner :> es
       )
    => TestSession
    -> Maybe ByteSize
    -> TestTimeout
    -> Eff es Test.Suites
runTestsForTargets testSession memoryLimit testTimeout = do
    Pub.publish $ Test.Suites initial
    Log.info $ "Running " <> show (length testSession.targets) <> " test suite(s)"
    fmap Test.Suites . State.execState initial $ traverse_ go testSession.targets
  where
    initial = Map.fromList $ (,Test.SuiteRunning Nothing) <$> testSession.targets
    go target = do
        Log.info $ "Running tests: " <> renderedTarget
        let testCommand = TestCommand.render testSession memoryLimit target
            publishProgress suite = do
                updated <- State.state $ dup . Map.insert target suite
                Pub.publish $ Test.Suites updated
        Log.info
            $ "Test suite "
                <> renderedTarget
                <> " command:\n"
                <> show testCommand.command
        finishedSuite <- TestRunner.runTestSuite publishProgress testTimeout testCommand
        case finishedSuite of
            Test.SuiteErrored (Test.SuiteError message) ->
                Log.warn $ "Test suite " <> renderedTarget <> "failed: " <> message
            _ ->
                pure ()
        updated <- State.state $ dup . Map.insert target finishedSuite
        Pub.publish $ Test.Suites updated
      where
        renderedTarget = TestTarget.render target


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
