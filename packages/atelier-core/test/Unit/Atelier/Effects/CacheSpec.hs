module Unit.Atelier.Effects.CacheSpec (test_Cache) where

import Data.Time (UTCTime (..), addUTCTime, fromGregorian)
import Data.Time.Clock (NominalDiffTime)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState, modify)
import Hedgehog (forAll, property, (===))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))
import Test.Tasty.Hedgehog (testProperty)

import Effectful.Concurrent.STM qualified as STM
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range

import Atelier.Effects.Cache
    ( Config (..)
    , cacheDelete
    , cacheInsert
    , cacheLookup
    , cacheModify
    , runCacheTtlWithWait
    )
import Atelier.Effects.Clock (runClockState)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.Log (runLogNoOp)


test_Cache :: TestTree
test_Cache =
    testGroup
        "Cache"
        [ testGroup
            "Basic Operations"
            [ testCase "lookup on absent key returns Nothing" do
                result <- runCacheTest $ cacheLookup 1
                result @?= Nothing
            , testCase "lookup after insert returns Just value" do
                result <- runCacheTest do
                    cacheInsert 1 42
                    cacheLookup 1
                result @?= Just 42
            , testCase "lookup after delete returns Nothing" do
                result <- runCacheTest $ do
                    cacheInsert 1 42
                    cacheDelete 1
                    cacheLookup 1
                result @?= Nothing
            , testCase "insert twice updates value" do
                result <- runCacheTest $ do
                    cacheInsert 1 42
                    cacheInsert 1 99
                    cacheLookup 1
                result @?= Just 99
            , testCase "delete on absent key is a no-op" do
                result <- runCacheTest $ do
                    cacheDelete 1
                    cacheLookup 1
                result @?= Nothing
            ]
        , testGroup
            "Modify"
            [ testCase "modify on absent key uses Nothing branch" do
                result <- runCacheTest $ cacheModify @Int @Int 1 (maybe 0 (+ 1))
                result @?= 0
            , testCase "modify on present key uses Just branch" do
                result <- runCacheTest $ do
                    cacheInsert 1 10
                    cacheModify 1 (maybe 0 (+ 1))
                result @?= 11
            , testCase "modify returns the new value" do
                result <- runCacheTest $ do
                    _ <- cacheModify 1 (maybe 5 (+ 5))
                    cacheModify 1 (maybe 5 (+ 5))
                result @?= 10
            ]
        , testGroup
            "TTL Eviction"
            [ testCase "entry is present before TTL expires" do
                result <- runBase . runCacheTestWithWait (STM.atomically STM.retry) $ do
                    cacheInsert 1 42
                    cacheLookup 1
                result @?= Just 42
            , testCase "entry is evicted after cleanup thread fires past TTL" do
                result <- runBase do
                    trigger <- STM.atomically STM.newEmptyTMVar
                    done <- STM.atomically STM.newEmptyTMVar
                    runCacheTestWithWait (cleanupBarrier done trigger) do
                        awaitReady done
                        cacheInsert 1 42
                        v1 <- cacheLookup 1
                        modify (addUTCTime (ttl + 1))
                        stepCleanup trigger done -- run one cleanup, block until it finishes
                        v2 <- cacheLookup 1
                        pure (v1, v2)
                result @?= (Just 42, Nothing)
            , testCase "entry within TTL survives cleanup" do
                result <- runBase do
                    trigger <- STM.atomically STM.newEmptyTMVar
                    done <- STM.atomically STM.newEmptyTMVar
                    runCacheTestWithWait (cleanupBarrier done trigger) do
                        awaitReady done
                        cacheInsert 1 42
                        modify (addUTCTime (ttl - 1))
                        stepCleanup trigger done
                        cacheLookup 1
                result @?= Just 42
            , testCase "re-inserted entry retains original TTL window" do
                result <- runBase do
                    trigger <- STM.atomically STM.newEmptyTMVar
                    done <- STM.atomically STM.newEmptyTMVar
                    runCacheTestWithWait (cleanupBarrier done trigger) do
                        awaitReady done
                        cacheInsert 1 42
                        v1 <- cacheLookup 1

                        -- re-insert before TTL expires: updates value but preserves createdAt = t0
                        modify (addUTCTime (ttl - 1))
                        stepCleanup trigger done
                        cacheInsert 1 99
                        v2 <- cacheLookup 1

                        -- advance clock past original TTL
                        modify (addUTCTime 2)
                        stepCleanup trigger done
                        v3 <- cacheLookup 1

                        pure (v1, v2, v3)
                -- createdAt was preserved from the first insert, so the entry is expired and evicted
                result @?= (Just 42, Just 99, Nothing)
            ]
        , testGroup
            "Properties"
            [ testProperty "insert then lookup roundtrips value" $ property do
                v <- forAll $ Gen.int (Range.linear 0 1000)
                result <- liftIO $ runCacheTest $ do
                    cacheInsert 1 v
                    cacheLookup 1
                result === Just v
            , testProperty "distinct keys have independent values" $ property do
                m <- forAll $ Gen.int (Range.linear 1 20)
                n <- forAll $ Gen.int (Range.linear 1 20)
                (a, b) <- liftIO $ runCacheTest $ do
                    cacheInsert 1 m
                    cacheInsert 2 n
                    va <- cacheLookup 1
                    vb <- cacheLookup 2
                    pure (va, vb)
                a === Just m
                b === Just n
            , testProperty "interleaved key access is independent" $ property do
                keys <- forAll $ Gen.list (Range.linear 1 50) Gen.bool
                -- count inserts per key by interleaving
                counts <- liftIO $ runCacheTest $ do
                    let step True = cacheModify @Int 1 (maybe 1 (+ 1))
                        step False = cacheModify @Int 2 (maybe 1 (+ 1))
                    traverse step keys
                let key1Counts = [c | (k, c) <- zip keys counts, k]
                    key2Counts = [c | (k, c) <- zip keys counts, not k]
                key1Counts === [1 .. length key1Counts]
                key2Counts === [1 .. length key2Counts]
            , testProperty "concurrent inserts to different keys don't interfere" $ property do
                n <- forAll $ Gen.int (Range.linear 1 20)
                results <- liftIO $ runCacheTest $ do
                    for_ [1 .. n] \i -> cacheInsert i i
                    traverse (\i -> cacheLookup i) [1 .. n]
                results === map (Just . id) [1 .. n]
            , testProperty "modify is atomic under concurrency" $ property do
                n <- forAll $ Gen.int (Range.linear 1 50)
                finalVal <- liftIO $ runCacheTest $ do
                    for_ [1 .. n] \_ -> cacheModify 1 (maybe 1 (+ 1))
                    cacheLookup 1
                finalVal === Just n
            ]
        ]
  where
    runBase = runEff . runConcurrent
    runCacheTest = runBase . runCacheTestWithWait (STM.atomically STM.retry)
    runCacheTestWithWait wait =
        runLogNoOp
            . runConc
            . runDelay
            . evalState epoch
            . runClockState
            . runReader (Config {entryTtl = ttl, cleanupInterval = 3600})
            . runCacheTtlWithWait @Int @Int wait
    epoch = UTCTime (fromGregorian 1970 1 1) 0
    ttl = 3600 :: NominalDiffTime

    -- Deterministic control over the background cleanup thread, replacing
    -- real-time 'Delay.wait' guesses with a handshake. The thread runs its
    -- injected wait ('cleanupBarrier') once per loop: it acknowledges that the
    -- previous cycle finished (via 'done'), then blocks for the next trigger.
    -- 'stepCleanup' triggers one cycle and blocks until that cycle's eviction has
    -- completed, so look-ups afterwards observe a settled state.
    cleanupBarrier done trigger =
        STM.atomically (STM.putTMVar done ()) >> STM.atomically (STM.takeTMVar trigger)
    awaitReady done = STM.atomically (STM.takeTMVar done)
    stepCleanup trigger done =
        STM.atomically (STM.putTMVar trigger ()) >> STM.atomically (STM.takeTMVar done)
