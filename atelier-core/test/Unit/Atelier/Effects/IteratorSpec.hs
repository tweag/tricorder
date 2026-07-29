module Unit.Atelier.Effects.IteratorSpec (spec_Iterator) where

import Control.Concurrent (threadDelay)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Test.Hspec (Spec, describe, it, shouldBe)

import Atelier.Effects.Chan (Chan, runChan)
import Atelier.Effects.Clock (Clock, runClock)
import Atelier.Effects.Conc (Conc, fork, runConc)
import Atelier.Effects.Monitoring.Tracing (Tracing, runTracingNoOp)
import Atelier.Effects.Publishing (runPubSub)
import Atelier.Effects.Publishing.Pub (Pub)
import Atelier.Effects.Publishing.Sub (Sub)

import Atelier.Effects.Iterator qualified as Iter
import Atelier.Effects.Publishing.Pub qualified as Pub


spec_Iterator :: Spec
spec_Iterator = do
    describe "fromEvents" testFromEvents
    describe "filter" testFilter
    describe "changes" testChanges


testFromEvents :: Spec
testFromEvents = do
    it "yields a published event" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    Pub.publish (42 :: Int)
                Iter.next iter
        result `shouldBe` 42

    it "yields events in publication order" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [1, 2, 3]
                replicateM 3 (Iter.next iter)
        result `shouldBe` [1, 2, 3]

    it "buffers events so next can catch up" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [1, 2, 3]
                liftIO $ threadDelay 5_000
                replicateM 3 (Iter.next iter)
        result `shouldBe` [1, 2, 3]


testFilter :: Spec
testFilter = do
    it "passes values that satisfy the predicate" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [1 .. 4]
                Iter.next (Iter.filter even iter)
        result `shouldBe` 2

    it "skips values that do not satisfy the predicate" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [1 .. 6]
                replicateM 3 (Iter.next (Iter.filter even iter))
        result `shouldBe` [2, 4, 6]


testChanges :: Spec
testChanges = do
    it "skips values equal to the initial value" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [0, 0, 1]
                Iter.next (Iter.changes 0 iter)
        result `shouldBe` 1

    it "yields values that differ from the initial value" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [1, 2, 3]
                replicateM 3 (Iter.next (Iter.changes 0 iter))
        result `shouldBe` [1, 2, 3]

    it "skips initial values interspersed with non-initial values" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [0, 1, 0, 2, 0, 3]
                replicateM 3 (Iter.next (Iter.changes 0 iter))
        result `shouldBe` [1, 2, 3]


--------------------------------------------------------------------------------
-- Test Helpers
--------------------------------------------------------------------------------

runTest :: Eff '[Pub Int, Sub Int, Chan, Clock, Tracing, Conc, Concurrent, IOE] a -> IO a
runTest =
    runEff
        . runConcurrent
        . runConc
        . runTracingNoOp
        . runClock
        . runChan
        . runPubSub @Int
