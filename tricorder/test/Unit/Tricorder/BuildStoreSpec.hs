module Unit.Tricorder.BuildStoreSpec (spec_BuildStore) where

import Atelier.Effects.Conc (Conc, runConc)
import Atelier.Effects.Delay (Delay, runDelay)
import Atelier.Effects.Input (Input, runInputConst)
import Control.Concurrent (threadDelay)
import Data.Time (UTCTime (..), fromGregorian)
import Effectful (IOE, runEff, runPureEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Reader.Static (ask, local, runReader)
import Test.Hspec

import Atelier.Effects.Conc qualified as Conc
import Data.Map.Strict qualified as Map

import Tricorder.BuildState
    ( ActiveBuild (..)
    , BuildId (..)
    , BuildOutput (..)
    , BuildRecord (..)
    , BuildResult (..)
    , BuildState (..)
    , CycleEvent (..)
    , CyclePhase (..)
    , DaemonInfo (..)
    , TestOutput (..)
    , atBuild
    , currentRecord
    , step
    )
import Tricorder.BuildState.BuildProgress (BuildProgress (..))
import Tricorder.Effects.BuildStore
    ( BuildStore
    , emit
    , getState
    , runBuildStore
    , runBuildStoreScripted
    , waitForNext
    , waitUntilDone
    , writeTestsAt
    )

import Tricorder.BuildState.Test qualified as Test


spec_BuildStore :: Spec
spec_BuildStore = do
    describe "step reducer" testStep
    describe "runBuildStoreScripted" testScripted
    describe "runBuildStoreSTM" testSTM
    describe "ambient ActiveBuild targeting (straggler-safety prototype)" testActiveBuild


--------------------------------------------------------------------------------
-- Straggler-safety prototype: Reader.local-bound ActiveBuild + ask-based setter
--------------------------------------------------------------------------------

testActiveBuild :: Spec
testActiveBuild = do
    -- (1) Fork inheritance: the make-or-break claim. A 'Conc.fork'd fiber must
    -- see the 'Reader.local' binding in scope at fork time — this is what lets
    -- a drain fiber (which runs onProgress) resolve the build it was spawned
    -- for. Proven directly against the atelier Conc/Ki interpreter.
    it "a Conc.fork'd fiber inherits the Reader.local binding" do
        seen <-
            runEff . runConcurrent . runConc . runReader (ActiveBuild (BuildId 0))
                $ local (const (ActiveBuild (BuildId 7))) do
                    t <- Conc.fork (ask @ActiveBuild)
                    Conc.await t
        seen `shouldBe` ActiveBuild (BuildId 7)

    -- (2) The straggler: a write bound (via ask) to build N files under
    -- history[N] through the REAL store interpreter, even though 'current' has
    -- already bumped to N+1. Compare with a current-based write, which lands on
    -- N+1.
    it "an ask-bound write files under the captured build after current bumped" do
        finalState <-
            runEff
                . runConcurrent
                . runDelay
                . runReader (ActiveBuild (BuildId 0))
                . runInputConst emptyDaemonInfo
                . runBuildStore
                $ do
                    emit SourceChanged -- current 0 -> 1
                    capturedN <- (.current) <$> getState -- BuildId 1
                    emit (BuildFinished result') -- settle build 1
                    -- Enter build 1's "cycle scope": bind ActiveBuild = 1.
                    local (const (ActiveBuild capturedN)) do
                        -- A new build starts concurrently (current -> 2)...
                        emit SourceChanged
                        -- ...then a straggler from build 1's scope writes tests.
                        ActiveBuild bid <- ask
                        writeTestsAt bid (const (TestsDone doneSuites))
                    getState
        -- The straggler landed on build 1 (its captured id), NOT build 2.
        fmap (.tests) (atBuild (BuildId 1) finalState) `shouldBe` Just (TestsDone doneSuites)
        fmap (.tests) (atBuild (BuildId 2) finalState) `shouldBe` Just TestsIdle
  where
    result' =
        BuildResult
            { completedAt = epoch
            , duration = 0
            , moduleCount = 0
            , diagnostics = []
            }
    doneSuites = Test.Suites mempty


--------------------------------------------------------------------------------
-- Pure reducer tests (the "maximally testable" claim)
--------------------------------------------------------------------------------

testStep :: Spec
testStep = do
    it "SourceChanged bumps the build id and starts Building" do
        let s = step initial SourceChanged
        s.current `shouldBe` BuildId 1
        s.cycle `shouldBe` Building Nothing

    it "BuildFinished settles the cycle and publishes the build register atomically" do
        let s = foldl' step initial [SourceChanged, BuildFinished result]
        s.cycle `shouldBe` Settled
        (currentRecord s).build `shouldBe` Built result

    it "Restarting absorbs a stale BuildFinished (the clobber fix)" do
        let s = foldl' step initial [SourceChanged, CabalChanged, BuildFinished result]
        s.cycle `shouldBe` Restarting
        -- the late result did not land
        (currentRecord s).build `shouldBe` NotBuilt

    it "Restarting absorbs a stale BuildAborted" do
        let s = foldl' step initial [SourceChanged, CabalChanged, BuildAborted "boom"]
        s.cycle `shouldBe` Restarting

    it "BuildProgressed does not resurrect a Settled cycle" do
        let s = foldl' step initial [SourceChanged, BuildFinished result, BuildProgressed prog]
        s.cycle `shouldBe` Settled

    it "evicts history down to K=2 across many builds" do
        let s = foldl' step initial (replicate 5 SourceChanged)
        Map.size s.history `shouldBe` 2
        -- only the two most recent build ids survive
        Map.keys s.history `shouldBe` [BuildId 4, BuildId 5]


--------------------------------------------------------------------------------
-- Scripted interpreter tests (pure, no IO)
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    describe "getState" do
        it "returns the head of the state list" do
            let r = runScripted [buildingAt 0, doneAt 1] getState
            r.current `shouldBe` BuildId 0

    describe "waitUntilDone" do
        it "returns immediately when head is already settled" do
            let r = runScripted [doneAt 1, doneAt 2] waitUntilDone
            r.current `shouldBe` BuildId 1

        it "skips Building states and returns the first settled" do
            let r = runScripted [buildingAt 0, buildingAt 0, doneAt 1] waitUntilDone
            r.current `shouldBe` BuildId 1

    describe "waitForNext" do
        it "skips states with the same buildId" do
            let r = runScripted [doneAt 1, doneAt 2] (waitForNext (BuildId 1))
            r.current `shouldBe` BuildId 2

        it "skips Building states regardless of buildId" do
            let r = runScripted [buildingAt 2, doneAt 2] (waitForNext (BuildId 1))
            r.current `shouldBe` BuildId 2


--------------------------------------------------------------------------------
-- STM interpreter tests (concurrent)
--------------------------------------------------------------------------------

testSTM :: Spec
testSTM = do
    describe "getState" do
        it "returns the initial Building state" do
            r <- runStm getState
            r.current `shouldBe` BuildId 0
            r.cycle `shouldBe` Building Nothing

    describe "emit / getState" do
        it "reflects a settled build" do
            r <- runStm do
                emit SourceChanged
                emit (BuildFinished result)
                getState
            r.cycle `shouldBe` Settled
            (currentRecord r).build `shouldBe` Built result

    describe "waitUntilDone" do
        it "blocks until a build settles from another thread" do
            r <- runStmConc do
                emit SourceChanged
                void $ Conc.fork do
                    liftIO (threadDelay 10_000)
                    emit (BuildFinished result)
                waitUntilDone
            r.cycle `shouldBe` Settled

    -- Regression for "status --wait waits until the LAST cycle finishes": the
    -- broadcast TChan of transitions makes every state change a discrete
    -- message that can't be overwritten, so a transient Settled followed
    -- immediately by Building (N+1) is still observed by the waiter.
    describe "atomic transition capture" do
        it "observes a transient Settled even if Building immediately follows" do
            r <- runStmConc do
                emit SourceChanged -- build 1, Building
                void $ Conc.fork do
                    liftIO (threadDelay 5_000)
                    emit (BuildFinished result) -- build 1 settles (transient)
                    emit SourceChanged -- build 2, Building (overwrites TVar)
                waitUntilDone
            -- Must report the settled build 1, not skip past it to build 2.
            r.current `shouldBe` BuildId 1
            r.cycle `shouldBe` Settled


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

emptyDaemonInfo :: DaemonInfo
emptyDaemonInfo =
    DaemonInfo
        { targets = []
        , watchDirs = []
        , sockPath = ""
        , logFile = ""
        , metricsPort = Nothing
        }


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
        { current = BuildId n
        , cycle = Building Nothing
        , history = Map.singleton (BuildId n) (BuildRecord NotBuilt TestsIdle)
        , daemonInfo = emptyDaemonInfo
        }


doneAt :: Int -> BuildState
doneAt n =
    BuildState
        { current = BuildId n
        , cycle = Settled
        , history = Map.singleton (BuildId n) (BuildRecord (Built result) (TestsDone (Test.Suites mempty)))
        , daemonInfo = emptyDaemonInfo
        }


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0


runScripted :: [BuildState] -> Eff '[BuildStore] a -> a
runScripted states = runPureEff . runBuildStoreScripted states


runStm :: Eff '[BuildStore, Input DaemonInfo, Delay, Concurrent, IOE] a -> IO a
runStm = runEff . runConcurrent . runDelay . runInputConst emptyDaemonInfo . runBuildStore


runStmConc :: Eff '[Conc, BuildStore, Input DaemonInfo, Delay, Concurrent, IOE] a -> IO a
runStmConc = runEff . runConcurrent . runDelay . runInputConst emptyDaemonInfo . runBuildStore . runConc
