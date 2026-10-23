module Unit.Atelier.Effects.PubSubSpec (test_PubSub) where

import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Data.Time (UTCTime, getCurrentTime)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc, runConc)
import Atelier.Effects.PubSub.Pub (Pub)
import Atelier.Effects.PubSub.Sub (Sub)

import Atelier.Effects.Chan qualified as Chan
import Atelier.Effects.Clock qualified as Clock
import Atelier.Effects.PubSub qualified as PubSub
import Atelier.Effects.PubSub.Pub qualified as Pub
import Atelier.Effects.PubSub.Sub qualified as Sub


data TestEvent = TestEvent Text
    deriving stock (Eq, Show)


test_PubSub :: TestTree
test_PubSub =
    testGroup
        "PubSub"
        [ testGroup
            "run"
            [ testCase "listener receives a published event" do
                result <- runPubSubTest $ do
                    received <- liftIO newEmptyMVar
                    Sub.forkListener_ @TestEvent \event ->
                        liftIO $ putMVar received event
                    Pub.publish (TestEvent "hello")
                    liftIO $ takeMVar received
                result @?= TestEvent "hello"
            , testCase "event timestamp matches Clock at publish time" do
                t0 <- getCurrentTime
                result <- runPubSubTestWithClock t0 $ do
                    received <- liftIO newEmptyMVar
                    Sub.forkListener @TestEvent \ts _event ->
                        liftIO $ putMVar received ts
                    Pub.publish (TestEvent "hello")
                    liftIO $ takeMVar received
                result @?= t0
            , testCase "multiple listeners each receive the published event" do
                result <- runPubSubTest $ do
                    recv1 <- liftIO newEmptyMVar
                    recv2 <- liftIO newEmptyMVar
                    Sub.forkListener_ @TestEvent \event -> liftIO $ putMVar recv1 event
                    Sub.forkListener_ @TestEvent \event -> liftIO $ putMVar recv2 event
                    Pub.publish (TestEvent "hello")
                    e1 <- liftIO $ takeMVar recv1
                    e2 <- liftIO $ takeMVar recv2
                    pure (e1, e2)
                result @?= (TestEvent "hello", TestEvent "hello")
            ]
        ]


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
        . Clock.runIO
        . Chan.run
        . PubSub.run @TestEvent


runPubSubTestWithClock
    :: UTCTime
    -> Eff '[Pub TestEvent, Sub TestEvent, Chan, Clock, Conc, Concurrent, IOE] a
    -> IO a
runPubSubTestWithClock t =
    runEff
        . runConcurrent
        . runConc
        . Clock.runConst t
        . Chan.run
        . PubSub.run @TestEvent
