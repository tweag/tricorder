module Unit.Atelier.Effects.PublishingSpec (spec_Publishing) where

import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Data.Time (UTCTime, getCurrentTime)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Test.Hspec (Spec, describe, it, shouldBe)

import Atelier.Effects.Chan (Chan, runChan)
import Atelier.Effects.Clock (Clock, runClock, runClockConst)
import Atelier.Effects.Conc (Conc, runConc)
import Atelier.Effects.Publishing (runPubSub)
import Atelier.Effects.Publishing.Pub (Pub)
import Atelier.Effects.Publishing.Sub (Sub)

import Atelier.Effects.Publishing.Pub qualified as Pub
import Atelier.Effects.Publishing.Sub qualified as Sub


data TestEvent = TestEvent Text
    deriving stock (Eq, Show)


spec_Publishing :: Spec
spec_Publishing = do
    describe "runPubSub" do
        it "listener receives a published event" do
            result <- runPubSubTest $ do
                received <- liftIO newEmptyMVar
                Sub.forkListener_ @TestEvent \event ->
                    liftIO $ putMVar received event
                Pub.publish (TestEvent "hello")
                liftIO $ takeMVar received
            result `shouldBe` TestEvent "hello"

        it "event timestamp matches Clock at publish time" do
            t0 <- getCurrentTime
            result <- runPubSubTestWithClock t0 $ do
                received <- liftIO newEmptyMVar
                Sub.forkListener @TestEvent \ts _event ->
                    liftIO $ putMVar received ts
                Pub.publish (TestEvent "hello")
                liftIO $ takeMVar received
            result `shouldBe` t0

        it "multiple listeners each receive the published event" do
            result <- runPubSubTest $ do
                recv1 <- liftIO newEmptyMVar
                recv2 <- liftIO newEmptyMVar
                Sub.forkListener_ @TestEvent \event -> liftIO $ putMVar recv1 event
                Sub.forkListener_ @TestEvent \event -> liftIO $ putMVar recv2 event
                Pub.publish (TestEvent "hello")
                e1 <- liftIO $ takeMVar recv1
                e2 <- liftIO $ takeMVar recv2
                pure (e1, e2)
            result `shouldBe` (TestEvent "hello", TestEvent "hello")


--------------------------------------------------------------------------------
-- Test Helpers
--------------------------------------------------------------------------------

runPubSubTest
    :: Eff '[Pub TestEvent, Sub TestEvent, Chan, Clock, Conc, Concurrent, IOE] a
    -> IO a
runPubSubTest =
    runEff
        . runConcurrent
        . runConc
        . runClock
        . runChan
        . runPubSub @TestEvent


runPubSubTestWithClock
    :: UTCTime
    -> Eff '[Pub TestEvent, Sub TestEvent, Chan, Clock, Conc, Concurrent, IOE] a
    -> IO a
runPubSubTestWithClock t =
    runEff
        . runConcurrent
        . runConc
        . runClockConst t
        . runChan
        . runPubSub @TestEvent
