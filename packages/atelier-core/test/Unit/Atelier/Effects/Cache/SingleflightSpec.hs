module Unit.Atelier.Effects.Cache.SingleflightSpec (test_Singleflight) where

import Control.Exception (try)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Exception (catch, throwIO)
import Effectful.State.Static.Shared (State, modify, runState)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.Effects.Cache.Singleflight (Singleflight, runSingleflight, updateCache, withCache)
import Atelier.Effects.Conc (Conc, runConc)
import Atelier.Effects.Delay (Delay, runDelay)
import Atelier.Time (Millisecond)
import Atelier.Types.Semaphore (Semaphore)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Delay qualified as Delay
import Atelier.Types.Semaphore qualified as Sem


-- | Test exception type
data TestException = TestException Text
    deriving stock (Eq, Show)
    deriving anyclass (Exception)


-- | Run a Singleflight test with execution counter
runSingleflightTest
    :: Eff [Singleflight Int Int, State Int, Delay, Conc, Concurrent, IOE] a
    -> IO (a, Int)
runSingleflightTest action =
    runEff
        . runConcurrent
        . runConc
        . runDelay
        . runState @Int 0
        . runSingleflight @Int @Int
        $ action


-- | A computation that increments the execution counter and returns a value
compute :: (State Int :> es) => Int -> Eff es Int
compute value = do
    modify @Int (+ 1)
    pure value


-- | A slow computation that increments the counter
slowCompute :: (Concurrent :> es, State Int :> es) => Semaphore -> Int -> Eff es Int
slowCompute sem value = do
    Sem.wait sem
    modify @Int (+ 1)
    pure value


test_Singleflight :: TestTree
test_Singleflight =
    testGroup
        "Singleflight"
        [ testGroup
            "Basic Behaviors"
            [ testGroup
                "First request executes computation"
                [ testCase "executes the computation on first request" $ do
                    (result, execCount) <- runSingleflightTest $ do
                        withCache 1 (compute 42)
                    result @?= 42
                    execCount @?= 1
                ]
            , testGroup
                "Cached value returned on second request"
                [ testCase "returns cached value without re-executing" $ do
                    (result, execCount) <- runSingleflightTest $ do
                        r1 <- withCache 1 (compute 42)
                        r2 <- withCache 1 (compute 42)
                        pure (r1, r2)
                    result @?= (42, 42)
                    execCount @?= 1
                , testCase "returns cached value across multiple sequential requests" $ do
                    (results, execCount) <- runSingleflightTest $ do
                        r1 <- withCache 1 (compute 42)
                        r2 <- withCache 1 (compute 42)
                        r3 <- withCache 1 (compute 42)
                        pure [r1, r2, r3]
                    results @?= [42, 42, 42]
                    execCount @?= 1
                ]
            , testGroup
                "Concurrent requests are deduplicated"
                [ testCase "executes computation once for concurrent requests" $ do
                    (results, execCount) <- runSingleflightTest $ do
                        -- Launch 10 concurrent requests for the same key
                        asyncs <- replicateM 10 do
                            sem <- Sem.new
                            async <- Conc.fork $ withCache 1 (slowCompute sem 42)
                            pure (sem, async)
                        traverse_ Sem.set $ fst <$> asyncs
                        traverse Conc.await $ snd <$> asyncs
                    all (== 42) results @?= True
                    length results @?= 10
                    execCount @?= 1
                , testCase "all concurrent waiters receive the same result" $ do
                    (results, execCount) <- runSingleflightTest $ do
                        sem <- Sem.new
                        -- Launch concurrent requests with different delays
                        a1 <- Conc.fork $ withCache 1 (slowCompute sem 99)
                        Delay.wait (1 :: Millisecond) -- Ensure first request starts
                        a2 <- Conc.fork $ withCache 1 (compute 99)
                        a3 <- Conc.fork $ withCache 1 (compute 99)
                        Sem.signal sem -- Let first request continue
                        r1 <- Conc.await a1
                        r2 <- Conc.await a2
                        r3 <- Conc.await a3
                        pure [r1, r2, r3]
                    results @?= [99, 99, 99]
                    execCount @?= 1
                ]
            , testGroup
                "Different keys execute independently"
                [ testCase "executes separate computations for different keys" $ do
                    (results, execCount) <- runSingleflightTest $ do
                        r1 <- withCache 1 (compute 10)
                        r2 <- withCache 2 (compute 20)
                        r3 <- withCache 3 (compute 30)
                        pure [r1, r2, r3]
                    results @?= [10, 20, 30]
                    execCount @?= 3
                , testCase "different keys can run concurrently" $ do
                    (results, execCount) <- runSingleflightTest $ do
                        sem <- Sem.newSet
                        a1 <- Conc.fork $ withCache 1 (slowCompute sem 10)
                        a2 <- Conc.fork $ withCache 2 (slowCompute sem 20)
                        a3 <- Conc.fork $ withCache 3 (slowCompute sem 30)
                        replicateM_ 3 $ Sem.signal sem
                        r1 <- Conc.await a1
                        r2 <- Conc.await a2
                        r3 <- Conc.await a3
                        pure [r1, r2, r3]
                    all (\r -> r `elem` [10, 20, 30]) results @?= True
                    execCount @?= 3
                ]
            , testGroup
                "UpdateCache pre-populates the cache"
                [ testCase "returns pre-populated value without executing computation" $ do
                    (result, execCount) <- runSingleflightTest $ do
                        updateCache [(1, 99)]
                        withCache 1 (compute 42)
                    result @?= 99
                    execCount @?= 0
                , testCase "pre-populated values are returned by subsequent requests" $ do
                    (results, execCount) <- runSingleflightTest $ do
                        updateCache [(1, 99)]
                        r1 <- withCache 1 (compute 42)
                        r2 <- withCache 1 (compute 42)
                        pure [r1, r2]
                    results @?= [99, 99]
                    execCount @?= 0
                ]
            , testGroup
                "UpdateCache handles multiple entries"
                [ testCase "correctly handles multiple key-value pairs" $ do
                    (results, execCount) <- runSingleflightTest $ do
                        updateCache [(1, 10), (2, 20), (3, 30)]
                        r1 <- withCache 1 (compute 99)
                        r2 <- withCache 2 (compute 99)
                        r3 <- withCache 3 (compute 99)
                        pure [r1, r2, r3]
                    results @?= [10, 20, 30]
                    execCount @?= 0
                ]
            , testGroup
                "All concurrent waiters receive the result"
                [ testCase "broadcasts result to all waiting requests" $ do
                    (results, execCount) <- runSingleflightTest $ do
                        -- Start one slow computation and many fast waiters
                        asyncs <- replicateM 20 do
                            sem <- Sem.new
                            async <- Conc.fork $ withCache 1 (slowCompute sem 777)
                            pure (sem, async)
                        traverse_ Sem.signal $ fst <$> asyncs
                        traverse Conc.await $ snd <$> asyncs
                    all (== 777) results @?= True
                    length results @?= 20
                    execCount @?= 1
                ]
            ]
        , testGroup
            "Edge Cases"
            [ testGroup
                "Computation throws exception"
                [ testCase "propagates exception to the first caller" $ do
                    let action = runSingleflightTest $ do
                            withCache @Int @Int 1 (throwIO $ TestException "boom")
                    result <- try action
                    result @?= Left (TestException "boom")
                , testCase "exception does not get cached" $ do
                    (result, execCount) <- runSingleflightTest $ do
                        -- First request throws
                        _ <-
                            (withCache @Int @Int 1 (throwIO $ TestException "boom"))
                                `catch` \(_ :: TestException) -> pure 0
                        -- Second request should re-execute
                        withCache 1 (compute 42)
                    result @?= 42
                    execCount @?= 1
                , testCase "propagates exception to all concurrent waiters" $ do
                    let action = runSingleflightTest $ do
                            sem <- Sem.new
                            a1 <-
                                Conc.fork $ withCache @Int @Int 1 (slowCompute sem 42 >> throwIO (TestException "concurrent-boom"))
                            Delay.wait (1 :: Millisecond)
                            a2 <- Conc.fork $ withCache @Int @Int 1 (compute 99)
                            Sem.signal sem
                            _ <- Conc.await a1
                            Conc.await a2
                    result <- try action
                    result @?= Left (TestException "concurrent-boom")
                ]
            , testGroup
                "UpdateCache on in-flight computation"
                [ testCase "overrides result of in-flight computation" $ do
                    (result, execCount) <- runSingleflightTest $ do
                        sem <- Sem.new
                        -- Start slow computation
                        a1 <- Conc.fork $ withCache 1 (slowCompute sem 42)
                        Delay.wait (1 :: Millisecond) -- Let it start
                        -- Update cache while computation is running
                        updateCache [(1, 999)]
                        -- Both should get the updated value
                        Sem.signal sem
                        Conc.await a1
                    result @?= 999
                    execCount @?= 1
                , testCase "waiting requests receive updated value" $ do
                    (results, execCount) <- runSingleflightTest $ do
                        sem <- Sem.new
                        -- Start slow computation and waiters
                        a1 <- Conc.fork $ withCache 1 (slowCompute sem 42)
                        Delay.wait (1 :: Millisecond)
                        a2 <- Conc.fork $ withCache 1 (compute 42)
                        Delay.wait (1 :: Millisecond)
                        -- Update while they're all waiting/running
                        updateCache [(1, 888)]
                        Sem.signal sem
                        r1 <- Conc.await a1
                        r2 <- Conc.await a2
                        pure [r1, r2]
                    all (== 888) results @?= True
                    execCount @?= 1
                ]
            ]
        ]
