module Unit.Tricorder.Session.Stage.Test.CommandSpec (test_Command) where

import Data.Default (def)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Build.ByteSize (ByteSize (..), Unit (..))
import Tricorder.Session.Command.RenderedCommand (RenderedCommand (..))
import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), targetPlaceholder)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage.Test.Command
    ( RenderedTestCommand (..)
    , render
    )
import Tricorder.Session.Stage.Test.Config (TestConfig (..))
import Tricorder.Session.Stage.Test.Session (TestSession (..), resolve)
import Tricorder.Session.TestTarget (TestTarget (..))

import Tricorder.Session.CommandConfig qualified as CommandConfig
import Tricorder.Session.Stage qualified as Stage
import Tricorder.Session.Target qualified as Target


test_Command :: TestTree
test_Command =
    testGroup
        "Tricorder.Session.Stage.Test.Command"
        [ testResolveTestSession
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
    test :: CommandTemplate 'Stage.Test -> Maybe ByteSize -> TestTarget -> Text
    test template mMemoryLimit target =
        (render (TestSession template [] def) mMemoryLimit target).command.getRenderedCommand
    testTarget = TestTarget (Target.parse "test:foo")
    oneByte = ByteSize 1 B


testResolveTestSession :: TestTree
testResolveTestSession =
    testGroup
        "resolveTestSession"
        [ testCase "uses the built-in default template for Cabal when test.command_template is unset" do
            (resolve Cabal [] def).commandTemplate.template @?= "cabal repl {target}"
        , testCase "uses the built-in default template for Stack when test.command_template is unset" do
            (resolve Stack [] def).commandTemplate.template @?= "stack ghci {target}"
        , testCase "uses test.command_template when set" do
            let cfg =
                    def
                        { test =
                            def
                                { commandConfig =
                                    def
                                        { CommandConfig.commandTemplate = Just "cabal repl --repl-options=-fno-code {target}"
                                        }
                                }
                        }
            (resolve Cabal [] cfg).commandTemplate.template
                @?= "cabal repl --repl-options=-fno-code {target}"
        , testCase "carries test.extra_auto_arguments when test.command_template is unset" do
            let cfg = def {test = def {commandConfig = def {extraAutoArguments = ["--flag"]}}}
            (resolve Cabal [] cfg).commandTemplate.arguments @?= ["--flag"]
        , testCase "ignores test.extra_auto_arguments when test.command_template is set" do
            let cfg =
                    def
                        { test =
                            def
                                { commandConfig =
                                    def
                                        { commandTemplate = Just "cabal repl {target}"
                                        , extraAutoArguments = ["--flag"]
                                        }
                                }
                        }
            (resolve Cabal [] cfg).commandTemplate.arguments @?= []
        ]
