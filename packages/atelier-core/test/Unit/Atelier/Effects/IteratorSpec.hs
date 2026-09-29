module Unit.Atelier.Effects.IteratorSpec (test_Iterator) where

import Control.Concurrent (threadDelay)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.Effects.Chan (Chan, runChan)
import Atelier.Effects.Clock (Clock, runClock)
import Atelier.Effects.Conc (Conc, fork, runConc)
import Atelier.Effects.Publishing (runPubSub)
import Atelier.Effects.Publishing.Pub (Pub)
import Atelier.Effects.Publishing.Sub (Sub)

import Atelier.Effects.Iterator qualified as Iter
import Atelier.Effects.Publishing.Pub qualified as Pub


test_Iterator :: TestTree
test_Iterator =
    testGroup
        "Iterator"
        [ testGroup "fromEvents" testFromEvents
        , testGroup "filter" testFilter
        , testGroup "changes" testChanges
        ]


testFromEvents :: [TestTree]
testFromEvents =
    [ testCase "yields a published event" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    Pub.publish (42 :: Int)
                Iter.next iter
        result @?= 42
    , testCase "yields events in publication order" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [1, 2, 3]
                replicateM 3 (Iter.next iter)
        result @?= [1, 2, 3]
    , testCase "buffers events so next can catch up" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [1, 2, 3]
                liftIO $ threadDelay 5_000
                replicateM 3 (Iter.next iter)
        result @?= [1, 2, 3]
    ]


testFilter :: [TestTree]
testFilter =
    [ testCase "passes values that satisfy the predicate" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [1 .. 4]
                Iter.next (Iter.filter even iter)
        result @?= 2
    , testCase "skips values that do not satisfy the predicate" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [1 .. 6]
                replicateM 3 (Iter.next (Iter.filter even iter))
        result @?= [2, 4, 6]
    ]


testChanges :: [TestTree]
testChanges =
    [ testCase "skips values equal to the initial value" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [0, 0, 1]
                Iter.next (Iter.changes 0 iter)
        result @?= 1
    , testCase "yields values that differ from the initial value" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [1, 2, 3]
                replicateM 3 (Iter.next (Iter.changes 0 iter))
        result @?= [1, 2, 3]
    , testCase "skips initial values interspersed with non-initial values" do
        result <- runTest $ do
            Iter.fromEvents @Int \iter -> do
                _ <- fork do
                    liftIO $ threadDelay 10
                    traverse_ Pub.publish [0, 1, 0, 2, 0, 3]
                replicateM 3 (Iter.next (Iter.changes 0 iter))
        result @?= [1, 2, 3]
    ]


--------------------------------------------------------------------------------
-- Test Helpers
--------------------------------------------------------------------------------

runTest :: Eff '[Pub Int, Sub Int, Chan, Clock, Conc, Concurrent, IOE] a -> IO a
runTest =
    runEff
        . runConcurrent
        . runConc
        . runClock
        . runChan
        . runPubSub @Int
