module Tricorder.Daemon.Core (main) where

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process)
import Atelier.Effects.PubSub.Pub (Pub)
import Atelier.Effects.PubSub.Sub (Sub)
import Effectful.Concurrent.STM
    ( Concurrent
    , STM
    , TVar
    , atomically
    , modifyTVar'
    , newTVarIO
    , readTVar
    , retry
    )
import Effectful.Reader.Static (Reader)
import Effectful.State.Static.Shared (State)
import Relude.Extra.Tuple (dup)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.FileWatcher.Event qualified as Event
import Atelier.Effects.FileWatcher.Event qualified as FileWatcher (Event)
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.PubSub qualified as PubSub
import Atelier.Effects.PubSub.Pub qualified as Pub
import Atelier.Effects.PubSub.Sub qualified as Sub
import Atelier.FileSystem.Path qualified as Path
import Data.Map.Strict qualified as Map
import Effectful.Reader.Static qualified as Reader
import Effectful.State.Static.Shared qualified as State

import Tricorder.Build.Changes (ProjectChangeDetected (..), SourceChangeDetected (..))
import Tricorder.Build.Diagnostic (Diagnostic (..))
import Tricorder.Build.PostBuild (PostBuild (..))
import Tricorder.Daemon.Builder
    ( BuildConsideration (..)
    , BuildFailure
    , Builder
    , NewLoadResult
    , compileBuildResults
    )
import Tricorder.Daemon.Dispatch (BuilderState (..), emptyBuilderState, planActions)
import Tricorder.Daemon.EvalCommentRunner (EvalCommentRunner, findEvalCommentsInModules)
import Tricorder.Daemon.Ghci.LoadedModule (LoadedModule (..))
import Tricorder.Daemon.TestRunner (TestRunner)
import Tricorder.Runtime.ProjectRoot (ProjectRoot)
import Tricorder.Session (Session (..))
import Tricorder.Session.Stage.Test.Command (RenderedTestCommand (..))
import Tricorder.Waiters (Waiters)

import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Id qualified as Build (Id (..))
import Tricorder.Build.Phase qualified as Build (Phase)
import Tricorder.Build.Phase qualified as Phase
import Tricorder.Build.Result qualified as Build (Result (..))
import Tricorder.Build.Severity qualified as Severity
import Tricorder.Build.Test qualified as Test
import Tricorder.Daemon.Builder qualified as Builder
import Tricorder.Daemon.EvalCommentRunner qualified as EvalCommentRunner
import Tricorder.Daemon.Ghci.LoadResult qualified as Ghci (LoadResult)
import Tricorder.Daemon.Ghci.LoadResult qualified as Ghci.LoadResult
import Tricorder.Daemon.Ghci.Session qualified as Ghci (Session)
import Tricorder.Daemon.TestRunner qualified as TestRunner
import Tricorder.Session.Hook qualified as Hook
import Tricorder.Session.Hooks qualified as Hooks
import Tricorder.Session.Stage.Build.Command qualified as Build.Command
import Tricorder.Session.Stage.Build.Session qualified as Build.Session
import Tricorder.Session.Stage.Test.Command qualified as Test.Command
import Tricorder.Session.Stage.Test.Session qualified as Test (Session)
import Tricorder.Session.Stage.Test.Session qualified as Test.Session
import Tricorder.Session.TestTarget qualified as TestTarget
import Tricorder.Waiters qualified as Waiters


data RestartBuilder = RestartBuilder


data ReloadBuilder = ReloadBuilder Path.Any FileWatcher.Event


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
       , Pub Build.Phase :> es
       , Reader ProjectRoot :> es
       , State Build.Id :> es
       , Sub ProjectChangeDetected :> es
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

            Conc.fork_ $ Sub.listen_ \(ProjectChangeDetected _ _) ->
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
       , Pub Build.Phase :> es
       , Reader ProjectRoot :> es
       , Sub ReloadBuilder :> es
       , TestRunner :> es
       , Waiters :> es
       )
    => Build.Id -> Session -> Eff es ()
runBuilder buildId session = State.evalState emptyBuilderState do
    Log.info $ "Starting session " <> show buildId.getId
    Pub.publish Phase.Starting
    whenJust (session.hooks.start >>= (.before)) Hook.run
    startupError <- fmap (either id absurd)
        $ Pub.map (Phase.Building $ Test.Session.targets session.testSession)
        $ Builder.with buildId session.buildSession.ghci buildCommand session.watchDirs \_ initialLoad -> do
            whenJust (session.hooks.start >>= (.after)) Hook.run
            processPostBuild session $ Right initialLoad
            Log.debug "Waiting for reload"
            pending <- newTVarIO emptyPending
            Conc.fork_ $ Sub.listen_ @ReloadBuilder \event -> do
                Log.debug "Got request to reload builder"
                atomically $ modifyTVar' pending (addPending event)

            -- Events stay pending until a build that covered them has finished,
            -- so a build cancelled by a newer event is redone with both.
            forever do
                batch <- atomically $ takeBatch pending
                Conc.scoped do
                    _ <- Conc.fork do
                        processBatch session $ snd <$> batch.items
                        atomically $ modifyTVar' pending (dropCovered batch)
                    -- Return (cancelling the build, if it is still running) as
                    -- soon as an event newer than the batch shows up. If a
                    -- build is currently running, it will be restarted, not
                    -- dropped.
                    atomically $ waitForNewerThan batch pending

    Pub.publish $ Phase.Failed $ toText $ displayException startupError
  where
    buildCommand =
        Build.Command.render
            (Build.Session.commandTemplate session.buildSession)
            session.buildSession.targets


-- | Handles a batch of source changes, determining which of them warrant a
-- rebuild, and what GHCi needs to do about them.
processBatch
    :: ( Builder :> es
       , Conc :> es
       , EvalCommentRunner :> es
       , Log :> es
       , Process :> es
       , Pub Build.Phase :> es
       , Reader ProjectRoot :> es
       , State BuilderState :> es
       , TestRunner :> es
       , Waiters :> es
       )
    => Session -> [ReloadBuilder] -> Eff es ()
processBatch session events = do
    considered <- forM (Event.collapse [(fp, event) | ReloadBuilder fp event <- events]) \(fp, event) -> do
        Log.debug $ "Considering " <> toText fp
        consideration <- Builder.consider fp event
        case consideration of
            SkipBuilding -> do
                Log.debug $ "Skipping " <> toText fp
                pure Nothing
            ShouldBuild action -> do
                Log.debug $ "Should build " <> toText fp
                pure $ Just action
    case nonEmpty $ planActions $ catMaybes considered of
        Nothing -> Log.debug "Nothing to build"
        Just actions -> do
            -- Only flip the phase once we know a build will follow.
            Waiters.without $ Pub.publish Phase.Starting
            whenJust (session.hooks.reload >>= (.before)) Hook.run
            let fullAction = last actions
                intermediateActions = init actions

            -- Process intermediate changes in GHCi first. Usually there is a
            -- single action, so there are no intermediate actions to run. Only
            -- drive GHCi (and fold their diagnostics into the state) for the
            -- intermediate changes.
            for_ intermediateActions \action -> do
                res <- Builder.build action
                Log.debug $ "Finished intermediate build: " <> show action
                for_ (rightToMaybe res) \newLoadResult ->
                    void $ newLoadResultToBuildResult session newLoadResult

            -- Fully process the last change.
            result <- Builder.build fullAction
            Log.debug $ "Finished build: " <> show fullAction
            whenJust (session.hooks.reload >>= (.after)) Hook.run
            processPostBuild session result
    Log.info "Reload finished"


processPostBuild
    :: ( Conc :> es
       , EvalCommentRunner :> es
       , Log :> es
       , Pub Build.Phase :> es
       , Reader ProjectRoot :> es
       , State BuilderState :> es
       , TestRunner :> es
       )
    => Session -> Either BuildFailure NewLoadResult -> Eff es ()
processPostBuild session = \case
    Left buildFailure -> do
        Log.debug "Build failure"
        Pub.publish $ Phase.Failed $ show buildFailure
    Right newLoadResult -> do
        Log.debug "Built"
        buildResult <- newLoadResultToBuildResult session newLoadResult
        let initialPostBuild = PostBuild mempty Eval.Looking
        Pub.publish $ Phase.PostBuilding buildResult initialPostBuild
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
            Pub.publish $ Phase.Finished buildResult $ PostBuild tests evalComments
  where
    updateEvalComments buildResult evalComments = do
        newPostBuild <- State.state \postBuild -> dup $ postBuild {evalComments}
        Pub.publish $ Phase.PostBuilding buildResult newPostBuild
    updateTestSuites buildResult testSuites = do
        newPostBuild <- State.state \postBuild -> dup $ postBuild {testSuites}
        Pub.publish $ Phase.PostBuilding buildResult newPostBuild


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
    => Session -> Build.Result -> Eff es Test.Suites
runTests session buildResult
    | hasTargets session.testSession.targets && noErrors buildResult.diagnostics =
        runTestsForTargets session.testSession
    | otherwise = pure mempty
  where
    hasTargets = not . null
    noErrors = all \d -> d.severity /= Severity.Error


runTestsForTargets
    :: ( Log :> es
       , Pub Test.Suites :> es
       , TestRunner :> es
       )
    => Test.Session
    -> Eff es Test.Suites
runTestsForTargets testSession = do
    Pub.publish $ Test.Suites initial
    Log.info $ "Running " <> show (length testSession.targets) <> " test suite(s)"
    fmap Test.Suites . State.execState initial $ traverse_ go testSession.targets
  where
    initial = Map.fromList $ (,Test.SuiteRunning Nothing) <$> testSession.targets
    go target = do
        Log.info $ "Running tests: " <> renderedTarget
        let testCommand = Test.Command.render testSession target
            publishProgress suite = do
                updated <- State.state $ dup . Map.insert target suite
                Pub.publish $ Test.Suites updated
        Log.info
            $ "Test suite "
                <> renderedTarget
                <> " command:\n"
                <> show testCommand.command
        finishedSuite <- TestRunner.runTestSuite testSession publishProgress testCommand
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
    => Session -> NewLoadResult -> Eff es Build.Result
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


-- | Source events waiting for a build to cover them. Each gets an increasing
-- id so a batch can tell which events are newer than it.
data Pending = Pending
    { nextId :: Int
    , events :: [(Int, ReloadBuilder)]
    }


-- | A snapshot of the pending events, taken when a build starts.
data Batch = Batch
    { newestId :: Int
    , items :: [(Int, ReloadBuilder)]
    }


emptyPending :: Pending
emptyPending =
    Pending
        { nextId = 0
        , events = []
        }


addPending :: ReloadBuilder -> Pending -> Pending
addPending event p =
    Pending
        { nextId = p.nextId + 1
        , events = p.events <> [(p.nextId, event)]
        }


-- | Blocks until there is something pending, then snapshots it.
takeBatch :: TVar Pending -> STM Batch
takeBatch pending = do
    p <- readTVar pending
    when (null p.events) retry
    pure
        Batch
            { newestId = foldl' (\m -> max m . fst) 0 p.events
            , items = p.events
            }


-- | Blocks until an event newer than the batch is pending.
waitForNewerThan :: Batch -> TVar Pending -> STM ()
waitForNewerThan batch pending = do
    p <- readTVar pending
    unless (any ((> batch.newestId) . fst) p.events) retry


-- | Forgets the events a finished build covered, keeping any newer ones.
dropCovered :: Batch -> Pending -> Pending
dropCovered batch p =
    p
        { events = filter ((> batch.newestId) . fst) p.events
        }
