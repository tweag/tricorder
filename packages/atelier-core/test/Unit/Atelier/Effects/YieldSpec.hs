module Unit.Atelier.Effects.YieldSpec (test_Yield) where

import Effectful (runEff, runPureEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.State.Static.Shared (execState, modify)
import Effectful.Writer.Static.Shared (execWriter, tell)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.Effects.Chan (runChan)
import Atelier.Effects.Conc (runConc)

import Atelier.Effects.Await qualified as Await
import Atelier.Effects.Yield qualified as Yield


test_Yield :: TestTree
test_Yield =
    testGroup
        "Yield"
        [ testGroup "yieldToList" testYieldToList
        , testGroup "yieldToReverseList" testYieldToReverseList
        , testGroup "forEach" testForEach
        , testGroup "ignoreYield" testIgnoreYield
        , testGroup "inFoldable" testInFoldable
        , testGroup "cycleToYield" testCycleToYield
        , testGroup "withYieldToList" testWithYieldToList
        , testGroup "enumerate" testEnumerate
        , testGroup "enumerateFrom" testEnumerateFrom
        , testGroup "map" testMap
        , testGroup "mapMaybe" testMapMaybe
        , testGroup "catMaybes" testCatMaybes
        , testGroup "filter" testFilter
        , testGroup "changes" testChanges
        ]


testYieldToList :: [TestTree]
testYieldToList =
    [ testCase "collects yields in order" do
        let ((), xs) = runPureEff $ Yield.yieldToList @Int do
                Yield.yield 1
                Yield.yield 2
                Yield.yield 3
        xs @?= [1, 2, 3]
    , testCase "returns empty list when nothing is yielded" do
        let (_, xs) = runPureEff $ Yield.yieldToList @Int $ pure ()
        xs @?= []
    , testCase "also returns the result of the computation" do
        let (r :: Text, xs) = runPureEff $ Yield.yieldToList do
                Yield.yield (1 :: Int)
                pure "result"
        r @?= "result"
        xs @?= [1]
    ]


testYieldToReverseList :: [TestTree]
testYieldToReverseList =
    [ testCase "collects yields in reverse order" do
        let ((), xs) = runPureEff $ Yield.yieldToReverseList @Int do
                Yield.yield 1
                Yield.yield 2
                Yield.yield 3
        xs @?= [3, 2, 1]
    ]


testForEach :: [TestTree]
testForEach =
    [ testCase "calls the action for each yielded value" do
        let xs = runPureEff
                $ execState @[Int] mempty
                $ Yield.forEach (\x -> modify (x :)) do
                    Yield.yield 1
                    Yield.yield 2
                    Yield.yield 3
        xs @?= [3, 2, 1]
    , testCase "can discard values" do
        let xs = runPureEff $ Yield.forEach @Int (const $ pure ()) do
                Yield.yield 1
        xs @?= ()
    ]


testIgnoreYield :: [TestTree]
testIgnoreYield =
    [ testCase "discards all yielded values" do
        let x = runPureEff $ Yield.ignoreYield @Int do
                Yield.yield 1
                Yield.yield 2
        x @?= ()
    ]


testInFoldable :: [TestTree]
testInFoldable =
    [ testCase "yields all elements of a list in order" do
        let ((), xs) = runPureEff $ Yield.yieldToList $ Yield.inFoldable @Int [1, 2, 3]
        xs @?= [1, 2, 3]
    , testCase "yields nothing for an empty list" do
        let ((), xs) = runPureEff $ Yield.yieldToList $ Yield.inFoldable @Int []
        xs @?= []
    ]


testCycleToYield :: [TestTree]
testCycleToYield =
    [ testCase "yields elements of a list repeatedly in order" do
        xs <-
            runTest
                $ Await.awaitYield
                    (Yield.cycleToYield @Int [1, 2, 3])
                    (replicateM_ 7 (Await.await >>= \x -> tell [x]))
        xs @?= [1, 2, 3, 1, 2, 3, 1]
    ]
  where
    runTest = runEff . runConcurrent . runConc . runChan . execWriter


testWithYieldToList :: [TestTree]
testWithYieldToList =
    [ testCase "passes the collected yields to the returned function" do
        let result = runPureEff $ Yield.withYieldToList @Int do
                Yield.yield 1
                Yield.yield 2
                Yield.yield 3
                pure length
        result @?= 3
    , testCase "passes yields in order to the function" do
        let result = runPureEff $ Yield.withYieldToList @Int do
                Yield.yield 1
                Yield.yield 2
                Yield.yield 3
                pure id
        result @?= [1, 2, 3]
    , testCase "passes an empty list when nothing is yielded" do
        let result = runPureEff $ Yield.withYieldToList @Int do
                pure null
        result @?= True
    ]


testEnumerate :: [TestTree]
testEnumerate =
    [ testCase "pairs each value with its zero-based index" do
        let ((), xs) = runPureEff $ Yield.yieldToList $ Yield.enumerate do
                Yield.yield 'a'
                Yield.yield 'b'
                Yield.yield 'c'
        xs @?= [(0, 'a'), (1, 'b'), (2, 'c')]
    ]


testEnumerateFrom :: [TestTree]
testEnumerateFrom =
    [ testCase "pairs each value with its index starting from the given value" do
        let ((), xs) = runPureEff $ Yield.yieldToList $ Yield.enumerateFrom 5 do
                Yield.yield 'x'
                Yield.yield 'y'
        xs @?= [(5, 'x'), (6, 'y')]
    ]


testMap :: [TestTree]
testMap =
    [ testCase "transforms each yielded value" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.map @Int (* 2) do
                Yield.yield 1
                Yield.yield 2
                Yield.yield 3
        xs @?= [2, 4, 6]
    , testCase "preserves order" do
        let (_, xs :: [Text]) = runPureEff $ Yield.yieldToList $ Yield.map show do
                Yield.yield @Int 1
                Yield.yield 2
        xs @?= ["1", "2"]
    ]


testMapMaybe :: [TestTree]
testMapMaybe =
    [ testGroup
        "when the function returns Just"
        [ testCase "yields transformed values" do
            let ((), xs) = runPureEff $ Yield.yieldToList $ Yield.mapMaybe (\x -> if even x then Just (x * 10) else Nothing) do
                    Yield.yield @Int 1
                    Yield.yield 2
                    Yield.yield 3
                    Yield.yield 4
            xs @?= [20, 40]
        ]
    , testGroup
        "when the function always returns Nothing"
        [ testCase "yields nothing" do
            let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.mapMaybe @Int @Int (const Nothing) do
                    Yield.yield 1
            xs @?= []
        ]
    ]


testCatMaybes :: [TestTree]
testCatMaybes =
    [ testCase "unwraps Just values and drops Nothings" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.catMaybes do
                Yield.yield (Just 1)
                Yield.yield Nothing
                Yield.yield (Just 2)
        xs @?= [1 :: Int, 2]
    , testCase "yields nothing when all values are Nothing" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.catMaybes do
                Yield.yield (Nothing :: Maybe Int)
                Yield.yield Nothing
        xs @?= []
    ]


testFilter :: [TestTree]
testFilter =
    [ testCase "passes values satisfying the predicate" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.filter even do
                Yield.yield 1
                Yield.yield 2
                Yield.yield 3
                Yield.yield 4
        xs @?= [2 :: Int, 4]
    , testCase "drops all values when predicate is always false" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.filter (const False) do
                Yield.yield (1 :: Int)
        xs @?= []
    , testCase "passes all values when predicate is always true" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.filter (const True) do
                Yield.yield 1
                Yield.yield 2
        xs @?= [1 :: Int, 2]
    ]


testChanges :: [TestTree]
testChanges =
    [ testCase "suppresses yields equal to the initial value" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.changes 0 do
                Yield.yield 0
                Yield.yield 1
        xs @?= [1 :: Int]
    , testCase "passes values that differ from the initial value" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.changes 0 do
                Yield.yield 1
                Yield.yield 2
        xs @?= [1 :: Int, 2]
    , testCase "suppresses initial value interspersed with other values" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.changes 0 do
                Yield.yield 0
                Yield.yield 1
                Yield.yield 0
                Yield.yield 2
                Yield.yield 0
                Yield.yield 3
        xs @?= [1 :: Int, 2, 3]
    , testCase "does not suppress non-initial values even if they repeat" do
        let (_, xs) = runPureEff $ Yield.yieldToList $ Yield.changes 0 do
                Yield.yield 1
                Yield.yield 1
                Yield.yield 2
        xs @?= [1 :: Int, 1, 2]
    ]
