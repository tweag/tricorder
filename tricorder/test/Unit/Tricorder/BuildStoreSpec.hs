module Unit.Tricorder.BuildStoreSpec (spec_BuildStore) where

import Atelier.Effects.Conc (Conc, runConc)
import Atelier.Effects.Delay (Delay, runDelay)
import Control.Concurrent (threadDelay)
import Data.Time (UTCTime (..), fromGregorian)
import Effectful (IOE, runEff, runPureEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Test.Hspec

import Atelier.Effects.Conc qualified as Conc
import Data.Map.Strict qualified as Map

import Tricorder.BuildState
    ( BuildId (..)
    , BuildOutput (..)
    , BuildRecord (..)
    , BuildResult (..)
    , BuildState (..)
    , CycleEvent (..)
    , CyclePhase (..)
    , TestOutput (..)
    , beginBuild
    , currentBuild
    , currentId
    , initialBuildState
    , step
    )
import Tricorder.BuildState.BuildProgress (BuildProgress (..))
import Tricorder.Effects.BuildStore
    ( BuildStore
    , emit
    , finishBuild
    , getState
    , runBuildStore
    , runBuildStoreScripted
    , setBuild
    , waitForNext
    , waitUntilDone
    )

import Tricorder.BuildState.Test qualified as Test


spec_BuildStore :: Spec
spec_BuildStore = do
    describe "step reducer" testStep
    describe "currentId derivation" testCurrentId
    describe "beginBuild" testBeginBuild
    describe "runBuildStoreScripted" testScripted
    describe "runBuildStoreSTM" testSTM


--------------------------------------------------------------------------------
-- Pure reducer tests (the "maximally testable" claim)
--------------------------------------------------------------------------------

testStep :: Spec
testStep = do
    it "SourceChanged bumps the build id and starts Building" do
        let s = step initial SourceChanged
        currentId s `shouldBe` BuildId 1
        s.cycle `shouldBe` Building Nothing

    it "Building -> Analysing -> Idle drives a clean build to rest" do
        let s = foldl' step initial [SourceChanged, EnterAnalysis, AnalysisComplete]
        s.cycle `shouldBe` Idle

    it "Building -> Idle (no analysis) settles directly" do
        let s = foldl' step initial [SourceChanged, AnalysisComplete]
        s.cycle `shouldBe` Idle

    it "Restarting absorbs a stale EnterAnalysis (the clobber fix)" do
        let s = foldl' step initial [SourceChanged, CabalChanged, EnterAnalysis]
        s.cycle `shouldBe` Restarting

    it "Restarting absorbs a stale AnalysisComplete (the clobber fix)" do
        let s = foldl' step initial [SourceChanged, CabalChanged, AnalysisComplete]
        s.cycle `shouldBe` Restarting

    it "Restarting absorbs a stale BuildAborted (the clobber fix)" do
        let s = foldl' step initial [SourceChanged, CabalChanged, BuildAborted "boom"]
        s.cycle `shouldBe` Restarting

    it "BuildAborted with no restart pending moves to BuildFailed" do
        let s = foldl' step initial [SourceChanged, BuildAborted "boom"]
        s.cycle `shouldBe` BuildFailed "boom"

    it "BuildProgressed does not resurrect an Idle cycle" do
        let s = foldl' step initial [SourceChanged, AnalysisComplete, BuildProgressed prog]
        s.cycle `shouldBe` Idle

    it "BuildProgressed only advances a live Building" do
        let s = foldl' step initial [SourceChanged, BuildProgressed prog]
        s.cycle `shouldBe` Building (Just prog)

    it "evicts history down to K=2 across many builds" do
        let s = foldl' step initial (replicate 5 SourceChanged)
        Map.size s.history `shouldBe` 2
        -- only the two most recent build ids survive
        Map.keys s.history `shouldBe` [BuildId 4, BuildId 5]


--------------------------------------------------------------------------------
-- currentId is derived from the map's greatest key, never stored
--------------------------------------------------------------------------------

testCurrentId :: Spec
testCurrentId = do
    it "is BuildId 0 for the seeded initial state" do
        currentId initialBuildState `shouldBe` BuildId 0

    it "follows the greatest key after eviction drops the smaller ones" do
        let s = foldl' step initialBuildState (replicate 5 SourceChanged)
        currentId s `shouldBe` BuildId 5


--------------------------------------------------------------------------------
-- beginBuild: total construction, id derivation, eviction
--------------------------------------------------------------------------------

testBeginBuild :: Spec
testBeginBuild = do
    it "bumps to max+1 and evicts to K=2" do
        let s = beginBuild (beginBuild (beginBuild initialBuildState))
        Map.keys s.history `shouldBe` [BuildId 2, BuildId 3]
        currentId s `shouldBe` BuildId 3

    it "seeds an empty record under the new id and resets the phase" do
        let s = beginBuild (initial {cycle = Idle})
        s.cycle `shouldBe` Building Nothing
        currentBuild s `shouldBe` NotBuilt


--------------------------------------------------------------------------------
-- Scripted interpreter tests (pure, no IO)
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    describe "getState" do
        it "returns the head of the state list" do
            let r = runScripted [buildingAt 0, doneAt 1] getState
            currentId r `shouldBe` BuildId 0

    describe "waitUntilDone" do
        it "returns immediately when head is already done" do
            let r = runScripted [doneAt 1, doneAt 2] waitUntilDone
            currentId r `shouldBe` BuildId 1

        it "skips Building states and returns the first done" do
            let r = runScripted [buildingAt 0, buildingAt 0, doneAt 1] waitUntilDone
            currentId r `shouldBe` BuildId 1

    describe "waitForNext" do
        it "skips states with the same buildId" do
            let r = runScripted [doneAt 1, doneAt 2] (waitForNext (BuildId 1))
            currentId r `shouldBe` BuildId 2

        it "skips Building states regardless of buildId" do
            let r = runScripted [buildingAt 2, doneAt 2] (waitForNext (BuildId 1))
            currentId r `shouldBe` BuildId 2

        it "skips both Building and same-id Done before returning the next Done" do
            let r =
                    runScripted
                        [buildingAt 1, doneAt 1, buildingAt 2, doneAt 2]
                        (waitForNext (BuildId 1))
            currentId r `shouldBe` BuildId 2


--------------------------------------------------------------------------------
-- STM interpreter tests (concurrent)
--------------------------------------------------------------------------------

testSTM :: Spec
testSTM = do
    describe "getState" do
        it "returns the seeded Building state" do
            r <- runStm getState
            currentId r `shouldBe` BuildId 0
            r.cycle `shouldBe` Building Nothing

    describe "setBuild / emit / getState" do
        it "reflects a settled build (register written by setBuild, phase by emit)" do
            r <- runStm do
                emit SourceChanged
                setBuild (Built result)
                emit AnalysisComplete
                getState
            r.cycle `shouldBe` Idle
            currentBuild r `shouldBe` Built result

    -- The combined primitive couples the register write with the settle
    -- transition in one step, so a settled 'Idle' can never be observed without
    -- its result (the ordering can't slip at the call site).
    describe "finishBuild" do
        it "settles directly to Idle carrying the result" do
            r <- runStm do
                emit SourceChanged
                finishBuild (Built result) AnalysisComplete
                getState
            r.cycle `shouldBe` Idle
            currentBuild r `shouldBe` Built result

        it "enters Analysing carrying the result" do
            r <- runStm do
                emit SourceChanged
                finishBuild (Built result) EnterAnalysis
                getState
            r.cycle `shouldBe` Analysing
            currentBuild r `shouldBe` Built result

        it "a waiter woken on the settle never sees Idle with a NotBuilt register" do
            r <- runStmConc do
                emit SourceChanged
                void $ Conc.fork do
                    liftIO (threadDelay 10_000)
                    finishBuild (Built result) AnalysisComplete
                waitUntilDone
            (r.cycle, currentBuild r) `shouldBe` (Idle, Built result)

    describe "waitUntilDone" do
        it "blocks until a build settles from another thread" do
            r <- runStmConc do
                emit SourceChanged
                void $ Conc.fork do
                    liftIO (threadDelay 10_000)
                    setBuild (Built result)
                    emit AnalysisComplete
                waitUntilDone
            r.cycle `shouldBe` Idle

    describe "waitForNext" do
        it "blocks until a settled build with a different id appears from another thread" do
            r <- runStmConc do
                emit SourceChanged -- build 1, Building
                finishBuild (Built result) AnalysisComplete -- build 1 settles (id 1)
                void $ Conc.fork do
                    liftIO (threadDelay 10_000)
                    emit SourceChanged -- build 2, Building
                    finishBuild (Built result) AnalysisComplete -- build 2 settles
                waitForNext (BuildId 1)
            -- Must skip past build 1 (same id) and its Building frames, waking
            -- only on the settled build 2.
            currentId r `shouldBe` BuildId 2
            r.cycle `shouldBe` Idle

    -- Regression for "status --wait waits until the LAST cycle finishes": the
    -- broadcast TChan of transitions makes every state change a discrete
    -- message that can't be overwritten, so a transient Idle followed
    -- immediately by Building (N+1) is still observed by the waiter.
    describe "atomic transition capture" do
        it "observes a transient Idle even if Building immediately follows" do
            r <- runStmConc do
                emit SourceChanged -- build 1, Building
                void $ Conc.fork do
                    liftIO (threadDelay 5_000)
                    setBuild (Built result)
                    emit AnalysisComplete -- build 1 settles (transient Idle)
                    emit SourceChanged -- build 2, Building (overwrites TVar)
                waitUntilDone
            -- Must report the settled build 1, not skip past it to build 2.
            currentId r `shouldBe` BuildId 1
            r.cycle `shouldBe` Idle


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

initial :: BuildState
initial = buildingAt 0


result :: BuildResult
result =
    BuildResult
        { completedAt = epoch
        , duration = 0
        , moduleCount = 0
        , diagnostics = []
        }


prog :: BuildProgress
prog = BuildProgress {compiled = 1, total = 2}


buildingAt :: Int -> BuildState
buildingAt n =
    BuildState
        { cycle = Building Nothing
        , history = Map.singleton (BuildId n) (BuildRecord NotBuilt TestsIdle)
        }


doneAt :: Int -> BuildState
doneAt n =
    BuildState
        { cycle = Idle
        , history = Map.singleton (BuildId n) (BuildRecord (Built result) (TestsDone (Test.Suites mempty)))
        }


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0


runScripted :: [BuildState] -> Eff '[BuildStore] a -> a
runScripted states = runPureEff . runBuildStoreScripted states


runStm :: Eff '[BuildStore, Delay, Concurrent, IOE] a -> IO a
runStm = runEff . runConcurrent . runDelay . runBuildStore


runStmConc :: Eff '[Conc, BuildStore, Delay, Concurrent, IOE] a -> IO a
runStmConc = runEff . runConcurrent . runDelay . runBuildStore . runConc
