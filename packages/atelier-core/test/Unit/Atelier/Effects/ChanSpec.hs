module Unit.Atelier.Effects.ChanSpec (test_Chan) where

import Effectful (IOE, runEff)
import Effectful.Timeout (Timeout, runTimeout)
import Hedgehog (forAll, property, (===))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))
import Test.Tasty.Hedgehog (testProperty)

import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range

import Atelier.Effects.Chan (Chan)
import Atelier.Time (Millisecond, Second)

import Atelier.Effects.Chan qualified as Chan


test_Chan :: TestTree
test_Chan =
    testGroup
        "Chan"
        [ testGroup
            "Basic Operations"
            [ testCase "Chan.write then Chan.read roundtrips a value" do
                result <- runChanTest $ do
                    (inChan, outChan) <- Chan.new
                    Chan.write inChan (42 :: Int)
                    Chan.read outChan
                result @?= 42
            , testProperty "preserves FIFO order" $ property do
                xs <- forAll $ Gen.list (Range.linear 0 50) (Gen.int Range.linearBounded)
                result <- liftIO $ runChanTest $ do
                    (inChan, outChan) <- Chan.new
                    traverse_ (Chan.write inChan) xs
                    replicateM (length xs) (Chan.read outChan)
                result === xs
            , testCase "Chan.dup creates an independent reader that receives the same messages" do
                result <- runChanTest $ do
                    (inChan, outChan1) <- Chan.new
                    outChan2 <- Chan.dup inChan
                    Chan.write inChan (42 :: Int)
                    v1 <- Chan.read outChan1
                    v2 <- Chan.read outChan2
                    pure (v1, v2)
                result @?= (42, 42)
            ]
        , testGroup
            "Chan.readBatched"
            [ testGroup
                "when items fill the batch before timeout"
                [ testCase "returns a full batch" do
                    result <- runChanTest $ do
                        (inChan, outChan) <- Chan.new
                        traverse_ (Chan.write inChan) [1, 2, 3 :: Int]
                        Chan.readBatched (1 :: Second) 3 outChan
                    result @?= (1 :| [2, 3])
                , testProperty "caps at batchSize even when more items are available" $ property do
                    batchSize <- forAll $ Gen.int (Range.linear 1 20)
                    extra <- forAll $ Gen.int (Range.linear 1 10)
                    let n = batchSize + extra
                    result <- liftIO $ runChanTest $ do
                        (inChan, outChan) <- Chan.new
                        traverse_ (Chan.write inChan) [1 .. n]
                        Chan.readBatched (1 :: Second) batchSize outChan
                    length result === batchSize
                ]
            , testGroup
                "when timeout fires before batch is full"
                [ testCase "returns a singleton when only one item is in the channel" do
                    result <- runChanTest $ do
                        (inChan, outChan) <- Chan.new
                        Chan.write inChan (1 :: Int)
                        Chan.readBatched (1 :: Millisecond) 5 outChan
                    result @?= (1 :| [])
                , testCase "returns a partial batch" do
                    result <- runChanTest $ do
                        (inChan, outChan) <- Chan.new
                        Chan.write inChan (1 :: Int)
                        Chan.write inChan 2
                        Chan.readBatched (1 :: Millisecond) 5 outChan
                    result @?= (1 :| [2])
                ]
            ]
        ]


--------------------------------------------------------------------------------
-- Test Helpers
--------------------------------------------------------------------------------

runChanTest :: Eff '[Chan, Timeout, IOE] a -> IO a
runChanTest = runEff . runTimeout . Chan.run
