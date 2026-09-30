module Unit.Tricorder.Session.Stage.Eval.CommandSpec (test_Command) where

import Data.Default (def)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..))
import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), targetPlaceholder)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Stage.Eval.Command (render, resolve)
import Tricorder.Session.Target (Target (..))


test_Command :: TestTree
test_Command =
    testGroup
        "Tricorder.Session.Stage.Eval.Command"
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
    eval template targets = (render template targets).getResolvedCommand


testResolveEvalCommand :: [TestTree]
testResolveEvalCommand =
    [ testCase "uses the built-in default template for Cabal when eval.command_template is unset" do
        (resolve Cabal def).template @?= "cabal repl {target}"
    , testCase "uses eval.command_template when set" do
        let cfg =
                def
                    { eval = (def :: CommandConfig 'Eval) {commandTemplate = Just "cabal repl --builddir /tmp {target}"}
                    }
        (resolve Cabal cfg).template @?= "cabal repl --builddir /tmp {target}"
    , testCase "carries eval.extra_auto_arguments when eval.command_template is unset" do
        let cfg = def {eval = (def :: CommandConfig 'Eval) {extraAutoArguments = ["--flag"]}}
        (resolve Cabal cfg).arguments @?= ["--flag"]
    , testCase "ignores eval.extra_auto_arguments when eval.command_template is set" do
        let cfg =
                def
                    { eval =
                        (def :: CommandConfig 'Eval)
                            { commandTemplate = Just "cabal repl {target}"
                            , extraAutoArguments = ["--flag"]
                            }
                    }
        (resolve Cabal cfg).arguments @?= []
    ]
