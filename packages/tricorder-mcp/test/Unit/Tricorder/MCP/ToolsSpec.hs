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
    , TestSuitesOptions (..)
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
                $ toolCommand (StartDaemon StartOptions {projectRoot = Nothing})
                    @?= (Nothing, Right ["daemon", "start"])
            , testCase "omits --ignore-pending-queries when unset"
                $ toolCommand
                    ( StopDaemon
                        ( StopOptions
                            { ignorePendingQueries = Nothing
                            , projectRoot = Nothing
                            }
                        )
                    )
                    @?= (Nothing, Right ["daemon", "stop"])
            , testCase "omits --ignore-pending-queries when explicitly false"
                $ toolCommand
                    ( RestartDaemon
                        ( RestartOptions
                            { ignorePendingQueries = Just False
                            , projectRoot = Nothing
                            }
                        )
                    )
                    @?= (Nothing, Right ["daemon", "restart"])
            , testCase "includes --ignore-pending-queries when true"
                $ toolCommand
                    ( StopDaemon
                        ( StopOptions
                            { ignorePendingQueries = Just True
                            , projectRoot = Nothing
                            }
                        )
                    )
                    @?= (Nothing, Right ["daemon", "stop", "--ignore-pending-queries"])
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
                    @?= (Nothing, Right ["status", "--json", "--expand", "3"])
            , testCase "turns modules into positional arguments"
                $ toolCommand
                    ( Source
                        ( SourceOptions
                            { projectRoot = Nothing
                            , modules = ["Data.Map.Strict", "Foo#bar"]
                            }
                        )
                    )
                    @?= (Nothing, Right ["source", "Data.Map.Strict", "Foo#bar"])
            , testCase "maps log_path to --print-path"
                $ toolCommand (LogPath LogPathOptions {projectRoot = Nothing})
                    @?= (Nothing, Right ["log", "--print-path"])
            , testCase "maps log_contents to plain log"
                $ toolCommand (LogContents LogContentsOptions {projectRoot = Nothing})
                    @?= (Nothing, Right ["log"])
            ]
        , testGroup
            "reportsBuildOutcome"
            [ testCase "is true for status, test_results and eval_comments" do
                reportsBuildOutcome (Status (StatusOptions Nothing Nothing Nothing Nothing)) @?= True
                reportsBuildOutcome (TestSuites (TestSuitesOptions Nothing Nothing Nothing Nothing Nothing))
                    @?= True
                reportsBuildOutcome (EvalComments (EvalCommentsOptions Nothing Nothing)) @?= True
            , testCase "is false for commands whose exit code reflects process failure" do
                reportsBuildOutcome (StartDaemon $ StartOptions Nothing) @?= False
                reportsBuildOutcome (StopDaemon $ StopOptions Nothing Nothing) @?= False
                reportsBuildOutcome (RestartDaemon $ RestartOptions Nothing Nothing) @?= False
                reportsBuildOutcome (Source $ SourceOptions [] Nothing) @?= False
                reportsBuildOutcome (LogPath $ LogPathOptions Nothing) @?= False
                reportsBuildOutcome (LogContents $ LogContentsOptions Nothing) @?= False
            ]
        ]
