module Unit.Tricorder.Session.Command.TestSpec (spec_Test) where

import Data.Default (def)
import Test.Hspec (Spec, describe, it, shouldBe)

import Tricorder.Build.ByteSize (ByteSize (..), Unit (..))
import Tricorder.Session.Command (CommandTemplate (..), targetPlaceholder)
import Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..))
import Tricorder.Session.Command.Test (renderTest, resolveTestCommand)
import Tricorder.Session.Config (CommandConfig (..), Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Target (parseTarget)
import Tricorder.Session.TestTarget (TestTarget (..))


spec_Test :: Spec
spec_Test = do
    describe "resolveTestCommand" testResolveTestCommand
    describe "renderTest" testRenderTest


testRenderTest :: Spec
testRenderTest = do
    it "substitutes {target} (singular) with the single test target" do
        test (CommandTemplate Cabal "cabal repl {target}" [] targetPlaceholder) Nothing testTarget
            `shouldBe` "cabal repl test:foo"

    it "does not substitute {targets} (plural) when the command uses targetPlaceholder" do
        test (CommandTemplate Cabal "cabal repl {targets}" [] targetPlaceholder) Nothing testTarget
            `shouldBe` "cabal repl {targets}"

    it "adds no memory-limit flag when no limit is configured" do
        test (CommandTemplate Cabal "cabal repl {target}" [] targetPlaceholder) Nothing testTarget
            `shouldBe` "cabal repl test:foo"

    it "appends a --repl-options memory-limit RTS flag for Cabal" do
        test (CommandTemplate Cabal "cabal repl {target}" [] targetPlaceholder) (Just oneByte) testTarget
            `shouldBe` "cabal repl test:foo --repl-options +RTS -M1 -RTS"

    it "appends a --ghc-options memory-limit RTS flag for Stack" do
        -- Plain (single-package) Stack renders bare component names, not
        -- the fully qualified target — see 'testRenderTargetsFor'.
        test (CommandTemplate Stack "stack ghci {target}" [] targetPlaceholder) (Just oneByte) testTarget
            `shouldBe` "stack ghci foo --ghc-options +RTS -M1 -RTS"

    it "appends the memory-limit flag after the user's configured arguments" do
        test
            (CommandTemplate Cabal "cabal repl {target}" ["--flag"] targetPlaceholder)
            (Just oneByte)
            testTarget
            `shouldBe` "cabal repl test:foo --flag --repl-options +RTS -M1 -RTS"
  where
    test template mMemoryLimit target = (renderTest template mMemoryLimit target).getResolvedCommand
    testTarget = TestTarget (parseTarget "test:foo")
    oneByte = ByteSize 1 B


testResolveTestCommand :: Spec
testResolveTestCommand = do
    it "uses the built-in default template for Cabal when test.command_template is unset" do
        (resolveTestCommand Cabal def).template `shouldBe` "cabal repl {target}"

    it "uses the built-in default template for Stack when test.command_template is unset" do
        (resolveTestCommand Stack def).template `shouldBe` "stack ghci {target}"

    it "ignores the deprecated top-level command" do
        let cfg = (def :: Config) {command = Just "should not apply to tests"}
        (resolveTestCommand Cabal cfg).template `shouldBe` "cabal repl {target}"

    it "uses test.command_template when set" do
        let cfg =
                def
                    { test =
                        (def :: CommandConfig 'Test)
                            { commandTemplate = Just "cabal repl --repl-options=-fno-code {target}"
                            }
                    }
        (resolveTestCommand Cabal cfg).template `shouldBe` "cabal repl --repl-options=-fno-code {target}"

    it "carries test.extra_auto_arguments when test.command_template is unset" do
        let cfg = def {test = (def :: CommandConfig 'Test) {extraAutoArguments = ["--flag"]}}
        (resolveTestCommand Cabal cfg).arguments `shouldBe` ["--flag"]

    it "ignores test.extra_auto_arguments when test.command_template is set" do
        let cfg =
                def
                    { test =
                        (def :: CommandConfig 'Test)
                            { commandTemplate = Just "cabal repl {target}"
                            , extraAutoArguments = ["--flag"]
                            }
                    }
        (resolveTestCommand Cabal cfg).arguments `shouldBe` []
