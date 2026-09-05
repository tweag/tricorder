module Unit.Tricorder.MCP.ToolsSpec (spec_Tools) where

import Test.Hspec (Spec, describe, it, shouldBe)

import Tricorder.MCP.Tools


spec_Tools :: Spec
spec_Tools = do
    describe "toolCommand" do
        it "starts with just the directory" do
            toolCommand (Start StartOptions {projectRoot = Nothing})
                `shouldBe` (Nothing, ["start"])

        it "omits --force when unset" do
            toolCommand (Stop (StopOptions {force = Nothing, projectRoot = Nothing}))
                `shouldBe` (Nothing, ["stop"])

        it "omits --force when explicitly false" do
            toolCommand (Restart (RestartOptions {force = Just False, projectRoot = Nothing}))
                `shouldBe` (Nothing, ["restart"])

        it "includes --force when true" do
            toolCommand
                ( Stop
                    ( StopOptions
                        { force = Just True
                        , projectRoot = Nothing
                        }
                    )
                )
                `shouldBe` (Nothing, ["stop", "--force"])

        it "combines status flags in order, with --expand carrying its argument" do
            toolCommand
                ( Status
                    StatusOptions
                        { wait = Just True
                        , verbose = Nothing
                        , expand = Just 3
                        , projectRoot = Nothing
                        }
                )
                `shouldBe` (Nothing, ["status", "--wait", "--json", "--expand", "3"])

        it "turns modules into positional arguments" do
            toolCommand
                ( Source
                    ( SourceOptions
                        { projectRoot = Nothing
                        , modules = ["Data.Map.Strict", "Foo#bar"]
                        }
                    )
                )
                `shouldBe` (Nothing, ["source", "Data.Map.Strict", "Foo#bar"])

        it "maps log_path to --print-path" do
            toolCommand (LogPath LogPathOptions {projectRoot = Nothing})
                `shouldBe` (Nothing, ["log", "--print-path"])

        it "maps log_contents to plain log" do
            toolCommand (LogContents LogContentsOptions {projectRoot = Nothing})
                `shouldBe` (Nothing, ["log"])

    describe "reportsBuildOutcome" do
        it "is true for status, test_results and eval_comments" do
            reportsBuildOutcome (Status (StatusOptions Nothing Nothing Nothing Nothing)) `shouldBe` True
            reportsBuildOutcome (TestResults (TestResultsOptions Nothing Nothing Nothing)) `shouldBe` True
            reportsBuildOutcome (EvalComments (EvalCommentsOptions Nothing Nothing)) `shouldBe` True

        it "is false for commands whose exit code reflects process failure" do
            reportsBuildOutcome (Start $ StartOptions Nothing) `shouldBe` False
            reportsBuildOutcome (Stop $ StopOptions Nothing Nothing) `shouldBe` False
            reportsBuildOutcome (Restart $ RestartOptions Nothing Nothing) `shouldBe` False
            reportsBuildOutcome (Source $ SourceOptions [] Nothing) `shouldBe` False
            reportsBuildOutcome (LogPath $ LogPathOptions Nothing) `shouldBe` False
            reportsBuildOutcome (LogContents $ LogContentsOptions Nothing) `shouldBe` False
