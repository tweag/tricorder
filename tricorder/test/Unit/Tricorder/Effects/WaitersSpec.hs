module Unit.Tricorder.Effects.WaitersSpec (spec_Waiters) where

import Atelier.Effects.Conc (Conc, runConc)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Exception (catch, throwIO)
import Effectful.State.Static.Shared (State, get, modify, runState)
import Test.Hspec (Spec, describe, it, shouldBe, shouldMatchList, shouldThrow)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Types.Semaphore qualified as Sem

import Tricorder.Effects.Waiters (Waiters)

import Tricorder.Effects.Waiters qualified as Waiters


-- | Test exception type, used to prove that a waiter's slot is released
-- even when its action throws.
data TestException = TestException Text
    deriving stock (Eq, Show)
    deriving anyclass (Exception)


runWaitersTest
    :: Eff [Waiters, State [Text], Conc, Concurrent, IOE] a
    -> IO (a, [Text])
runWaitersTest =
    runEff
        . runConcurrent
        . runConc
        . runState @[Text] []
        . Waiters.run


logEvent :: (State [Text] :> es) => Text -> Eff es ()
logEvent name = modify (<> [name])


spec_Waiters :: Spec
spec_Waiters = do
    describe "Waiters.without" do
        describe "with waiters" $ it "skips the action" do
            (_, events) <- runWaitersTest do
                proceed <- Sem.new
                started <- Sem.new
                waiter <- Conc.fork $ Waiters.with do
                    void $ Sem.set started
                    Sem.wait proceed
                    logEvent "waiter"
                Sem.wait started
                -- Called directly (not forked): Without never blocks, so
                -- forking it here would race its no-waiters check against
                -- the `Sem.set proceed` below, making the test flaky.
                Waiters.without (logEvent "without")
                void $ Sem.set proceed
                Conc.await waiter
            events `shouldBe` ["waiter"]
        it "runs its action immediately when there are no active waiters" do
            (_, events) <- runWaitersTest $ Waiters.without (logEvent "ran")
            events `shouldBe` ["ran"]

    describe "Waiters.with" do
        it "runs its action" do
            (_, events) <- runWaitersTest $ Waiters.with (logEvent "ran")
            events `shouldBe` ["ran"]

        it "lets a subsequent Waiters.wait proceed once it has completed" do
            (_, events) <- runWaitersTest do
                Waiters.with (logEvent "waiter")
                Waiters.wait (logEvent "quiesced")
            events `shouldBe` ["waiter", "quiesced"]

        it "blocks a concurrent Waiters.wait until its action finishes" do
            (_, events) <- runWaitersTest do
                started <- Sem.new
                proceed <- Sem.new
                waiter <- Conc.fork $ Waiters.with do
                    _ <- Sem.set started
                    Sem.wait proceed
                    logEvent "waiter-end"
                Sem.wait started
                quiescent <- Conc.fork $ Waiters.wait (logEvent "quiesced")
                _ <- Sem.set proceed
                Conc.await waiter
                Conc.await quiescent
            -- Blocking is guaranteed by the STM retry on the waiter count,
            -- not by scheduling luck, so this order holds on every run.
            events `shouldBe` ["waiter-end", "quiesced"]

        it "blocks wait until every concurrent waiter finishes" do
            (afterFirst, events) <- runWaitersTest do
                started1 <- Sem.new
                proceed1 <- Sem.new
                waiter1 <- Conc.fork $ Waiters.with do
                    _ <- Sem.set started1
                    Sem.wait proceed1
                    logEvent "waiter1-end"
                Sem.wait started1

                quiescent <- Conc.fork $ Waiters.wait (logEvent "quiesced")

                started2 <- Sem.new
                proceed2 <- Sem.new
                waiter2 <- Conc.fork $ Waiters.with do
                    _ <- Sem.set started2
                    Sem.wait proceed2
                    logEvent "waiter2-end"
                Sem.wait started2

                _ <- Sem.set proceed1
                Conc.await waiter1
                -- waiter2 is still active here, so the waiter count cannot
                -- have reached zero yet: quiescent is still blocked, not
                -- just "hasn't been scheduled".
                afterFirst <- get
                _ <- Sem.set proceed2
                Conc.await waiter2
                -- No snapshot is taken here: once waiter2's slot is released,
                -- quiescent's STM retry can wake and log concurrently with
                -- this thread, so there is no deterministic in-between state
                -- to observe. Only the final, fully-awaited state is safe to
                -- assert on.
                Conc.await quiescent
                pure afterFirst
            afterFirst `shouldMatchList` ["waiter1-end"]
            events `shouldMatchList` ["waiter1-end", "waiter2-end", "quiesced"]

    describe "exception safety" do
        it "propagates an exception raised by the waiter's action" do
            let action = runWaitersTest $ Waiters.with (throwIO $ TestException "boom")
            action `shouldThrow` \(TestException msg) -> msg == "boom"

        it "releases the waiter slot even when the action throws" do
            (_, events) <- runWaitersTest do
                _ <-
                    Waiters.with (throwIO $ TestException "boom")
                        `catch` \(_ :: TestException) -> pure ()
                Waiters.without (logEvent "quiesced")
            events `shouldBe` ["quiesced"]
