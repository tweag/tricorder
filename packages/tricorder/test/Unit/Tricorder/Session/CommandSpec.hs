module Unit.Tricorder.Session.CommandSpec (spec_Command) where

import Atelier.Effects.FileSystem (runFileSystemState)
import Data.Default (def)
import Effectful (runPureEff)
import Effectful.State.Static.Shared (evalState)
import Test.Hspec (Spec, describe, it, shouldBe)

import Data.Map.Strict qualified as Map

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Command (resolveCommand)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Target (parseTarget)
import Tricorder.Session.TestTarget (parseTestTargets)

import Tricorder.Session.Command qualified as Command
import Tricorder.Session.Config qualified as Config


spec_Command :: Spec
spec_Command = do
    describe "resolveCommand" testResolveCommand


testResolveCommand :: Spec
testResolveCommand = do
    describe "when config has a command" do
        it "should use specified command" do
            let actual =
                    Command.render
                        . runPureEff
                        . evalState mempty
                        . runFileSystemState
                        $ resolveCommand pr def {command = Just "foo"} [] testTargets
            actual `shouldBe` "foo"

    describe "when config has explicit targets" do
        it "should spell them out verbatim, ignoring discovered test targets" do
            let actual =
                    Command.render
                        . runPureEff
                        . evalState (Map.singleton "/cabal.project" "")
                        . runFileSystemState
                        $ resolveCommand pr cfg (parseTarget <$> ["lib:foo"]) testTargets
            actual `shouldBe` "cabal repl --enable-multi-repl --builddir /replbuild lib:foo"

    describe "when config does not have a command or targets" do
        describe "and there is a cabal.project file" do
            it "should use cabal 'all' plus the discovered test targets" do
                let actual =
                        Command.render
                            . runPureEff
                            . evalState (Map.singleton "/cabal.project" "")
                            . runFileSystemState
                            $ resolveCommand pr cfg [] testTargets
                actual
                    `shouldBe` "cabal repl --enable-multi-repl --builddir /replbuild all test:foo"

        describe "and there is at least one *.cabal file" do
            it "should use cabal 'all' plus the discovered test targets" do
                let actual =
                        Command.render
                            . runPureEff
                            . evalState (Map.singleton "/foo.cabal" "")
                            . runFileSystemState
                            $ resolveCommand pr cfg [] testTargets
                actual
                    `shouldBe` "cabal repl --enable-multi-repl --builddir /replbuild all test:foo"

        describe "and there is a stack.yaml file" do
            it "should use stack ghci with 'all' plus test targets" do
                let actual =
                        Command.render
                            . runPureEff
                            . evalState (Map.singleton "/stack.yaml" "")
                            . runFileSystemState
                            $ resolveCommand pr cfg [] testTargets
                actual `shouldBe` "stack ghci all foo"

        describe "and there is both a stack.yaml and a cabal.project file" do
            it "should prefer stack ghci over cabal" do
                let actual =
                        Command.render
                            . runPureEff
                            . evalState (Map.fromList [("/stack.yaml", ""), ("/cabal.project", "")])
                            . runFileSystemState
                            $ resolveCommand pr cfg [] testTargets
                actual `shouldBe` "stack ghci all foo"

        describe "and there is both a stack.yaml and a *.cabal file" do
            it "should prefer stack ghci over cabal" do
                let actual =
                        Command.render
                            . runPureEff
                            . evalState (Map.fromList [("/stack.yaml", ""), ("/foo.cabal", "")])
                            . runFileSystemState
                            $ resolveCommand pr cfg [] testTargets
                actual `shouldBe` "stack ghci all foo"

        describe "but there are no project files" do
            it "should use default cabal repl with 'all' plus test targets" do
                let actual =
                        Command.render
                            . runPureEff
                            . evalState mempty
                            . runFileSystemState
                            $ resolveCommand pr cfg [] testTargets
                actual `shouldBe` "cabal repl --builddir /replbuild all test:foo"

        describe "and no test targets are discovered" do
            it "should fall back to plain 'all'" do
                let actual =
                        Command.render
                            . runPureEff
                            . evalState (Map.singleton "/cabal.project" "")
                            . runFileSystemState
                            $ resolveCommand pr cfg [] (parseTestTargets [])
                actual `shouldBe` "cabal repl --enable-multi-repl --builddir /replbuild all"
  where
    pr = ProjectRoot "/"
    cfg = def {Config.replBuildDir = "/replbuild"}
    testTargets = parseTestTargets ["test:foo"]
