module Unit.Tricorder.Session.CommandTemplateSpec (test_Command) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Session.CommandTemplate
    ( hasPlaceholder
    , renderTargetsFor
    , targetPlaceholder
    , targetsPlaceholder
    )
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Target (ComponentKind (..), Target (..))


test_Command :: TestTree
test_Command =
    testGroup
        "Command"
        [ testGroup "renderTargetsFor" testRenderTargetsFor
        , testGroup "hasPlaceholder" testHasPlaceholder
        ]


--------------------------------------------------------------------------------
-- renderTargetsFor
--------------------------------------------------------------------------------

testRenderTargetsFor :: [TestTree]
testRenderTargetsFor =
    [ testCase "renders bare component names for plain Stack, deduplicated" do
        renderTargetsFor Stack [Qualified Test "foo", PackageQualified "pkg" Test "foo"]
            @?= ["foo"]
    , testCase "renders fully qualified targets for StackMulti" do
        renderTargetsFor StackMulti [PackageQualified "pkg" Test "foo"]
            @?= ["pkg:test:foo"]
    , testCase "renders fully qualified targets for Cabal" do
        renderTargetsFor Cabal [Qualified Test "foo"] @?= ["test:foo"]
    ]


--------------------------------------------------------------------------------
-- hasPlaceholder
--------------------------------------------------------------------------------

testHasPlaceholder :: [TestTree]
testHasPlaceholder =
    [ testCase "is True when {targets} is present and checking for targetsPlaceholder" do
        hasPlaceholder targetsPlaceholder "cabal repl {targets}" @?= True
    , testCase "is True when only the escaped \\{targets} is present" do
        hasPlaceholder targetsPlaceholder "echo \\{targets}" @?= True
    , testCase "is False when neither form is present" do
        hasPlaceholder targetsPlaceholder "cabal repl test:foo" @?= False
    , testCase "is True when {target} is present and checking for targetPlaceholder" do
        hasPlaceholder targetPlaceholder "cabal repl {target}" @?= True
    , testCase "is False for {targets} (plural) when checking for targetPlaceholder" do
        hasPlaceholder targetPlaceholder "cabal repl {targets}" @?= False
    ]
