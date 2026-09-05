module Unit.Atelier.Effects.TallySpec (spec_Tally) where

import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Reader.Static (Reader, runReader)
import Hedgehog (forAll, (===))
import Test.Hspec (Spec, describe, it, shouldBe)
import Test.Hspec.Hedgehog (hedgehog)

import Data.IORef qualified as IORef
import Data.Map.Strict qualified as Map
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range

import Atelier.Effects.Clock (Clock, runClock)
import Atelier.Effects.Conc (Conc, runConc)
import Atelier.Effects.Delay (Delay, runDelay)
import Atelier.Effects.Log (Log, runLogNoOp)
import Atelier.Effects.Tally (Config (..), Tally, runTally, withTallyCheck)


spec_Tally :: Spec
spec_Tally = do
    describe "Multiple Keys" do
        it "works with integer keys" do
            result <- runTallyTest $ checkCountsForKeys [1, 42, 999 :: Int]
            result `shouldBe` Map.fromList [(1, 1), (42, 1), (999, 1)]

    describe "Custom Classifiers" do
        it "identity classifier returns the raw hit count" do
            result <- runTallyTest $ replicateM 4 (withTallyCheck @Int 1 id pure)
            result `shouldBe` [1, 2, 3, 4 :: Int]

        it "multi-mark classifier yields correct mark for each hit" do
            -- Two thresholds: warning at >2, critical at >4
            let classify c
                    | c > 4 = Just True -- critical
                    | c > 2 = Just False -- warning
                    | otherwise = Nothing -- ok
            result <- runTallyTest $ replicateM 6 (withTallyCheck @Int 1 classify pure)
            result `shouldBe` [Nothing, Nothing, Just False, Just False, Just True, Just True]

        it "classifier producing tuples gives both count and flag" do
            let classify c = (c, c > 2)
            result <- runTallyTest $ replicateM 4 (withTallyCheck @Int 1 classify pure)
            result `shouldBe` [(1, False), (2, False), (3, True), (4, True)]

    describe "Action Execution" do
        it "continuation with side effects executes correctly" do
            result <- runTallyTest $ do
                ref <- liftIO $ IORef.newIORef ([] :: [(Int, Bool)])
                replicateM_ 3
                    $ withTallyCheck @Int 1 (\c -> (c, c > 2))
                    $ \(count, exceeded) ->
                        liftIO $ IORef.modifyIORef' ref ((count, exceeded) :)
                liftIO $ reverse <$> IORef.readIORef ref
            result `shouldBe` [(1, False), (2, False), (3, True)]

    describe "Properties" do
        it "kth call receives count k (count fidelity)" $ hedgehog $ do
            n <- forAll $ Gen.int (Range.linear 1 100)
            results <- liftIO $ runTallyTest $ replicateM n checkCount
            results === [1 .. n]

        it "no lost updates under concurrency" $ hedgehog $ do
            n <- forAll $ Gen.int (Range.linear 1 50)
            finalCount <- liftIO $ runTallyTest $ do
                replicateM_ n checkCount
                checkCount
            finalCount === n + 1

        it "classifier output is passed through unchanged" $ hedgehog $ do
            n <- forAll $ Gen.int (Range.linear 1 50)
            offset <- forAll $ Gen.int (Range.linear 0 200)
            results <- liftIO $ runTallyTest $ replicateM n (withTallyCheck @Int 1 (+ offset) pure)
            results === map (+ offset) [1 .. n]


--------------------------------------------------------------------------------
-- Test Helpers
--------------------------------------------------------------------------------

-- | Run a tally test
runTallyTest :: Eff '[Tally Int, Reader Config, Clock, Delay, Conc, Log, Concurrent, IOE] a -> IO a
runTallyTest action =
    runEff
        . runConcurrent
        . runLogNoOp
        . runConc
        . runDelay
        . runClock
        . runReader (Config {entryTtl = 3600, cleanupInterval = 3600})
        . runTally @Int
        $ action


-- | Increment the tally for the default test key and return the raw count
checkCount :: (Tally Int :> es) => Eff es Int
checkCount = withTallyCheck @Int 1 id pure


-- | Increment the tally for a specific key and return the raw count
checkCountForKey :: (Hashable key, Ord key, Tally key :> es) => key -> Eff es Int
checkCountForKey key = withTallyCheck key id pure


-- | Increment the tally for each key and return a map of key → count
checkCountsForKeys :: (Hashable key, Ord key, Tally key :> es) => [key] -> Eff es (Map key Int)
checkCountsForKeys keys = Map.fromList . zip keys <$> traverse checkCountForKey keys
