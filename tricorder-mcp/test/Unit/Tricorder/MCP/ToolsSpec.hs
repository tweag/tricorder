module Unit.Tricorder.MCP.ToolsSpec (spec_Tools) where

import Test.Hspec (Spec, describe, it, shouldBe)

import Tricorder.MCP.Tools


spec_Tools :: Spec
spec_Tools = do
    describe "toolCommand" do
        it "starts with just the directory" do
            toolCommand (Start (StartOptions {directory = "/proj"}))
                `shouldBe` ("/proj", ["start"])

        it "omits --force when unset" do
            toolCommand (Stop (StopOptions {directory = "/proj", force = Nothing}))
                `shouldBe` ("/proj", ["stop"])

        it "omits --force when explicitly false" do
            toolCommand (Restart (RestartOptions {directory = "/proj", force = Just False}))
                `shouldBe` ("/proj", ["restart"])

        it "includes --force when true" do
            toolCommand (Stop (StopOptions {directory = "/proj", force = Just True}))
                `shouldBe` ("/proj", ["stop", "--force"])

        it "combines status flags in order, with --expand carrying its argument" do
            toolCommand
                ( Status
                    StatusOptions
                        { directory = "/proj"
                        , wait = Just True
                        , json = Just True
                        , verbose = Nothing
                        , expand = Just 3
                        }
                )
                `shouldBe` ("/proj", ["status", "--wait", "--json", "--expand", "3"])

        it "turns modules into positional arguments" do
            toolCommand
                (Source (SourceOptions {directory = "/proj", modules = ["Data.Map.Strict", "Foo#bar"]}))
                `shouldBe` ("/proj", ["source", "Data.Map.Strict", "Foo#bar"])

        it "maps log_path to --print-path" do
            toolCommand (LogPath (LogPathOptions {directory = "/proj"}))
                `shouldBe` ("/proj", ["log", "--print-path"])

        it "maps log_contents to plain log" do
            toolCommand (LogContents (LogContentsOptions {directory = "/proj"}))
                `shouldBe` ("/proj", ["log"])

    describe "reportsBuildOutcome" do
        it "is true for status, test_results and eval_comments" do
            reportsBuildOutcome (Status (StatusOptions "/p" Nothing Nothing Nothing Nothing)) `shouldBe` True
            reportsBuildOutcome (TestResults (TestResultsOptions "/p" Nothing Nothing)) `shouldBe` True
            reportsBuildOutcome (EvalComments (EvalCommentsOptions "/p" Nothing Nothing)) `shouldBe` True

        it "is false for commands whose exit code reflects process failure" do
            reportsBuildOutcome (Start (StartOptions "/p")) `shouldBe` False
            reportsBuildOutcome (Stop (StopOptions "/p" Nothing)) `shouldBe` False
            reportsBuildOutcome (Restart (RestartOptions "/p" Nothing)) `shouldBe` False
            reportsBuildOutcome (Source (SourceOptions "/p" [])) `shouldBe` False
            reportsBuildOutcome (LogPath (LogPathOptions "/p")) `shouldBe` False
            reportsBuildOutcome (LogContents (LogContentsOptions "/p")) `shouldBe` False
