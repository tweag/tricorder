module Unit.Tricorder.Session.TestTargetSpec (test_TestTarget) where

import Data.Default (def)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Session.Config (Config (..))

import Tricorder.Session.Target qualified as Target
import Tricorder.Session.TestTarget qualified as TestTarget


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
        TestTarget.resolve cfg (mkTargets ["lib:mylib", "test:mylib-test"])
            @?= TestTarget.parse ["test:mylib-test"]
    , testCase "returns empty list when no test: components in targets" do
        let cfg = def :: Config
        TestTarget.resolve cfg (mkTargets ["lib:mylib", "exe:myapp"])
            @?= TestTarget.parse []
    , testCase "uses explicit testTargets list when set" do
        let cfg = def {testTargets = Just ["test:b-test"]} :: Config
        TestTarget.resolve cfg (mkTargets ["lib:a", "test:a-test", "test:b-test"])
            @?= TestTarget.parse ["test:b-test"]
    , testCase "returns empty list when testTargets is explicitly empty" do
        let cfg = def {testTargets = Just []} :: Config
        TestTarget.resolve cfg (mkTargets ["lib:a", "test:a-test"])
            @?= TestTarget.parse []
    , testCase "infers multiple test: components" do
        let cfg = def :: Config
        TestTarget.resolve cfg (mkTargets ["lib:a", "test:a-test", "test:b-test"])
            @?= TestTarget.parse ["test:a-test", "test:b-test"]
    ]
  where
    mkTargets = fmap Target.parse
