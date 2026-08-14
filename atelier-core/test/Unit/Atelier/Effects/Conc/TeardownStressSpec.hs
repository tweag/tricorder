-- | Focused stress tests for 'Conc.scoped' teardown.
--
-- The full test suite occasionally deadlocks under heavy scheduler pressure
-- (CPU oversubscription). Earlier A/B experiments ruled out the channel
-- primitive: converting the Iterator/Publishing path from unagi to STM did not
-- change the hang rate, which points at the one layer common to every victim —
-- Ki structured-concurrency teardown in the 'Conc' effect ('runConc' /
-- 'Conc.scoped' killing and awaiting forked threads at scope close).
--
-- These tests hammer that teardown in a tight loop so a low-probability
-- lost-wakeup becomes near-certain under load, isolating it from Pub/Sub,
-- Iterator, channels, and everything else. Iteration count is tunable via
-- @ATELIER_CONC_STRESS_N@ (crank it up under @yes@-load to reproduce). Each
-- test is wrapped in a 'timeout' so a real teardown hang fails loudly instead
-- of wedging the run.
module Unit.Atelier.Effects.Conc.TeardownStressSpec (spec_ConcTeardownStress) where

import Control.Concurrent (threadDelay)
import Control.Exception (evaluate)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Concurrent.STM (atomically, retry)
import System.Environment (lookupEnv)
import System.Timeout (timeout)
import Test.Hspec (Spec, describe, it, runIO, shouldBe)

import Atelier.Effects.Chan (Chan, runChan)
import Atelier.Effects.Clock (Clock, runClock)
import Atelier.Effects.Conc (Conc, fork, fork_, runConc, scoped)
import Atelier.Effects.Publishing (runPubSub)
import Atelier.Effects.Publishing.Pub (Pub)
import Atelier.Effects.Publishing.Sub (Sub)

import Atelier.Effects.Iterator qualified as Iter
import Atelier.Effects.Publishing.Pub qualified as Pub


spec_ConcTeardownStress :: Spec
spec_ConcTeardownStress = do
    iterations <- runIO (fromMaybe defaultIterations . (>>= readMaybe) <$> lookupEnv "ATELIER_CONC_STRESS_N")
    timeoutSecs <- runIO (fromMaybe defaultTimeoutSecs . (>>= readMaybe) <$> lookupEnv "ATELIER_CONC_STRESS_TIMEOUT_S")
    runSpin <- runIO (isJust <$> lookupEnv "ATELIER_CONC_SPIN")

    publishDelayUs <- runIO (fromMaybe defaultPublishDelayUs . (>>= readMaybe) <$> lookupEnv "ATELIER_CONC_STRESS_DELAY_US")

    let testTimeoutMicros = timeoutSecs * 1_000_000

    describe "Conc.scoped teardown stress" do
        it "reaps an STM-blocked fork_ across many scopes" do
            completed <-
                timeout testTimeoutMicros
                    $ runConcTest
                    $ replicateM_ iterations
                    $ scoped (void (fork_ blockForever))
            completed `shouldBe` Just ()

        it "reaps a two-child scope (one parked, one transient) across many scopes" do
            completed <-
                timeout testTimeoutMicros
                    $ runConcTest
                    $ replicateM_ iterations
                    $ scoped do
                        _ <- fork (liftIO (threadDelay 5))
                        void (fork_ blockForever)
            completed `shouldBe` Just ()

    -- Faithful repro of the actual full-suite victim: the 'fromEvents' Iterator
    -- pattern over its real effect stack, looped. The producer's 10us delay is
    -- the ONLY thing giving the forked listener time to subscribe before the
    -- first publish; under load that race can drop early events and wedge the
    -- consumer's 'Iter.next' (it reads exactly as many as were published, so any
    -- dropped event blocks forever). Also exercises the deep-stack
    -- 'Conc.scoped' unlift/teardown that the bare tests above strip away.
    describe "fromEvents Iterator pattern stress (full stack)" do
        it "drives the producer/listener fromEvents scope across many iterations" do
            completed <-
                timeout testTimeoutMicros
                    $ runIterTest
                    $ replicateM_ iterations
                    $ Iter.fromEvents @Int \iter -> do
                        _ <- fork do
                            liftIO (threadDelay publishDelayUs)
                            traverse_ Pub.publish [1, 2, 3 :: Int]
                        _ <- replicateM 3 (Iter.next iter)
                        pure ()
            completed `shouldBe` Just ()

    -- A non-allocating fork_ is UN-KILLABLE under -O: -fomit-yields strips the
    -- loop's safe point, so the async exception Ki throws at scope close — and
    -- the one 'timeout' would throw — can never be delivered. It would wedge an
    -- optimized build permanently and burn a core. Hence opt-in, and only safe
    -- on a -O0 build (where the boxed-Int loop still allocates and stays
    -- killable). This is the discriminating probe for the omit-yields theory.
    when runSpin
        $ describe "Conc.scoped teardown of a NON-ALLOCATING fork_ (ATELIER_CONC_SPIN=1; -O0 only)" do
            it "reaps a non-allocating spin at scope exit" do
                completed <-
                    timeout testTimeoutMicros
                        $ runConcTest
                        $ scoped (void (fork_ nonAllocatingSpin))
                completed `shouldBe` Just ()
  where
    defaultIterations = 300 :: Int
    defaultTimeoutSecs = 15 :: Int
    defaultPublishDelayUs = 10 :: Int

    blockForever :: (Concurrent :> es) => Eff es Void
    blockForever = atomically retry

    -- Boxed-Int loop: allocates (killable) at -O0, worker-wraps to a
    -- non-allocating Int# loop (un-killable) at -O.
    nonAllocatingSpin :: (IOE :> es) => Eff es Void
    nonAllocatingSpin = liftIO (evaluate (spin 0))
      where
        spin :: Int -> Void
        spin !n = spin (n + 1)


runConcTest :: Eff '[Conc, Concurrent, IOE] a -> IO a
runConcTest = runEff . runConcurrent . runConc


-- | Mirrors 'IteratorSpec.runTest' — the full effect stack the real victim runs on.
runIterTest :: Eff '[Pub Int, Sub Int, Chan, Clock, Conc, Concurrent, IOE] a -> IO a
runIterTest = runEff . runConcurrent . runConc . runClock . runChan . runPubSub @Int
