module Unit.Atelier.Effects.Publishing.PubSpec (spec_Pub) where

import Effectful (runPureEff)
import Effectful.Writer.Static.Shared (execWriter)
import Test.Hspec (Spec, context, describe, it, shouldMatchList)

import Atelier.Effects.Publishing.Pub qualified as Pub


data TestEvent = TestEvent Text
    deriving stock (Eq, Show)


spec_Pub :: Spec
spec_Pub = do
    describe "toWriter" do
        context "no events published" do
            it "doesn't record events" do
                let events =
                        runPureEff . execWriter . Pub.toWriter @TestEvent
                            $ pure ()

                events `shouldMatchList` []

        context "events published" do
            it "records events" do
                let events =
                        runPureEff . execWriter . Pub.toWriter @TestEvent $ do
                            Pub.publish $ TestEvent "payload"
                            pure ()

                events `shouldMatchList` [TestEvent "payload"]
