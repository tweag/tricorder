module Unit.Atelier.Effects.YieldSpec (spec_Yield) where

import Effectful (runEff, runPureEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.State.Static.Shared (execState, modify)
import Effectful.Writer.Static.Shared (execWriter, tell)
import Test.Hspec (Spec, describe, it, shouldBe, shouldMatchList)

import Atelier.Effects.Chan (runChan)
import Atelier.Effects.Conc (runConc)

import Atelier.Effects.Await qualified as Await
import Atelier.Effects.Yield qualified as Yield


spec_Yield :: Spec
spec_Yield = do
    describe "yieldToList" testYieldToList
    describe "yieldToReverseList" testYieldToReverseList
    describe "forEach" testForEach
    describe "ignoreYield" testIgnoreYield
    describe "inFoldable" testInFoldable
    describe "cycleToYield" testCycleToYield
    describe "withYieldToList" testWithYieldToList
    describe "enumerate" testEnumerate
    describe "enumerateFrom" testEnumerateFrom
    describe "map" testMap
    describe "mapMaybe" testMapMaybe
    describe "catMaybes" testCatMaybes
    describe "filter" testFilter
    describe "changes" testChanges


testYieldToList :: Spec
testYieldToList = do
    it "collects yields in order" do
        let ((), xs) = runPureEff $ Yield.yieldToList @Int do
                Yield.yield 1
                Yield.yield 2
                Yield.yield 3
        xs `shouldMatchList` [1, 2, 3]

    it "returns empty list when nothing is yielded" do
        let (_, xs) = runPureEff $ Yield.yieldToList @Int $ pure ()
        xs `shouldMatchList` []

    it "also returns the result of the computation" do
        let (r :: Text, xs) = runPureEff $ Yield.yieldToList do
                Yield.yield (1 :: Int)
                pure "result"
        r `shouldBe` "result"
        xs `shouldMatchList` [1]


testYieldToReverseList :: Spec
testYieldToReverseList = do
    it "collects yields in reverse order" do
        let ((), xs) = runPureEff $ Yield.yieldToReverseList @Int do
                Yield.yield 1
                Yield.yield 2
                Yield.yield 3
        xs `shouldBe` [3, 2, 1]


testForEach :: Spec
testForEach = do
    it "calls the action for each yielded value" do
        let xs = runPureEff
                $ execState @[Int] mempty
                $ Yield.forEach (\x -> modify (x :)) do
                    Yield.yield 1
                    Yield.yield 2
                    Yield.yield 3
        xs `shouldBe` [3, 2, 1]

    it "can discard values" do
        let xs = runPureEff $ Yield.forEach @Int (const $ pure ()) do
                Yield.yield 1
        xs `shouldBe` ()


testIgnoreYield :: Spec
testIgnoreYield = do
    it "discards all yielded values" do
        let x = runPureEff $ Yield.ignoreYield @Int do
                Yield.yield 1
                Yield.yield 2
        x `shouldBe` ()


testInFoldable :: Spec
testInFoldable = do
    it "yields all elements of a list in order" do
        let ((), xs) = runPureEff $ Yield.yieldToList $ Yield.inFoldable @Int [1, 2, 3]
        xs `shouldBe` [1, 2, 3]

    it "yields nothing for an empty list" do
        let ((), xs) = runPureEff $ Yield.yieldToList $ Yield.inFoldable @Int []
        xs `shouldBe` []


testCycleToYield :: Spec
testCycleToYield = do
    it "yields elements of a list repeatedly in order" do
        xs <-
            runTest
                $ Await.awaitYield
                    (Yield.cycleToYield @Int [1, 2, 3])
                    (replicateM_ 7 (Await.await >>= \x -> tell [x]))
        xs `shouldBe` [1, 2, 3, 1, 2, 3, 1]
  where
    runTest = runEff . runConcurrent . runConc . runChan . execWriter


testWithYieldToList :: Spec
testWithYieldToList = do
    it "passes the collected yields to the returned function" do
        let result = runPureEff $ Yield.withYieldToList @Int do
                Yield.yield 1
                Yield.yield 2
                Yield.yield 3
                pure length
        result `shouldBe` 3

    it "passes yields in order to the function" do
        let result = runPureEff $ Yield.withYieldToList @Int do
                Yield.yield 1
                Yield.yield 2
                Yield.yield 3
                pure id
        result `shouldBe` [1, 2, 3]

    it "passes an empty list when nothing is yielded" do
        let result = runPureEff $ Yield.withYieldToList @Int do
                pure null
        result `shouldBe` True


testEnumerate :: Spec
testEnumerate = do
    it "pairs each value with its zero-based index" do
        let ((), xs) = runPureEff $ Yield.yieldToList $ Yield.enumerate do
                Yield.yield 'a'
                Yield.yield 'b'
                Yield.yield 'c'
        xs `shouldBe` [(0, 'a'), (1, 'b'), (2, 'c')]


testEnumerateFrom :: Spec
testEnumerateFrom = do
    it "pairs each value with its index starting from the given value" do
        let ((), xs) = runPureEff $ Yield.yieldToList $ Yield.enumerateFrom 5 do
                Yield.yield 'x'
                Yield.yield 'y'
        xs `shouldBe` [(5, 'x'), (6, 'y')]


testMap :: Spec
testMap = do
    it "transforms each yielded value" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.map @Int (* 2) do
                Yield.yield 1
                Yield.yield 2
                Yield.yield 3
        xs `shouldBe` [2, 4, 6]

    it "preserves order" do
        let (_, xs :: [Text]) = runPureEff $ Yield.yieldToList $ Yield.map show do
                Yield.yield @Int 1
                Yield.yield 2
        xs `shouldBe` ["1", "2"]


testMapMaybe :: Spec
testMapMaybe = do
    describe "when the function returns Just" $ it "yields transformed values" do
        let ((), xs) = runPureEff $ Yield.yieldToList $ Yield.mapMaybe (\x -> if even x then Just (x * 10) else Nothing) do
                Yield.yield @Int 1
                Yield.yield 2
                Yield.yield 3
                Yield.yield 4
        xs `shouldMatchList` [20, 40]

    describe "when the function always returns Nothing" $ it "yields nothing" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.mapMaybe @Int @Int (const Nothing) do
                Yield.yield 1
        xs `shouldMatchList` []


testCatMaybes :: Spec
testCatMaybes = do
    it "unwraps Just values and drops Nothings" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.catMaybes do
                Yield.yield (Just 1)
                Yield.yield Nothing
                Yield.yield (Just 2)
        xs `shouldBe` [1 :: Int, 2]

    it "yields nothing when all values are Nothing" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.catMaybes do
                Yield.yield (Nothing :: Maybe Int)
                Yield.yield Nothing
        xs `shouldBe` []


testFilter :: Spec
testFilter = do
    it "passes values satisfying the predicate" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.filter even do
                Yield.yield 1
                Yield.yield 2
                Yield.yield 3
                Yield.yield 4
        xs `shouldBe` [2 :: Int, 4]

    it "drops all values when predicate is always false" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.filter (const False) do
                Yield.yield (1 :: Int)
        xs `shouldBe` []

    it "passes all values when predicate is always true" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.filter (const True) do
                Yield.yield 1
                Yield.yield 2
        xs `shouldBe` [1 :: Int, 2]


testChanges :: Spec
testChanges = do
    it "suppresses yields equal to the initial value" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.changes 0 do
                Yield.yield 0
                Yield.yield 1
        xs `shouldBe` [1 :: Int]

    it "passes values that differ from the initial value" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.changes 0 do
                Yield.yield 1
                Yield.yield 2
        xs `shouldBe` [1 :: Int, 2]

    it "suppresses initial value interspersed with other values" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.changes 0 do
                Yield.yield 0
                Yield.yield 1
                Yield.yield 0
                Yield.yield 2
                Yield.yield 0
                Yield.yield 3
        xs `shouldBe` [1 :: Int, 2, 3]

    it "does not suppress non-initial values even if they repeat" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.changes 0 do
                Yield.yield 1
                Yield.yield 1
                Yield.yield 2
        xs `shouldBe` [1 :: Int, 1, 2]
