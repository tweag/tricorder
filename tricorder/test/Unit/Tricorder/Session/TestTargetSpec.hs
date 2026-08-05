module Unit.Tricorder.Session.TestTargetSpec (spec_TestTarget) where

import Data.Default (def)
import Test.Hspec (Spec, describe, it, shouldBe)

import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Target (parseTarget)
import Tricorder.Session.TestTarget (parseTestTargets, resolveTestTargets)


spec_TestTarget :: Spec
spec_TestTarget = do
    describe "resolveTestTargets" testResolveTestTargets


testResolveTestTargets :: Spec
testResolveTestTargets = do
    it "infers test: components from targets when testTargets is absent" do
        let cfg = def :: Config
        resolveTestTargets cfg (mkTargets ["lib:mylib", "test:mylib-test"])
            `shouldBe` parseTestTargets ["test:mylib-test"]

    it "returns empty list when no test: components in targets" do
        let cfg = def :: Config
        resolveTestTargets cfg (mkTargets ["lib:mylib", "exe:myapp"])
            `shouldBe` parseTestTargets []

    it "uses explicit testTargets list when set" do
        let cfg = def {testTargets = Just ["test:b-test"]} :: Config
        resolveTestTargets cfg (mkTargets ["lib:a", "test:a-test", "test:b-test"])
            `shouldBe` parseTestTargets ["test:b-test"]

    it "returns empty list when testTargets is explicitly empty" do
        let cfg = def {testTargets = Just []} :: Config
        resolveTestTargets cfg (mkTargets ["lib:a", "test:a-test"])
            `shouldBe` parseTestTargets []

    it "infers multiple test: components" do
        let cfg = def :: Config
        resolveTestTargets cfg (mkTargets ["lib:a", "test:a-test", "test:b-test"])
            `shouldBe` parseTestTargets ["test:a-test", "test:b-test"]
  where
    mkTargets = fmap parseTarget
