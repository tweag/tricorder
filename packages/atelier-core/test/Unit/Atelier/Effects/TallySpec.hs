module Unit.Atelier.Effects.TallySpec (test_Tally) where

import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Reader.Static (Reader, runReader)
import Hedgehog (forAll, property, (===))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))
import Test.Tasty.Hedgehog (testProperty)

import Data.IORef qualified as IORef
import Data.Map.Strict qualified as Map
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range

import Atelier.Effects.Cache.Config (Config (..))
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Tally (Tally)

import Atelier.Effects.Clock qualified as Clock
import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Tally qualified as Tally


test_Tally :: TestTree
test_Tally =
    testGroup
        "Tally"
        [ testGroup
            "Multiple Keys"
            [ testCase "works with integer keys" do
                result <- runTallyTest $ checkCountsForKeys [1, 42, 999 :: Int]
                result @?= Map.fromList [(1, 1), (42, 1), (999, 1)]
            ]
        , testGroup
            "Action Execution"
            [ testCase "continuation with side effects executes correctly" do
                result <- runTallyTest $ do
                    ref <- liftIO $ IORef.newIORef ([] :: [Int])
                    replicateM_ 3
                        $ Tally.count @Int
                            1
                            \count ->
                                liftIO $ IORef.modifyIORef' ref (count :)
                    liftIO $ reverse <$> IORef.readIORef ref
                result @?= [1, 2, 3]
            ]
        , testGroup
            "Properties"
            [ testProperty "kth call receives count k (count fidelity)" $ property $ do
                n <- forAll $ Gen.int (Range.linear 1 100)
                results <- liftIO $ runTallyTest $ replicateM n checkCount
                results === [1 .. n]
            , testProperty "no lost updates under concurrency" $ property $ do
                n <- forAll $ Gen.int (Range.linear 1 50)
                finalCount <- liftIO $ runTallyTest $ do
                    replicateM_ n checkCount
                    checkCount
                finalCount === n + 1
            ]
        ]


--------------------------------------------------------------------------------
-- Test Helpers
--------------------------------------------------------------------------------

-- | Run a tally test
runTallyTest :: Eff '[Tally Int, Reader Config, Clock, Delay, Conc, Log, Concurrent, IOE] a -> IO a
runTallyTest action =
    runEff
        . runConcurrent
        . Log.runNoOp
        . Conc.runIO
        . Delay.runIO
        . Clock.runIO
        . runReader (Config {entryTtl = 3600, cleanupInterval = 3600})
        . Tally.run @Int
        $ action


-- | Increment the tally for the default test key and return the raw count
checkCount :: (Tally Int :> es) => Eff es Int
checkCount = Tally.count @Int 1 pure


-- | Increment the tally for a specific key and return the raw count
checkCountForKey :: (Hashable key, Ord key, Tally key :> es) => key -> Eff es Int
checkCountForKey key = Tally.count key pure


-- | Increment the tally for each key and return a map of key → count
checkCountsForKeys :: (Hashable key, Ord key, Tally key :> es) => [key] -> Eff es (Map key Int)
checkCountsForKeys keys = Map.fromList . zip keys <$> traverse checkCountForKey keys
