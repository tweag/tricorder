module Unit.Tricorder.Effects.BuildStoreSpec (spec_BuildStore) where

import Atelier.Effects.Conc (Conc, runConc)
import Atelier.Effects.Delay (Delay, runDelay)
import Atelier.Effects.Input (Input, runInputConst)
import Control.Concurrent (threadDelay)
import Data.Time (UTCTime (..), fromGregorian)
import Effectful (IOE, runEff, runPureEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.State.Static.Shared (State, execState, modify)
import Test.Hspec

import Atelier.Effects.Conc qualified as Conc

import Tricorder.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , EvalPhase (..)
    , PostBuild (..)
    , TestPhase (..)
    )
import Tricorder.Effects.BuildStore
    ( BuildStore (..)
    , getState
    , runBuildStore
    , runBuildStoreScripted
    , setPhase
    , waitForNext
    , waitUntilDone
    , withPostBuildPhase
    )

import Tricorder.Effects.PostBuildStore qualified as PostBuild


spec_BuildStore :: Spec
spec_BuildStore = do
    describe "runBuildStoreScripted" testScripted
    describe "runBuildStoreSTM" testSTM
    describe "withPostBuildPhase" testWithPostBuildPhase


--------------------------------------------------------------------------------
-- Scripted interpreter tests (pure, no IO)
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    describe "getState" do
        it "returns the head of the state list" do
            let result = runScripted [buildingAt 0, doneAt 1] getState
            result.buildId `shouldBe` BuildId 0

        it "does not consume the state" do
            let result = runScripted [doneAt 1] do
                    _ <- getState
                    getState
            result.buildId `shouldBe` BuildId 1

    describe "waitUntilDone" do
        it "returns immediately when head is already Done" do
            let result = runScripted [doneAt 1, doneAt 2] waitUntilDone
            result.buildId `shouldBe` BuildId 1

        it "skips Building states and returns the first Done" do
            let result = runScripted [buildingAt 0, buildingAt 0, doneAt 1] waitUntilDone
            result.buildId `shouldBe` BuildId 1

        it "consumes states up to and including the matched Done" do
            let result = runScripted [buildingAt 0, doneAt 1, doneAt 2] do
                    _ <- waitUntilDone
                    waitUntilDone
            result.buildId `shouldBe` BuildId 2

    describe "waitForNext" do
        it "skips states with the same buildId" do
            let result = runScripted [doneAt 1, doneAt 2] (waitForNext (BuildId 1))
            result.buildId `shouldBe` BuildId 2

        it "skips Building states regardless of buildId" do
            let result = runScripted [buildingAt 2, doneAt 2] (waitForNext (BuildId 1))
            result.buildId `shouldBe` BuildId 2

        it "skips Building and same-id Done before returning next Done" do
            let states = [buildingAt 1, doneAt 1, buildingAt 2, doneAt 2]
            let result = runScripted states (waitForNext (BuildId 1))
            result.buildId `shouldBe` BuildId 2


--------------------------------------------------------------------------------
-- STM interpreter tests (concurrent)
--------------------------------------------------------------------------------

testSTM :: Spec
testSTM = do
    describe "getState" do
        it "returns the initial Building state" do
            result <- runStm getState
            result `shouldBe` buildingAt 0

    describe "setPhase / getState" do
        it "reflects a written state" do
            result <- runStm do
                setPhase (BuildId 1) donePhase
                getState
            result `shouldBe` doneAt 1

    describe "waitUntilDone" do
        it "returns immediately when state is already Done" do
            result <- runStm do
                setPhase (BuildId 1) donePhase
                waitUntilDone
            result.buildId `shouldBe` BuildId 1

        it "blocks until a Done phase is set from another thread" do
            result <- runStmConc do
                void $ Conc.fork do
                    liftIO (threadDelay 10_000)
                    setPhase (BuildId 1) donePhase
                waitUntilDone
            result.buildId `shouldBe` BuildId 1

    describe "waitForNext" do
        it "blocks until a Done state with a different buildId appears" do
            result <- runStmConc do
                setPhase (BuildId 1) donePhase
                void $ Conc.fork do
                    liftIO (threadDelay 10_000)
                    setPhase (BuildId 2) donePhase
                waitForNext (BuildId 1)
            result.buildId `shouldBe` BuildId 2

    -- Regression for the bug behind the user's "status --wait waits until
    -- the LAST cycle finishes" report: a polling-based 'waitUntilDone'
    -- could miss a transient 'Done' state if the next 'Building' phase
    -- overwrote the TVar within the poll interval, and an STM-retry
    -- version still races against the scheduler's wake-up latency. The
    -- broadcast 'TChan' of transitions makes every phase change a
    -- discrete message that can't be overwritten — so even if
    -- 'setPhase Done >> setPhase Building' happens back-to-back, the
    -- waiter observes the Done.
    describe "atomic transition capture" do
        it "observes a transient Done even if Building immediately follows" do
            result <- runStmConc do
                setPhase (BuildId 1) (Building Nothing)
                -- The publisher thread fires Done and then immediately
                -- overwrites it with Building (N+1), the exact pattern the
                -- coalescing worker produces between two queued cycles.
                void $ Conc.fork do
                    liftIO (threadDelay 5_000)
                    setPhase (BuildId 1) donePhase
                    setPhase (BuildId 2) (Building Nothing)
                waitUntilDone
            -- The waiter must report BuildComplete(1), NOT skip past it and
            -- report the later BuildComplete(2) (or block forever).
            result.buildId `shouldBe` BuildId 1
            case result.phase of
                BuildComplete _ -> pure ()
                p -> expectationFailure $ "expected BuildComplete phase, got: " <> show p


--------------------------------------------------------------------------------
-- PostBuildStore interpreter test
--------------------------------------------------------------------------------

testWithPostBuildPhase :: Spec
testWithPostBuildPhase = do
    describe "with Done build phase" do
        let runTest = runTest' doneBuildState
        describe "setTestPhase" $ it "sets test phase" do
            let actualState = runTest $ PostBuild.setTestPhase DoneTesting
            actualState
                `shouldBe` doneBuildState
                    { phase =
                        BuildComplete
                            PostBuild
                                { testPhase = DoneTesting
                                , evalPhase = EvaluatingComments
                                , result = emptyBuildResult
                                }
                    }
        describe "setEvalPhase" $ it "sets eval phase" do
            let actualState = runTest $ PostBuild.setEvalPhase DoneEvaluatingComments
            actualState
                `shouldBe` doneBuildState
                    { phase =
                        BuildComplete
                            PostBuild
                                { testPhase = Testing
                                , evalPhase = DoneEvaluatingComments
                                , result = emptyBuildResult
                                }
                    }
        describe "updateBuildResult" $ it "updates the build result" do
            let actualState = runTest $ PostBuild.updateBuildResult \br -> br {moduleCount = 99}
            actualState
                `shouldBe` doneBuildState
                    { phase =
                        BuildComplete
                            PostBuild
                                { testPhase = Testing
                                , evalPhase = EvaluatingComments
                                , result = emptyBuildResult {moduleCount = 99}
                                }
                    }

    describe "with non-Done build phase" do
        let runTest = runTest' buildingBuildState
        describe "setTestPhase" do
            it "sets the build phase to Done and sets test phase" do
                let actualState = runTest $ PostBuild.setTestPhase DoneTesting
                actualState
                    `shouldBe` doneBuildState
                        { phase =
                            BuildComplete
                                PostBuild
                                    { testPhase = DoneTesting
                                    , evalPhase = EvaluatingComments
                                    , result = emptyBuildResult
                                    }
                        }
        describe "setEvalPhase" do
            it "sets the build phase to Done and sets eval phase" do
                let actualState = runTest $ PostBuild.setEvalPhase DoneEvaluatingComments
                actualState
                    `shouldBe` doneBuildState
                        { phase =
                            BuildComplete
                                PostBuild
                                    { testPhase = Testing
                                    , evalPhase = DoneEvaluatingComments
                                    , result = emptyBuildResult
                                    }
                        }
        describe "updateBuildResult" do
            it "sets the build phase to Done and updates the build result from the initial build result" do
                let actualState = runTest $ PostBuild.updateBuildResult \br -> br {moduleCount = 99}
                actualState
                    `shouldBe` doneBuildState
                        { phase =
                            BuildComplete
                                PostBuild
                                    { testPhase = Testing
                                    , evalPhase = EvaluatingComments
                                    , result = emptyBuildResult {moduleCount = 99}
                                    }
                        }
  where
    runTest' bs =
        runPureEff
            . execState bs
            . runBuildStoreSimple
            . withPostBuildPhase emptyBuildResult
    runBuildStoreSimple :: (State BuildState :> es) => Eff (BuildStore : es) a -> Eff es a
    runBuildStoreSimple = interpret_ \case
        ModifyPhase f -> modify \s -> s {phase = f s}
        _ -> error "runBuildStoreSimple: Unsupported operation"


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

buildingBuildState :: BuildState
buildingBuildState =
    BuildState
        { buildId = BuildId 1
        , phase = Building Nothing
        , daemonInfo = emptyDaemonInfo
        }


doneBuildState :: BuildState
doneBuildState =
    BuildState
        { buildId = BuildId 1
        , phase =
            BuildComplete
                PostBuild
                    { testPhase = Testing
                    , evalPhase = EvaluatingComments
                    , result = emptyBuildResult
                    }
        , daemonInfo = emptyDaemonInfo
        }


emptyBuildResult :: BuildResult
emptyBuildResult =
    BuildResult
        { completedAt = epoch
        , duration = 0
        , moduleCount = 0
        , diagnostics = []
        , testRuns = []
        , evalRuns = []
        }


emptyDaemonInfo :: DaemonInfo
emptyDaemonInfo =
    DaemonInfo
        { targets = []
        , watchDirs = []
        , sockPath = ""
        , logFile = ""
        , metricsPort = Nothing
        }


buildingAt :: Int -> BuildState
buildingAt n = BuildState (BuildId n) (Building Nothing) emptyDaemonInfo


donePhase :: BuildPhase
donePhase =
    BuildComplete
        $ PostBuild DoneTesting DoneEvaluatingComments
        $ BuildResult
            { completedAt = epoch
            , duration = 0
            , moduleCount = 0
            , diagnostics = []
            , testRuns = []
            , evalRuns = []
            }


doneAt :: Int -> BuildState
doneAt n = BuildState (BuildId n) donePhase emptyDaemonInfo


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0


runScripted :: [BuildState] -> Eff '[BuildStore] a -> a
runScripted states = runPureEff . runBuildStoreScripted states


runStm :: Eff '[BuildStore, Input DaemonInfo, Delay, Concurrent, IOE] a -> IO a
runStm = runEff . runConcurrent . runDelay . runInputConst emptyDaemonInfo . runBuildStore


runStmConc :: Eff '[Conc, BuildStore, Input DaemonInfo, Delay, Concurrent, IOE] a -> IO a
runStmConc = runEff . runConcurrent . runDelay . runInputConst emptyDaemonInfo . runBuildStore . runConc
