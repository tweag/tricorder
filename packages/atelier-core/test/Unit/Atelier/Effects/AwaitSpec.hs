module Unit.Atelier.Effects.AwaitSpec (spec_Await) where

import Effectful (runEff, runPureEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.State.Static.Shared (evalState, state)
import Effectful.Writer.Static.Shared (runWriter, tell)
import Test.Hspec (Spec, describe, it, shouldBe)

import Effectful.Concurrent.STM qualified as STM

import Atelier.Effects.Chan (runChan)
import Atelier.Effects.Conc (runConc)

import Atelier.Effects.Await qualified as Await
import Atelier.Effects.Yield qualified as Yield


spec_Await :: Spec
spec_Await = do
    describe "eachAwait" testEachAwait
    describe "takeAwait" testTakeAwait
    describe "awaitYield" testAwaitYield


testEachAwait :: Spec
testEachAwait = do
    it "answers each await with the given action's result" do
        let xs =
                runPureEff
                    . evalState @Int 0
                    . Await.eachAwait (state \s -> (s, s + 1))
                    $ replicateM 4 Await.await
        xs `shouldBe` [0, 1, 2, 3]


testTakeAwait :: Spec
testTakeAwait = do
    it "yields exactly N values from the await stream" do
        let (_, xs) =
                runPureEff
                    . evalState @Int 0
                    . Yield.yieldToList
                    . Await.eachAwait @Int (state \s -> (s, s + 1))
                    $ Await.takeAwait 3
        xs `shouldBe` [0, 1, 2]

    describe "when N is zero" $ it "yields nothing" do
        let (_, xs) =
                runPureEff
                    . Yield.yieldToList
                    . Await.eachAwait @Int (pure 7)
                    $ Await.takeAwait 0
        xs `shouldBe` []


testAwaitYield :: Spec
testAwaitYield = do
    it "pipes yielded values into the await stream" do
        (_, result) <-
            runTest
                $ Await.awaitYield (Yield.inFoldable @Int [1, 2, 3] >> blockForever)
                $ replicateM 3 Await.await >>= tell

        result `shouldBe` [1, 2, 3]

    it "returns the result of the awaiting computation" do
        -- The yielder blocks after yielding so the awaiter reliably wins the
        -- termination race and its 'tell' is observed; otherwise the yielder can
        -- finish first and cancel the awaiter before it writes (flaky under load).
        (_, result) <-
            runTest
                $ Await.awaitYield @Int (Yield.yield 99 >> blockForever)
                $ fmap (* 2) Await.await >>= tell . one
        result `shouldBe` [198]

    describe "when the awaiter finishes before the yielder"
        $ it "terminates with the awaiter's result" do
            (result, _) <-
                runTest . runConcurrent $ do
                    Await.awaitYield @Int
                        (Yield.inFoldable [1 .. 100] >> blockForever)
                        Await.await
            result `shouldBe` 1

    describe "when the yielder finishes before the awaiter"
        $ it "terminates with the yielder's result" do
            (result :: Int, _) <-
                runTest
                    $ Await.awaitYield @Int (Yield.yield 1 >> pure 2)
                    $ Await.await >> Await.await >> pure 1
            result `shouldBe` 2
  where
    runTest = runEff . runConcurrent . runConc . runChan . runWriter
    -- Block the current (forked) computation indefinitely; used to keep a yielder
    -- alive so the awaiter wins the awaitYield termination race. The explicit
    -- signature keeps it polymorphic across the differing effect stacks below.
    blockForever :: (STM.Concurrent :> es) => Eff es a
    blockForever = STM.atomically STM.retry
