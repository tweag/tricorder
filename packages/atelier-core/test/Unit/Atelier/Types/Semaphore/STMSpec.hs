module Unit.Atelier.Types.Semaphore.STMSpec (test_Semaphore_STM) where

import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Concurrent.STM (atomically)
import Effectful.State.Static.Shared (evalState, get, put)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Data.IORef qualified as IORef

import Atelier.Effects.Conc qualified as Conc
import Atelier.Types.Semaphore.STM qualified as Sem


test_Semaphore_STM :: TestTree
test_Semaphore_STM =
    testGroup
        "Semaphore.STM"
        [ testGroup
            "wait"
            [ testCase "should halt the computation" do
                runEff . runConcurrent . Conc.runConc . evalState @Int 0 $ do
                    sem <- atomically Sem.new

                    thread <- Conc.fork do
                        atomically $ Sem.wait sem
                        put 1

                    a1 <- get
                    liftIO $ a1 @?= 0

                    atomically $ Sem.signal sem

                    Conc.await thread

                    a2 <- get
                    liftIO $ a2 @?= 1
            ]
        , testGroup
            "signal"
            [ testCase "sets the semaphore" do
                result <- runEff . runConcurrent . atomically $ do
                    sem <- Sem.new
                    Sem.signal sem
                    Sem.peek sem
                result @?= True
            ]
        , testGroup
            "clear"
            [ testGroup
                "when the semaphore was set"
                [ testCase "returns True" do
                    result <- runEff . runConcurrent . atomically $ do
                        sem <- Sem.newSet
                        Sem.unset sem
                    result @?= True
                ]
            , testGroup
                "when the semaphore was not set"
                [ testCase "returns False" do
                    result <- runEff . runConcurrent . atomically $ do
                        sem <- Sem.new
                        Sem.unset sem
                    result @?= False
                ]
            , testCase "leaves the semaphore clear" do
                result <- runEff . runConcurrent . atomically $ do
                    sem <- Sem.newSet
                    _ <- Sem.unset sem
                    Sem.peek sem
                result @?= False
            ]
        , testGroup
            "reset"
            [ testGroup
                "when the semaphore was not set"
                [ testCase "returns True" do
                    result <- runEff . runConcurrent . atomically $ do
                        sem <- Sem.new
                        Sem.set sem
                    result @?= True
                ]
            , testGroup
                "when the semaphore was already set"
                [ testCase "returns False" do
                    result <- runEff . runConcurrent . atomically $ do
                        sem <- Sem.newSet
                        Sem.set sem
                    result @?= False
                ]
            , testCase "leaves the semaphore set" do
                result <- runEff . runConcurrent . atomically $ do
                    sem <- Sem.new
                    _ <- Sem.set sem
                    Sem.peek sem
                result @?= True
            ]
        , testGroup
            "peek"
            [ testGroup
                "when the semaphore is set"
                [ testCase "returns True" do
                    result <- runEff . runConcurrent . atomically $ do
                        sem <- Sem.newSet
                        Sem.peek sem
                    result @?= True
                ]
            , testGroup
                "when the semaphore is not set"
                [ testCase "returns False" do
                    result <- runEff . runConcurrent . atomically $ do
                        sem <- Sem.new
                        Sem.peek sem
                    result @?= False
                ]
            , testCase "does not change the state of the semaphore" do
                (before, after) <- runEff . runConcurrent . atomically $ do
                    sem <- Sem.newSet
                    before <- Sem.peek sem
                    after <- Sem.peek sem
                    pure (before, after)
                (before, after) @?= (True, True)
            ]
        , testGroup
            "withSemaphore"
            [ testCase "returns the result of the enclosed computation" do
                result <- runEff . runConcurrent $ do
                    sem <- atomically Sem.newSet
                    Sem.withSemaphore sem $ pure (42 :: Int)
                result @?= 42
            , testCase "signals the semaphore after the computation" do
                result <- runEff . runConcurrent $ do
                    sem <- atomically Sem.newSet
                    Sem.withSemaphore sem $ pure ()
                    atomically $ Sem.peek sem
                result @?= True
            , testCase "waits for the semaphore before running" do
                result <- runEff . runConcurrent . Conc.runConc $ do
                    sem <- atomically Sem.new
                    ref <- liftIO $ IORef.newIORef False
                    _ <- Conc.fork $ do
                        liftIO $ IORef.writeIORef ref True
                        atomically $ Sem.signal sem
                    Sem.withSemaphore sem $ liftIO $ IORef.readIORef ref
                result @?= True
            ]
        ]
