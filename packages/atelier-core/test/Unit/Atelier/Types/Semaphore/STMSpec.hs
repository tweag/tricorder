module Unit.Atelier.Types.Semaphore.STMSpec (spec_Semaphore_STM) where

import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Concurrent.STM (atomically)
import Effectful.State.Static.Shared (evalState, get, put)
import Test.Hspec (Spec, describe, it, shouldBe)

import Data.IORef qualified as IORef

import Atelier.Effects.Conc qualified as Conc
import Atelier.Types.Semaphore.STM qualified as Sem


spec_Semaphore_STM :: Spec
spec_Semaphore_STM = do
    describe "wait" $ it "should halt the computation" do
        runEff . runConcurrent . Conc.runConc . evalState @Int 0 $ do
            sem <- atomically Sem.new

            thread <- Conc.fork do
                atomically $ Sem.wait sem
                put 1

            a1 <- get
            liftIO $ a1 `shouldBe` 0

            atomically $ Sem.signal sem

            Conc.await thread

            a2 <- get
            liftIO $ a2 `shouldBe` 1

    describe "signal" do
        it "sets the semaphore" do
            result <- runEff . runConcurrent . atomically $ do
                sem <- Sem.new
                Sem.signal sem
                Sem.peek sem
            result `shouldBe` True

    describe "clear" do
        describe "when the semaphore was set" $ it "returns True" do
            result <- runEff . runConcurrent . atomically $ do
                sem <- Sem.newSet
                Sem.unset sem
            result `shouldBe` True

        describe "when the semaphore was not set" $ it "returns False" do
            result <- runEff . runConcurrent . atomically $ do
                sem <- Sem.new
                Sem.unset sem
            result `shouldBe` False

        it "leaves the semaphore clear" do
            result <- runEff . runConcurrent . atomically $ do
                sem <- Sem.newSet
                _ <- Sem.unset sem
                Sem.peek sem
            result `shouldBe` False

    describe "reset" do
        describe "when the semaphore was not set" $ it "returns True" do
            result <- runEff . runConcurrent . atomically $ do
                sem <- Sem.new
                Sem.set sem
            result `shouldBe` True

        describe "when the semaphore was already set" $ it "returns False" do
            result <- runEff . runConcurrent . atomically $ do
                sem <- Sem.newSet
                Sem.set sem
            result `shouldBe` False

        it "leaves the semaphore set" do
            result <- runEff . runConcurrent . atomically $ do
                sem <- Sem.new
                _ <- Sem.set sem
                Sem.peek sem
            result `shouldBe` True

    describe "peek" do
        describe "when the semaphore is set" $ it "returns True" do
            result <- runEff . runConcurrent . atomically $ do
                sem <- Sem.newSet
                Sem.peek sem
            result `shouldBe` True

        describe "when the semaphore is not set" $ it "returns False" do
            result <- runEff . runConcurrent . atomically $ do
                sem <- Sem.new
                Sem.peek sem
            result `shouldBe` False

        it "does not change the state of the semaphore" do
            (before, after) <- runEff . runConcurrent . atomically $ do
                sem <- Sem.newSet
                before <- Sem.peek sem
                after <- Sem.peek sem
                pure (before, after)
            (before, after) `shouldBe` (True, True)

    describe "withSemaphore" do
        it "returns the result of the enclosed computation" do
            result <- runEff . runConcurrent $ do
                sem <- atomically Sem.newSet
                Sem.withSemaphore sem $ pure (42 :: Int)
            result `shouldBe` 42

        it "signals the semaphore after the computation" do
            result <- runEff . runConcurrent $ do
                sem <- atomically Sem.newSet
                Sem.withSemaphore sem $ pure ()
                atomically $ Sem.peek sem
            result `shouldBe` True

        it "waits for the semaphore before running" do
            result <- runEff . runConcurrent . Conc.runConc $ do
                sem <- atomically Sem.new
                ref <- liftIO $ IORef.newIORef False
                _ <- Conc.fork $ do
                    liftIO $ IORef.writeIORef ref True
                    atomically $ Sem.signal sem
                Sem.withSemaphore sem $ liftIO $ IORef.readIORef ref
            result `shouldBe` True
