module Unit.Atelier.Effects.ConcSpec (test_Conc) where

import Control.Exception (ErrorCall (..), throwIO, try)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Concurrent.STM (atomically, modifyTVar', newTVarIO, readTVar, retry)
import Hedgehog (forAll, property, (===))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))
import Test.Tasty.Hedgehog (testProperty)

import Data.IORef qualified as IORef
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range

import Atelier.Effects.Conc (Conc, await, awaitAll, fork, forkTry, fork_, runConc, scoped)
import Atelier.Effects.Delay (Delay, runDelay)
import Atelier.Time (Millisecond)

import Atelier.Effects.Delay qualified as Delay


test_Conc :: TestTree
test_Conc =
    testGroup
        "Conc"
        [ testGroup
            "Thread cleanup"
            [ testGroup
                "without scoped"
                [ testCase "demonstrates thread lifetime" $ runTest do
                    -- This test shows threads live for the duration of their scope
                    counter <- newTVarIO (0 :: Int)

                    -- Thread we fork here will live until the root scope (in
                    -- 'runTest') exits.
                    fork_ $ forever $ atomically $ modifyTVar' counter (+ 1)

                    let waitFor n = atomically do
                            v <- readTVar counter
                            if v >= n then pure v else retry

                    countAfter <- waitFor 1
                    finalCount <- waitFor (countAfter + 1)

                    liftIO $ assertBool "expected the thread to keep running" $ finalCount > countAfter
                ]
            , testGroup
                "with scoped"
                [ testCase "kills nested threads when scope exits" $ runTest do
                    counter <- newTVarIO (0 :: Int)

                    let waitFor n = atomically do
                            v <- readTVar counter
                            if v >= n then pure v else retry

                    -- Create nested scope that will clean up its threads
                    scoped do
                        fork_ $ forever $ atomically $ modifyTVar' counter (+ 1)
                        -- Ensure the thread has incremented at least once
                        _ <- waitFor 1
                        pure ()
                    -- Inner scope exits here - thread should be KILLED

                    -- Capture count after scope exit
                    countAfter <- atomically $ readTVar counter

                    -- Give any leaked thread a brief window to advance the counter
                    Delay.wait (1 :: Millisecond)

                    -- Count should NOT increase after scope exit
                    finalCount <- atomically $ readTVar counter

                    liftIO $ finalCount @?= countAfter
                ]
            ]
        , testGroup
            "fork and await"
            [ testCase "returns the result of the forked computation" do
                result <- runTestSimple $ do
                    t <- fork $ pure (42 :: Int)
                    await t
                result @?= 42
            , testCase "executes the forked action" do
                result <- runTestSimple $ do
                    ref <- liftIO $ IORef.newIORef False
                    t <- fork $ liftIO $ IORef.writeIORef ref True
                    await t
                    liftIO $ IORef.readIORef ref
                result @?= True
            ]
        , testGroup
            "awaitAll"
            [ testProperty "waits for all forked threads to complete" $ property do
                n <- forAll $ Gen.int (Range.linear 1 20)
                result <- liftIO $ runTestSimple $ do
                    ref <- liftIO $ IORef.newIORef (0 :: Int)
                    replicateM_ n $ fork $ liftIO $ IORef.atomicModifyIORef' ref (\x -> (x + 1, ()))
                    awaitAll
                    liftIO $ IORef.readIORef ref
                result === n
            ]
        , testGroup
            "forkTry"
            [ testCase "returns Right for a successful computation" do
                result <- runTestSimple $ do
                    t <- forkTry @ErrorCall $ pure (42 :: Int)
                    await t
                result @?= Right 42
            , testCase "returns Left when the forked thread throws" do
                result <- runTestSimple $ do
                    t <- forkTry @ErrorCall $ liftIO $ throwIO $ ErrorCall "boom"
                    await t
                assertBool "expected Left" $ isLeft (result :: Either ErrorCall Int)
            ]
        , testGroup
            "exception propagation"
            [ testCase "uncaught exception in forked thread propagates to the scope" do
                let action = runTestSimple $ do
                        _ <- fork $ liftIO $ throwIO $ ErrorCall "boom"
                        awaitAll
                result <- try @SomeException action
                isLeft result @?= True
            ]
        ]


--------------------------------------------------------------------------------
-- Test Helpers
--------------------------------------------------------------------------------

runTest :: Eff '[Delay, Conc, Concurrent, IOE] a -> IO a
runTest = runEff . runConcurrent . runConc . runDelay


runTestSimple :: Eff '[Conc, Concurrent, IOE] a -> IO a
runTestSimple = runEff . runConcurrent . runConc
