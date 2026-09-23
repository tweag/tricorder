module Unit.Tricorder.Session.Command.EvalSpec (spec_Eval) where

import Data.Default (def)
import Test.Hspec (Spec, describe, it, shouldBe)

import Tricorder.Session.Command (CommandTemplate (..), targetPlaceholder)
import Tricorder.Session.Command.Eval (renderEval, resolveEvalCommand)
import Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..))
import Tricorder.Session.Config (CommandConfig (..), Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Target (Target (..))


spec_Eval :: Spec
spec_Eval = do
    describe "resolveEvalCommand" testResolveEvalCommand
    describe "renderEval" testRenderEval


testRenderEval :: Spec
testRenderEval = do
    it "substitutes {target} (singular) with the module being evaluated" do
        eval (CommandTemplate Cabal "cabal repl {target}" [] targetPlaceholder) [Bare "Tricorder.Foo"]
            `shouldBe` "cabal repl Tricorder.Foo"

    it "does not substitute {targets} (plural) when the command uses targetPlaceholder" do
        eval (CommandTemplate Cabal "cabal repl {targets}" [] targetPlaceholder) [Bare "Tricorder.Foo"]
            `shouldBe` "cabal repl {targets}"
  where
    eval template targets = (renderEval template targets).getResolvedCommand


testResolveEvalCommand :: Spec
testResolveEvalCommand = do
    it "uses the built-in default template for Cabal when eval.command_template is unset" do
        (resolveEvalCommand Cabal def).template `shouldBe` "cabal repl {target}"

    it "uses eval.command_template when set" do
        let cfg =
                def
                    { eval = (def :: CommandConfig 'Eval) {commandTemplate = Just "cabal repl --builddir /tmp {target}"}
                    }
        (resolveEvalCommand Cabal cfg).template `shouldBe` "cabal repl --builddir /tmp {target}"

    it "carries eval.extra_auto_arguments when eval.command_template is unset" do
        let cfg = def {eval = (def :: CommandConfig 'Eval) {extraAutoArguments = ["--flag"]}}
        (resolveEvalCommand Cabal cfg).arguments `shouldBe` ["--flag"]

    it "ignores eval.extra_auto_arguments when eval.command_template is set" do
        let cfg =
                def
                    { eval =
                        (def :: CommandConfig 'Eval)
                            { commandTemplate = Just "cabal repl {target}"
                            , extraAutoArguments = ["--flag"]
                            }
                    }
        (resolveEvalCommand Cabal cfg).arguments `shouldBe` []
