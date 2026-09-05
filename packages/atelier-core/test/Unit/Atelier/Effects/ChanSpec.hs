module Unit.Atelier.Effects.ChanSpec (spec_Chan) where

import Effectful (IOE, runEff)
import Effectful.Timeout (Timeout, runTimeout)
import Hedgehog (forAll, (===))
import Test.Hspec (Spec, describe, it, shouldBe)
import Test.Hspec.Hedgehog (hedgehog)

import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range

import Atelier.Effects.Chan (Chan, dupChan, newChan, readChan, readChanBatched, runChan, writeChan)
import Atelier.Time (Millisecond, Second)


spec_Chan :: Spec
spec_Chan = do
    describe "Basic Operations" do
        it "writeChan then readChan roundtrips a value" do
            result <- runChanTest $ do
                (inChan, outChan) <- newChan
                writeChan inChan (42 :: Int)
                readChan outChan
            result `shouldBe` 42

        it "preserves FIFO order" $ hedgehog do
            xs <- forAll $ Gen.list (Range.linear 0 50) (Gen.int Range.linearBounded)
            result <- liftIO $ runChanTest $ do
                (inChan, outChan) <- newChan
                traverse_ (writeChan inChan) xs
                replicateM (length xs) (readChan outChan)
            result === xs

        it "dupChan creates an independent reader that receives the same messages" do
            result <- runChanTest $ do
                (inChan, outChan1) <- newChan
                outChan2 <- dupChan inChan
                writeChan inChan (42 :: Int)
                v1 <- readChan outChan1
                v2 <- readChan outChan2
                pure (v1, v2)
            result `shouldBe` (42, 42)

    describe "readChanBatched" do
        describe "when items fill the batch before timeout" do
            it "returns a full batch" do
                result <- runChanTest $ do
                    (inChan, outChan) <- newChan
                    traverse_ (writeChan inChan) [1, 2, 3 :: Int]
                    readChanBatched (1 :: Second) 3 outChan
                result `shouldBe` (1 :| [2, 3])

            it "caps at batchSize even when more items are available" $ hedgehog do
                batchSize <- forAll $ Gen.int (Range.linear 1 20)
                extra <- forAll $ Gen.int (Range.linear 1 10)
                let n = batchSize + extra
                result <- liftIO $ runChanTest $ do
                    (inChan, outChan) <- newChan
                    traverse_ (writeChan inChan) [1 .. n]
                    readChanBatched (1 :: Second) batchSize outChan
                length result === batchSize

        describe "when timeout fires before batch is full" do
            it "returns a singleton when only one item is in the channel" do
                result <- runChanTest $ do
                    (inChan, outChan) <- newChan
                    writeChan inChan (1 :: Int)
                    readChanBatched (1 :: Millisecond) 5 outChan
                result `shouldBe` (1 :| [])

            it "returns a partial batch" do
                result <- runChanTest $ do
                    (inChan, outChan) <- newChan
                    writeChan inChan (1 :: Int)
                    writeChan inChan 2
                    readChanBatched (1 :: Millisecond) 5 outChan
                result `shouldBe` (1 :| [2])


--------------------------------------------------------------------------------
-- Test Helpers
--------------------------------------------------------------------------------

runChanTest :: Eff '[Chan, Timeout, IOE] a -> IO a
runChanTest = runEff . runTimeout . runChan
