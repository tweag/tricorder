module Unit.Tricorder.Session.TestTargetSpec (test_TestTarget) where

import Data.Default (def)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Target (parseTarget)
import Tricorder.Session.TestTarget (parseTestTargets, resolveTestTargets)


test_TestTarget :: TestTree
test_TestTarget =
    testGroup
        "TestTarget"
        [ testGroup "resolveTestTargets" testResolveTestTargets
        ]


testResolveTestTargets :: [TestTree]
testResolveTestTargets =
    [ testCase "infers test: components from targets when testTargets is absent" do
        let cfg = def :: Config
        resolveTestTargets cfg (mkTargets ["lib:mylib", "test:mylib-test"])
            @?= parseTestTargets ["test:mylib-test"]
    , testCase "returns empty list when no test: components in targets" do
        let cfg = def :: Config
        resolveTestTargets cfg (mkTargets ["lib:mylib", "exe:myapp"])
            @?= parseTestTargets []
    , testCase "uses explicit testTargets list when set" do
        let cfg = def {testTargets = Just ["test:b-test"]} :: Config
        resolveTestTargets cfg (mkTargets ["lib:a", "test:a-test", "test:b-test"])
            @?= parseTestTargets ["test:b-test"]
    , testCase "returns empty list when testTargets is explicitly empty" do
        let cfg = def {testTargets = Just []} :: Config
        resolveTestTargets cfg (mkTargets ["lib:a", "test:a-test"])
            @?= parseTestTargets []
    , testCase "infers multiple test: components" do
        let cfg = def :: Config
        resolveTestTargets cfg (mkTargets ["lib:a", "test:a-test", "test:b-test"])
            @?= parseTestTargets ["test:a-test", "test:b-test"]
    ]
  where
    mkTargets = fmap parseTarget
