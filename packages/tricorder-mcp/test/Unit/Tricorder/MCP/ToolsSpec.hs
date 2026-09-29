module Unit.Tricorder.MCP.ToolsSpec (test_Tools) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.MCP.Tools
    ( EvalCommentsOptions (..)
    , LogContentsOptions (..)
    , LogPathOptions (..)
    , RestartOptions (..)
    , SourceOptions (..)
    , StartOptions (..)
    , StatusOptions (..)
    , StopOptions (..)
    , TestResultsOptions (..)
    , Tool (..)
    , reportsBuildOutcome
    , toolCommand
    )


test_Tools :: TestTree
test_Tools =
    testGroup
        "Tools"
        [ testGroup
            "toolCommand"
            [ testCase "starts with just the directory"
                $ toolCommand (Start StartOptions {projectRoot = Nothing})
                    @?= (Nothing, ["start"])
            , testCase "omits --force when unset"
                $ toolCommand (Stop (StopOptions {force = Nothing, projectRoot = Nothing}))
                    @?= (Nothing, ["stop"])
            , testCase "omits --force when explicitly false"
                $ toolCommand (Restart (RestartOptions {force = Just False, projectRoot = Nothing}))
                    @?= (Nothing, ["restart"])
            , testCase "includes --force when true"
                $ toolCommand
                    ( Stop
                        ( StopOptions
                            { force = Just True
                            , projectRoot = Nothing
                            }
                        )
                    )
                    @?= (Nothing, ["stop", "--force"])
            , testCase "combines status flags in order, with --expand carrying its argument"
                $ toolCommand
                    ( Status
                        StatusOptions
                            { wait = Just True
                            , verbose = Nothing
                            , expand = Just 3
                            , projectRoot = Nothing
                            }
                    )
                    @?= (Nothing, ["status", "--wait", "--json", "--expand", "3"])
            , testCase "turns modules into positional arguments"
                $ toolCommand
                    ( Source
                        ( SourceOptions
                            { projectRoot = Nothing
                            , modules = ["Data.Map.Strict", "Foo#bar"]
                            }
                        )
                    )
                    @?= (Nothing, ["source", "Data.Map.Strict", "Foo#bar"])
            , testCase "maps log_path to --print-path"
                $ toolCommand (LogPath LogPathOptions {projectRoot = Nothing})
                    @?= (Nothing, ["log", "--print-path"])
            , testCase "maps log_contents to plain log"
                $ toolCommand (LogContents LogContentsOptions {projectRoot = Nothing})
                    @?= (Nothing, ["log"])
            ]
        , testGroup
            "reportsBuildOutcome"
            [ testCase "is true for status, test_results and eval_comments" do
                reportsBuildOutcome (Status (StatusOptions Nothing Nothing Nothing Nothing)) @?= True
                reportsBuildOutcome (TestResults (TestResultsOptions Nothing Nothing Nothing)) @?= True
                reportsBuildOutcome (EvalComments (EvalCommentsOptions Nothing Nothing)) @?= True
            , testCase "is false for commands whose exit code reflects process failure" do
                reportsBuildOutcome (Start $ StartOptions Nothing) @?= False
                reportsBuildOutcome (Stop $ StopOptions Nothing Nothing) @?= False
                reportsBuildOutcome (Restart $ RestartOptions Nothing Nothing) @?= False
                reportsBuildOutcome (Source $ SourceOptions [] Nothing) @?= False
                reportsBuildOutcome (LogPath $ LogPathOptions Nothing) @?= False
                reportsBuildOutcome (LogContents $ LogContentsOptions Nothing) @?= False
            ]
        ]
