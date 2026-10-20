module Unit.Tricorder.Session.Stage.Eval.CommandSpec (test_Command) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Session.Command.RenderedCommand (RenderedCommand (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), targetPlaceholder)
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage.Eval.Command (render)
import Tricorder.Session.Target (Target (..))


test_Command :: TestTree
test_Command =
    testGroup
        "Tricorder.Session.Stage.Eval.Command"
        [ testGroup "renderEval" testRenderEval
        ]


testRenderEval :: [TestTree]
testRenderEval =
    [ testCase "substitutes {target} (singular) with the module being evaluated" do
        eval (CommandTemplate Cabal "cabal repl {target}" [] targetPlaceholder) [Bare "Tricorder.Foo"]
            @?= "cabal repl Tricorder.Foo"
    , testCase "does not substitute {targets} (plural) when the command uses targetPlaceholder" do
        eval (CommandTemplate Cabal "cabal repl {targets}" [] targetPlaceholder) [Bare "Tricorder.Foo"]
            @?= "cabal repl {targets}"
    ]
  where
    eval template targets = (render template targets).getRenderedCommand
