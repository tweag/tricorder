module Unit.Tricorder.Session.Stage.Eval.SessionSpec (test_Session) where

import Data.Default (def)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..))
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Stage.Eval.Session (EvalSession (..), resolve)

import Tricorder.Session.CommandConfig qualified as CommandConfig
import Tricorder.Session.Config qualified as Config


test_Session :: TestTree
test_Session =
    testGroup
        "Tricorder.Session.Stage.Eval.Session"
        [ testGroup "resolve" testResolve
        ]


testResolve :: [TestTree]
testResolve =
    [ testCase "uses the built-in default template for Cabal when eval.command_template is unset" do
        (resolve Cabal def).commandTemplate.template @?= "cabal repl {target}"
    , testCase "uses eval.command_template when set" do
        let
            cfg =
                def
                    { Config.eval =
                        def
                            { CommandConfig.commandTemplate = Just "cabal repl --builddir /tmp {target}"
                            }
                    }
        (resolve Cabal cfg).commandTemplate.template @?= "cabal repl --builddir /tmp {target}"
    , testCase "carries eval.extra_auto_arguments when eval.command_template is unset" do
        let cfg = def {eval = (def :: CommandConfig 'Eval) {extraAutoArguments = ["--flag"]}}
        (resolve Cabal cfg).commandTemplate.arguments @?= ["--flag"]
    , testCase "ignores eval.extra_auto_arguments when eval.command_template is set" do
        let cfg =
                def
                    { eval =
                        (def :: CommandConfig 'Eval)
                            { commandTemplate = Just "cabal repl {target}"
                            , extraAutoArguments = ["--flag"]
                            }
                    }
        (resolve Cabal cfg).commandTemplate.arguments @?= []
    ]
