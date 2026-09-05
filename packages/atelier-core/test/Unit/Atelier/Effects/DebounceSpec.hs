module Unit.Atelier.Effects.DebounceSpec (spec_Debounce) where

import Data.Dynamic (fromDynamic, toDyn)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Test.Hspec

import Data.IORef qualified as IORef
import Effectful.Concurrent.STM qualified as STM
import StmContainers.Map qualified as Map

import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Debounce
    ( Entry (..)
    , debounced
    , debouncedWith
    , ensureCallback
    , ensureEntry
    , runDebounce
    )
import Atelier.Effects.Delay (runDelay)
import Atelier.Time (Millisecond)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Console qualified as Console
import Atelier.Effects.Delay qualified as Delay


spec_Debounce :: Spec
spec_Debounce = do
    describe "runDebounce" testRunDebounce
    describe "ensureEntry" testEnsureEntry
    describe "ensureCallback" testEnsureCallback


testEnsureEntry :: Spec
testEnsureEntry = do
    describe "new key" do
        it "gets generation 0" do
            state <- runSTM Map.new
            entry <- runSTM $ mkEntry 1 42 state (+)
            entry.generation `shouldBe` 0

        it "stores value as arg" do
            state <- runSTM Map.new
            entry <- runSTM $ mkEntry 1 42 state (+)
            (entry.arg >>= fromDynamic) `shouldBe` Just @Int 42

    describe "existing key" do
        it "increments generation" do
            state <- runSTM Map.new
            _ <- runSTM $ mkEntry 1 2 state (+)
            entry <- runSTM $ mkEntry 1 3 state (+)
            entry.generation `shouldBe` 1

        it "applies merge function to old and new value" do
            state <- runSTM Map.new
            _ <- runSTM $ mkEntry 1 5 state (+)
            entry <- runSTM $ mkEntry 1 10 state (+)
            (entry.arg >>= fromDynamic) `shouldBe` Just @Int 15

    describe "multiple updates" do
        it "accumulates generation" do
            state <- runSTM Map.new
            _ <- runSTM $ mkEntry 1 1 state (+)
            _ <- runSTM $ mkEntry 1 2 state (+)
            entry <- runSTM $ mkEntry 1 3 state (+)
            entry.generation `shouldBe` 2

        it "applies merge cumulatively" do
            state <- runSTM Map.new
            _ <- runSTM $ mkEntry 1 1 state (+)
            _ <- runSTM $ mkEntry 1 2 state (+)
            entry <- runSTM $ mkEntry 1 3 state (+)
            (entry.arg >>= fromDynamic) `shouldBe` Just @Int 6

    describe "independent keys" do
        it "do not interfere with each other" do
            state <- runSTM Map.new
            entryA <- runSTM $ mkEntry 1 10 state (+)
            entryB <- runSTM $ mkEntry 2 20 state (+)
            (entryA.arg >>= fromDynamic) `shouldBe` Just @Int 10
            (entryB.arg >>= fromDynamic) `shouldBe` Just @Int 20
            entryA.generation `shouldBe` 0
            entryB.generation `shouldBe` 0
  where
    mkEntry = ensureEntry @Int @Int
    runSTM action = runEff . runConcurrent $ STM.atomically action


testEnsureCallback :: Spec
testEnsureCallback = do
    it "fires callback when entry's generation still matches" do
        actual <- runCallbackTest do
            state <- STM.atomically Map.new
            STM.atomically $ Map.insert (entry 0) (1 :: Int) state
            ref <- liftIO $ IORef.newIORef @Int 0
            t <-
                Conc.fork
                    $ ensureCallback @Int @Int 1 state 1 0
                    $ liftIO . IORef.writeIORef ref
            Conc.await t
            liftIO $ IORef.readIORef ref
        actual `shouldBe` 10
    it "skips callback when generation has been bumped" do
        runCallbackTest do
            state <- STM.atomically Map.new
            -- A newer event has already bumped generation to 1
            STM.atomically $ Map.insert (entry 1) (1 :: Int) state
            -- This fork was scheduled for generation 0; it should skip
            ensureCallback @Int @Int 1 state 1 0 \_ ->
                liftIO $ False `shouldBe` True
    it "skips callback when entry has been removed" do
        runCallbackTest do
            state <- STM.atomically Map.new
            ensureCallback @Int @Int 1 state 1 0 \_ ->
                liftIO $ False `shouldBe` True
  where
    runCallbackTest =
        runEff
            . runConcurrent
            . Console.runConsole
            . Delay.runDelay
            . runConc
    entry generation =
        Entry
            { generation
            , arg = Just $ toDyn @Int 10
            }


-- These specs exercise real-timer debouncing across forked threads. Rather than
-- sleeping a fixed duration and hoping the settle fired (which races scheduling
-- under load), each callback signals a 'TMVar' and the test blocks until it
-- fires. Multi-burst tests sequence by waiting for each burst's fire, so bursts
-- cannot merge regardless of timing. A short grace after the fire guards against
-- a spurious second fire.
testRunDebounce :: Spec
testRunDebounce = do
    describe "debounced" do
        describe "when invoked once" $ it "fires once" do
            n <- runTest do
                (count, fired) <- newCounter
                debounced 50 () (bump count fired)
                awaitFire fired
                Delay.wait @Millisecond 80
                readCount count
            n `shouldBe` 1

        describe "when invoked multiple times" $ it "fires once" do
            n <- runTest do
                (count, fired) <- newCounter
                debounced 50 () (bump count fired)
                debounced 50 () (bump count fired)
                debounced 50 () (bump count fired)
                awaitFire fired
                Delay.wait @Millisecond 80
                readCount count
            n `shouldBe` 1

        describe "when invoked multiple times with a delay between" $ it "fires once per burst" do
            n <- runTest do
                (count, fired) <- newCounter
                debounced 50 () (bump count fired)
                debounced 50 () (bump count fired)
                awaitFire fired -- burst 1 settled and cleared the entry
                debounced 50 () (bump count fired)
                debounced 50 () (bump count fired)
                awaitFire fired -- burst 2 is therefore independent
                readCount count
            n `shouldBe` 2

        describe "when invoked many times" $ it "should not crash" do
            n <- runTest do
                (count, fired) <- newCounter
                replicateM_ 10_000 $ debounced 50 () (bump count fired)
                awaitFire fired
                Delay.wait @Millisecond 80
                readCount count
            n `shouldBe` 1

    describe "debouncedWith" do
        describe "when invoked once" $ it "fires callback with the provided arg" do
            got <- runTest do
                result <- STM.atomically STM.newEmptyTMVar
                debouncedWith 50 (+) () (42 :: Int) (signal result)
                awaitValue result
            got `shouldBe` Just 42

        describe "when invoked multiple times rapidly" do
            it "fires once" do
                n <- runTest do
                    (count, fired) <- newCounter
                    let cb _ = bump count fired
                    debouncedWith 50 (+) () (1 :: Int) cb
                    debouncedWith 50 (+) () (2 :: Int) cb
                    debouncedWith 50 (+) () (3 :: Int) cb
                    awaitFire fired
                    Delay.wait @Millisecond 80
                    readCount count
                n `shouldBe` 1

            it "fires callback with merged arg" do
                got <- runTest do
                    result <- STM.atomically STM.newEmptyTMVar
                    let cb = signal result
                    debouncedWith 50 (+) () (1 :: Int) cb
                    debouncedWith 50 (+) () (2 :: Int) cb
                    debouncedWith 50 (+) () (3 :: Int) cb
                    awaitValue result
                got `shouldBe` Just 6

        describe "when invoked multiple times with a delay between" $ it "fires once per burst with merged arg" do
            xs <- runTest do
                fired <- STM.atomically STM.newEmptyTMVar
                ref <- STM.atomically (STM.newTVar @[Int] [])
                let cb v = STM.atomically (STM.modifyTVar' ref (<> [v]) >> void (STM.tryPutTMVar fired ()))
                debouncedWith 50 (+) () (1 :: Int) cb
                debouncedWith 50 (+) () (2 :: Int) cb
                awaitFire fired -- burst 1 fired (1+2=3); entry cleared
                debouncedWith 50 (+) () (10 :: Int) cb
                debouncedWith 50 (+) () (20 :: Int) cb
                awaitFire fired -- burst 2 fired (10+20=30)
                STM.atomically (STM.readTVar ref)
            xs `shouldBe` [3, 30]
  where
    runTest =
        runEff
            . runConcurrent
            . runConc
            . runDelay
            . runDebounce

    -- A fire counter paired with a TMVar signalling that a fire happened.
    newCounter = do
        count <- STM.atomically (STM.newTVar @Int 0)
        fired <- STM.atomically STM.newEmptyTMVar
        pure (count, fired)
    bump count fired = STM.atomically do
        STM.modifyTVar' count (+ 1)
        void $ STM.tryPutTMVar fired ()
    readCount count = STM.atomically (STM.readTVar count)
    signal result v = STM.atomically (STM.putTMVar result v)

    -- Block until a callback signals, bounded by a generous timeout so a real
    -- regression fails loudly instead of hanging forever.
    awaitFire fired =
        awaitValue fired >>= \case
            Just () -> pure ()
            Nothing -> liftIO $ expectationFailure "debounce callback did not fire within 5s"
    awaitValue tmv =
        either (const Nothing) Just
            <$> Conc.race (Delay.wait @Millisecond 5000) (STM.atomically (STM.takeTMVar tmv))
