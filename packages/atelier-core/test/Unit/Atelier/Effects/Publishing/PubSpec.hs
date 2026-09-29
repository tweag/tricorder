module Unit.Atelier.Effects.Publishing.PubSpec (test_Pub) where

import Effectful (runPureEff)
import Effectful.Writer.Static.Shared (execWriter)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.Effects.Publishing.Pub qualified as Pub


data TestEvent = TestEvent Text
    deriving stock (Eq, Show)


test_Pub :: TestTree
test_Pub =
    testGroup
        "Pub"
        [ testGroup
            "toWriter"
            [ testGroup
                "no events published"
                [ testCase "doesn't record events" do
                    let events =
                            runPureEff . execWriter . Pub.toWriter @TestEvent
                                $ pure ()

                    events @?= []
                ]
            , testGroup
                "events published"
                [ testCase "records events" do
                    let events =
                            runPureEff . execWriter . Pub.toWriter @TestEvent $ do
                                Pub.publish $ TestEvent "payload"
                                pure ()

                    events @?= [TestEvent "payload"]
                ]
            ]
        , testGroup
            "map"
            [ testCase "maps over one event" do
                let events =
                        runPureEff
                            . execWriter
                            . Pub.toWriter @Text
                            . Pub.map show
                            $ Pub.publish @Int 1

                events @?= ["1"]
            , testCase "maps over many events" do
                let events =
                        runPureEff
                            . execWriter
                            . Pub.toWriter @Text
                            . Pub.map show
                            $ traverse Pub.publish [1 .. 10 :: Int]

                events @?= ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
            ]
        ]
