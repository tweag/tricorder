module Unit.Tricorder.Session.CommandSpec (spec_Command) where

import Test.Hspec (Spec, describe, it, shouldBe)

import Tricorder.Session.Command
    ( hasPlaceholder
    , renderTargetsFor
    , targetPlaceholder
    , targetsPlaceholder
    )
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Target (ComponentKind (..), Target (..))


spec_Command :: Spec
spec_Command = do
    describe "renderTargetsFor" testRenderTargetsFor
    describe "hasPlaceholder" testHasPlaceholder


--------------------------------------------------------------------------------
-- resolveRepl
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- renderTargetsFor
--------------------------------------------------------------------------------

testRenderTargetsFor :: Spec
testRenderTargetsFor = do
    it "renders bare component names for plain Stack, deduplicated" do
        renderTargetsFor Stack [Qualified Test "foo", PackageQualified "pkg" Test "foo"]
            `shouldBe` ["foo"]

    it "renders fully qualified targets for StackMulti" do
        renderTargetsFor StackMulti [PackageQualified "pkg" Test "foo"]
            `shouldBe` ["pkg:test:foo"]

    it "renders fully qualified targets for Cabal" do
        renderTargetsFor Cabal [Qualified Test "foo"] `shouldBe` ["test:foo"]


--------------------------------------------------------------------------------
-- hasPlaceholder
--------------------------------------------------------------------------------

testHasPlaceholder :: Spec
testHasPlaceholder = do
    it "is True when {targets} is present and checking for targetsPlaceholder" do
        hasPlaceholder targetsPlaceholder "cabal repl {targets}" `shouldBe` True

    it "is True when only the escaped \\{targets} is present" do
        hasPlaceholder targetsPlaceholder "echo \\{targets}" `shouldBe` True

    it "is False when neither form is present" do
        hasPlaceholder targetsPlaceholder "cabal repl test:foo" `shouldBe` False

    it "is True when {target} is present and checking for targetPlaceholder" do
        hasPlaceholder targetPlaceholder "cabal repl {target}" `shouldBe` True

    it "is False for {targets} (plural) when checking for targetPlaceholder" do
        hasPlaceholder targetPlaceholder "cabal repl {targets}" `shouldBe` False
