module Unit.Tricorder.MCP.ToolsSpec (spec_Tools) where

import Test.Hspec (Spec, describe, it, shouldBe)

import Tricorder.MCP.Tools


spec_Tools :: Spec
spec_Tools = do
    describe "toolCommand" do
        it "starts with just the directory" do
            toolCommand Start
                `shouldBe` ["start"]

        it "omits --force when unset" do
            toolCommand (Stop (StopOptions {force = Nothing}))
                `shouldBe` ["stop"]

        it "omits --force when explicitly false" do
            toolCommand (Restart (RestartOptions {force = Just False}))
                `shouldBe` ["restart"]

        it "includes --force when true" do
            toolCommand (Stop (StopOptions {force = Just True}))
                `shouldBe` ["stop", "--force"]

        it "combines status flags in order, with --expand carrying its argument" do
            toolCommand
                ( Status
                    StatusOptions
                        { wait = Just True
                        , verbose = Nothing
                        , json = Just True
                        , expand = Just 3
                        }
                )
                `shouldBe` ["status", "--wait", "--json", "--expand", "3"]

        it "turns modules into positional arguments" do
            toolCommand
                (Source (SourceOptions {modules = ["Data.Map.Strict", "Foo#bar"]}))
                `shouldBe` ["source", "Data.Map.Strict", "Foo#bar"]

        it "maps log_path to --print-path" do
            toolCommand LogPath
                `shouldBe` ["log", "--print-path"]

        it "maps log_contents to plain log" do
            toolCommand LogContents
                `shouldBe` ["log"]

    describe "reportsBuildOutcome" do
        it "is true for status, test_results and eval_comments" do
            reportsBuildOutcome (Status (StatusOptions Nothing Nothing Nothing Nothing)) `shouldBe` True
            reportsBuildOutcome (TestResults (TestResultsOptions Nothing Nothing)) `shouldBe` True
            reportsBuildOutcome (EvalComments (EvalCommentsOptions Nothing Nothing)) `shouldBe` True

        it "is false for commands whose exit code reflects process failure" do
            reportsBuildOutcome Start `shouldBe` False
            reportsBuildOutcome (Stop (StopOptions Nothing)) `shouldBe` False
            reportsBuildOutcome (Restart (RestartOptions Nothing)) `shouldBe` False
            reportsBuildOutcome (Source (SourceOptions [])) `shouldBe` False
            reportsBuildOutcome LogPath `shouldBe` False
            reportsBuildOutcome LogContents `shouldBe` False
