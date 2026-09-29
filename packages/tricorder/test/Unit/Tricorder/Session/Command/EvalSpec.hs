module Unit.Tricorder.Session.Command.EvalSpec (test_Eval) where

import Data.Default (def)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Session.Command.Eval (renderEval, resolveEvalCommand)
import Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), targetPlaceholder)
import Tricorder.Session.Config (CommandConfig (..), Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Target (Target (..))


test_Eval :: TestTree
test_Eval =
    testGroup
        "Eval"
        [ testGroup "resolveEvalCommand" testResolveEvalCommand
        , testGroup "renderEval" testRenderEval
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
    eval template targets = (renderEval template targets).getResolvedCommand


testResolveEvalCommand :: [TestTree]
testResolveEvalCommand =
    [ testCase "uses the built-in default template for Cabal when eval.command_template is unset" do
        (resolveEvalCommand Cabal def).template @?= "cabal repl {target}"
    , testCase "uses eval.command_template when set" do
        let cfg =
                def
                    { eval = (def :: CommandConfig 'Eval) {commandTemplate = Just "cabal repl --builddir /tmp {target}"}
                    }
        (resolveEvalCommand Cabal cfg).template @?= "cabal repl --builddir /tmp {target}"
    , testCase "carries eval.extra_auto_arguments when eval.command_template is unset" do
        let cfg = def {eval = (def :: CommandConfig 'Eval) {extraAutoArguments = ["--flag"]}}
        (resolveEvalCommand Cabal cfg).arguments @?= ["--flag"]
    , testCase "ignores eval.extra_auto_arguments when eval.command_template is set" do
        let cfg =
                def
                    { eval =
                        (def :: CommandConfig 'Eval)
                            { commandTemplate = Just "cabal repl {target}"
                            , extraAutoArguments = ["--flag"]
                            }
                    }
        (resolveEvalCommand Cabal cfg).arguments @?= []
    ]
