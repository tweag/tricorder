module Unit.Tricorder.Session.Command.TestSpec (test_Test) where

import Data.Default (def)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Build.ByteSize (ByteSize (..), Unit (..))
import Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..))
import Tricorder.Session.Command.Test (renderTest, resolveTestCommand)
import Tricorder.Session.CommandTemplate (CommandTemplate (..), targetPlaceholder)
import Tricorder.Session.Config (CommandConfig (..), Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Target (parseTarget)
import Tricorder.Session.TestTarget (TestTarget (..))


test_Test :: TestTree
test_Test =
    testGroup
        "Test"
        [ testGroup "resolveTestCommand" testResolveTestCommand
        , testGroup "renderTest" testRenderTest
        ]


testRenderTest :: [TestTree]
testRenderTest =
    [ testCase "substitutes {target} (singular) with the single test target" do
        test (CommandTemplate Cabal "cabal repl {target}" [] targetPlaceholder) Nothing testTarget
            @?= "cabal repl test:foo"
    , testCase "does not substitute {targets} (plural) when the command uses targetPlaceholder" do
        test (CommandTemplate Cabal "cabal repl {targets}" [] targetPlaceholder) Nothing testTarget
            @?= "cabal repl {targets}"
    , testCase "adds no memory-limit flag when no limit is configured" do
        test (CommandTemplate Cabal "cabal repl {target}" [] targetPlaceholder) Nothing testTarget
            @?= "cabal repl test:foo"
    , testCase "appends a --repl-options memory-limit RTS flag for Cabal" do
        test (CommandTemplate Cabal "cabal repl {target}" [] targetPlaceholder) (Just oneByte) testTarget
            @?= "cabal repl test:foo --repl-options +RTS -M1 -RTS"
    , testCase "appends a --ghc-options memory-limit RTS flag for Stack" do
        -- Plain (single-package) Stack renders bare component names, not
        -- the fully qualified target — see 'testRenderTargetsFor'.
        test (CommandTemplate Stack "stack ghci {target}" [] targetPlaceholder) (Just oneByte) testTarget
            @?= "stack ghci foo --ghc-options +RTS -M1 -RTS"
    , testCase "appends the memory-limit flag after the user's configured arguments" do
        test
            (CommandTemplate Cabal "cabal repl {target}" ["--flag"] targetPlaceholder)
            (Just oneByte)
            testTarget
            @?= "cabal repl test:foo --flag --repl-options +RTS -M1 -RTS"
    ]
  where
    test template mMemoryLimit target = (renderTest template mMemoryLimit target).getResolvedCommand
    testTarget = TestTarget (parseTarget "test:foo")
    oneByte = ByteSize 1 B


testResolveTestCommand :: [TestTree]
testResolveTestCommand =
    [ testCase "uses the built-in default template for Cabal when test.command_template is unset" do
        (resolveTestCommand Cabal def).template @?= "cabal repl {target}"
    , testCase "uses the built-in default template for Stack when test.command_template is unset" do
        (resolveTestCommand Stack def).template @?= "stack ghci {target}"
    , testCase "ignores the deprecated top-level command" do
        let cfg = (def :: Config) {command = Just "should not apply to tests"}
        (resolveTestCommand Cabal cfg).template @?= "cabal repl {target}"
    , testCase "uses test.command_template when set" do
        let cfg =
                def
                    { test =
                        (def :: CommandConfig 'Test)
                            { commandTemplate = Just "cabal repl --repl-options=-fno-code {target}"
                            }
                    }
        (resolveTestCommand Cabal cfg).template @?= "cabal repl --repl-options=-fno-code {target}"
    , testCase "carries test.extra_auto_arguments when test.command_template is unset" do
        let cfg = def {test = (def :: CommandConfig 'Test) {extraAutoArguments = ["--flag"]}}
        (resolveTestCommand Cabal cfg).arguments @?= ["--flag"]
    , testCase "ignores test.extra_auto_arguments when test.command_template is set" do
        let cfg =
                def
                    { test =
                        (def :: CommandConfig 'Test)
                            { commandTemplate = Just "cabal repl {target}"
                            , extraAutoArguments = ["--flag"]
                            }
                    }
        (resolveTestCommand Cabal cfg).arguments @?= []
    ]
