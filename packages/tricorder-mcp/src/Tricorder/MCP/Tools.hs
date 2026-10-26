module Tricorder.MCP.Tools
    ( Tool (..)
    , StartOptions (..)
    , StopOptions (..)
    , RestartOptions (..)
    , StatusOptions (..)
    , TestSuitesOptions (..)
    , SourceOptions (..)
    , EvalCommentsOptions (..)
    , LogPathOptions (..)
    , LogContentsOptions (..)
    , handleTool
    , toolCommand
    , toolDescriptions
    , reportsBuildOutcome
    )
where

import Control.Exception (IOException, try)
import MCP.Server (ClientContext, Content (..), ToolResult, toolError, toolResult)
import MCP.Server.Derive (DefinitionOptions (..), defaultDefinitionOptions)
import System.Directory (listDirectory)
import System.Environment (lookupEnv)
import System.Exit (ExitCode (..))
import System.Posix (getWorkingDirectory)
import System.Process.Typed (proc, readProcess, setWorkingDir)
import Tricorder.API.Force (Force)
import Tricorder.API.IfBuildIsPending (IfBuildIsPending)
import Tricorder.API.OutputFormat (OutputFormat (..))
import Tricorder.API.TestFilter (TestFilter)
import Tricorder.SourceLookup.SourceQuery (parseSourceQuery)
import Prelude hiding (force)

import Data.ByteString.Lazy qualified as BSL
import Data.List qualified as List
import Options.Applicative.Help qualified as Doc
import Tricorder.API.Command qualified as Command
import Tricorder.API.Daemon.Command qualified as Daemon.Command
import Tricorder.API.FieldMask qualified as FieldMask
import Tricorder.API.FieldMask.Args qualified as FieldMask.Args
import Tricorder.API.FieldMask.Schema qualified as FieldMask.Schema
import Tricorder.API.Force qualified as Force
import Tricorder.API.IfBuildIsPending qualified as IfBuildIsPending
import Tricorder.API.IfDaemonIsStopped qualified as IfDaemonIsStopped
import Tricorder.API.OutputFormat qualified as OutputFormat
import Tricorder.API.Test qualified as Test
import Tricorder.API.Test.SuiteView.Schema qualified as Test.SuiteView.Schema
import Tricorder.API.TestFilter qualified as TestFilter


data Tool
    = StartDaemon StartOptions
    | StopDaemon StopOptions
    | RestartDaemon RestartOptions
    | Status StatusOptions
    | TestSuites TestSuitesOptions
    | Source SourceOptions
    | EvalComments EvalCommentsOptions
    | LogPath LogPathOptions
    | LogContents LogContentsOptions


newtype StartOptions = StartOptions {projectRoot :: Maybe Text}


data StopOptions = StopOptions
    { force :: Maybe Bool
    , projectRoot :: Maybe Text
    }


data RestartOptions = RestartOptions
    { force :: Maybe Bool
    , projectRoot :: Maybe Text
    }


data StatusOptions = StatusOptions
    { wait :: Maybe Bool
    , verbose :: Maybe Bool
    , expand :: Maybe Int
    , projectRoot :: Maybe Text
    }


data TestSuitesOptions = TestSuitesOptions
    { testFilter :: Maybe TestFilter
    , wait :: Maybe Bool
    , projectRoot :: Maybe Text
    , fields :: Maybe Text
    , suiteNames :: Maybe [Text]
    }


data SourceOptions = SourceOptions
    { modules :: [Text]
    , projectRoot :: Maybe Text
    }


data EvalCommentsOptions = EvalCommentsOptions
    { wait :: Maybe Bool
    , projectRoot :: Maybe Text
    }


newtype LogPathOptions = LogPathOptions
    { projectRoot :: Maybe Text
    }


newtype LogContentsOptions = LogContentsOptions
    { projectRoot :: Maybe Text
    }


toolDescriptions :: [(String, DefinitionOptions)]
toolDescriptions =
    [
        ( "StartDaemon"
        , defaultDefinitionOptions
            { optDescription = Just "Start the tricorder daemon (no-op if already running)."
            , optTitle = Just "Start daemon"
            , optFieldDescriptions = [projectRootDesc]
            }
        )
    ,
        ( "StopDaemon"
        , defaultDefinitionOptions
            { optDescription = Just "Stop the tricorder daemon."
            , optTitle = Just "Stop daemon"
            , optFieldDescriptions =
                [ forceDesc
                , projectRootDesc
                ]
            }
        )
    ,
        ( "RestartDaemon"
        , defaultDefinitionOptions
            { optDescription = Just "Restart the tricorder daemon."
            , optTitle = Just "Restart daemon"
            , optFieldDescriptions =
                [ forceDesc
                , projectRootDesc
                ]
            }
        )
    ,
        ( "Status"
        , defaultDefinitionOptions
            { optDescription = Just "Get the current GHCi build status: diagnostics, errors and warnings."
            , optTitle = Just "View built status"
            , optFieldDescriptions =
                [ waitDesc
                , ("verbose", "Include full GHC message bodies and full test suite error messages.")
                , ("expand", "Only show the summary line and full message body for diagnostic #N.")
                , projectRootDesc
                ]
            }
        )
    ,
        ( "TestSuites"
        , defaultDefinitionOptions
            { optDescription = Just "Show output from the latest test suite runs."
            , optTitle = Just "View test results"
            , optFieldDescriptions =
                [ waitDesc
                ,
                    ( "testFilter"
                    , "Whether to show all test results, or only the test results that failed. Valid options are 'All' and 'FailedOnly'. Defaults to 'All' if not set."
                    )
                ,
                    ( "fields"
                    , show
                        $ mconcat
                        $ Doc.punctuate
                            Doc.hardline
                            [ "Comma-separated list of fields to include in the result."
                            , "Available fields:"
                            , Doc.indent 4 (Doc.vsep $ FieldMask.Schema.render Test.SuiteView.Schema.schema)
                            , "Select nested fields with parentheses,"
                            , "e.g. --fields 'name,cases(description,failure)'."
                            , "Default fields, when unspecified, are as follows:"
                            , Doc.pretty $ FieldMask.render Test.SuiteView.Schema.defaultFields
                            ]
                    )
                ,
                    ( "suiteNames"
                    , "Test suites to focus on. In the form '<package>:<kind>:<component-name>'. E.g. 'tricorder:test:tricorder-test'"
                    )
                , projectRootDesc
                ]
            }
        )
    ,
        ( "Source"
        , defaultDefinitionOptions
            { optDescription =
                Just
                    "Print the Haskell source of one or more project or installed modules. Prefer this over downloading tarballs."
            , optTitle = Just "Lookup source"
            , optFieldDescriptions =
                [ ("modules", "Module names to look up, e.g. Data.Map.Strict or Data.Map.Strict#insert.")
                , projectRootDesc
                ]
            }
        )
    ,
        ( "EvalComments"
        , defaultDefinitionOptions
            { optDescription = Just "Show eval comments and their evaluated results from the latest build."
            , optTitle = Just "View eval comments"
            , optFieldDescriptions =
                [ waitDesc
                , projectRootDesc
                ]
            }
        )
    ,
        ( "LogPath"
        , defaultDefinitionOptions
            { optDescription = Just "Print the path to the daemon's log file."
            , optTitle = Just "View log path"
            , optFieldDescriptions = [projectRootDesc]
            }
        )
    ,
        ( "LogContents"
        , defaultDefinitionOptions
            { optDescription = Just "Print the daemon's log output."
            , optTitle = Just "View log contents"
            , optFieldDescriptions = [projectRootDesc]
            }
        )
    ]
  where
    projectRootDesc =
        ( "projectRoot"
        , "Optional directory of the project wherein to run the Tricorder\
          \commands. Usually where the `cabal.project`, `.cabal` file or\
          \`package.yaml` lives. Defaults to the current working directory."
        )
    waitDesc =
        ( "wait"
        , "Block and wait until the current build cycle finishes to provide the most up-to-date result."
        )
    forceDesc = ("force", "Ignore pending queries instead of waiting for them to finish.")


-- | The @tricorder@ invocation for a tool call: the project directory to run
-- it in, and the subcommand plus flags to pass. Builds the shared 'CLI.Command'
-- and renders it via 'CLI.commandToArgs' so the flags stay in sync with
-- "Tricorder.CLI.Arguments" instead of being duplicated here.
toolCommand :: Tool -> (Maybe Text, Either Text [String])
toolCommand = \case
    StartDaemon (StartOptions {projectRoot}) ->
        ( projectRoot
        , Right $ Daemon.Command.toArgs Daemon.Command.Start
        )
    StopDaemon (StopOptions {force, projectRoot}) ->
        ( projectRoot
        , Right
            $ Daemon.Command.toArgs
            $ Daemon.Command.Stop
            $ toForce force
        )
    RestartDaemon (RestartOptions {force, projectRoot}) ->
        ( projectRoot
        , Right
            $ Daemon.Command.toArgs
            $ Daemon.Command.Restart
            $ toForce force
        )
    Status (StatusOptions {wait, verbose, expand, projectRoot}) ->
        ( projectRoot
        , Right
            $ Command.toArgs
            $ Command.Status
                Command.StatusOptions
                    { wait = toIfBuildIsPending wait
                    , format = JsonOutput
                    , verbosity = toVerbosity verbose
                    , expand
                    , ifDaemonIsStopped = IfDaemonIsStopped.StartDaemon
                    }
        )
    TestSuites opts ->
        ( opts.projectRoot
        , do
            fields <- traverse FieldMask.Args.parse opts.fields
            Right
                $ Command.toArgs
                $ Command.Test
                $ Test.Suites
                $ Test.SuitesOptions
                    { testFilter = fromMaybe TestFilter.All opts.testFilter
                    , ifBuildIsPending = toIfBuildIsPending opts.wait
                    , suiteNames = fromMaybe [] opts.suiteNames
                    , format = OutputFormat.JsonOutput
                    , ifDaemonIsStopped = IfDaemonIsStopped.StartDaemon
                    , fields
                    }
        )
    Source (SourceOptions {modules, projectRoot}) ->
        ( projectRoot
        , Right
            $ Command.toArgs
            $ Command.Source
                Command.SourceOptions
                    { queries = parseSourceQuery <$> modules
                    , maxDepth = Nothing
                    , maxModules = Nothing
                    }
        )
    EvalComments (EvalCommentsOptions {wait, projectRoot}) ->
        ( projectRoot
        , Right
            $ Command.toArgs
            $ Command.EvalComments
                Command.EvalCommentsOptions
                    { wait = toIfBuildIsPending wait
                    , format = JsonOutput
                    , ifDaemonIsStopped = IfDaemonIsStopped.StartDaemon
                    }
        )
    LogPath (LogPathOptions {projectRoot}) ->
        ( projectRoot
        , Right
            $ Command.toArgs
            $ Command.Log Command.ShowLogPath
        )
    LogContents (LogContentsOptions {projectRoot}) ->
        ( projectRoot
        , Right
            $ Command.toArgs
            $ Command.Log Command.ShowLog
        )


toForce :: Maybe Bool -> Force
toForce = maybe Force.NoForce (\enabled -> if enabled then Force.Force else Force.NoForce)


toIfBuildIsPending :: Maybe Bool -> IfBuildIsPending
toIfBuildIsPending =
    maybe IfBuildIsPending.UseCurrent
        $ bool IfBuildIsPending.UseCurrent IfBuildIsPending.WaitForBuild


toVerbosity :: Maybe Bool -> Command.Verbosity
toVerbosity = maybe Command.Concise (\enabled -> if enabled then Command.Verbose else Command.Concise)


-- | Whether a tool's exit code reports a build/test outcome (errors present,
-- tests failed) rather than the CLI process itself failing. @tricorder
-- status@, @test-results@ and @eval-comments@ exit non-zero to signal what
-- they found, not that the command failed, so their output is trusted
-- regardless of exit code; every other command only exits non-zero on a
-- genuine execution failure.
reportsBuildOutcome :: Tool -> Bool
reportsBuildOutcome (Status _) = True
reportsBuildOutcome (TestSuites _) = True
reportsBuildOutcome (EvalComments _) = True
reportsBuildOutcome _ = False


-- | Spawning @tricorder@ can fail before it ever runs (e.g. the given
-- directory does not exist, or the binary is not on @PATH@): 'readProcess'
-- reports that as an 'IOException' rather than an 'ExitCode', and left
-- uncaught it would take the whole server down with it, not just this
-- request.
handleTool :: ClientContext -> Tool -> IO ToolResult
handleTool _ tool = case argsRes of
    Left err -> pure $ toolError $ "Tool failed with given input: " <> err
    Right args -> do
        mDir <- case passedDir of
            Just dir -> pure $ Right $ toString dir
            Nothing -> getProjectRoot
        case mDir of
            Left err ->
                pure $ toolError $ "Failed to run tricorder: " <> err
            Right directory -> do
                outcome <-
                    try @IOException
                        $ readProcess
                        $ setWorkingDir directory
                        $ proc "tricorder" args
                pure $ case outcome of
                    Left ex -> toolError $ "Failed to run tricorder: " <> show ex
                    Right (ExitSuccess, out, _) -> toolResult [ContentText (decodeUtf8 out)]
                    Right (ExitFailure _, out, _) | reportsBuildOutcome tool -> toolResult [ContentText (decodeUtf8 out)]
                    Right (ExitFailure _, out, err) ->
                        toolError $ "tricorder failed: " <> decodeUtf8 (if BSL.null err then out else err)
  where
    (passedDir, argsRes) = toolCommand tool


getProjectRoot :: IO (Either Text FilePath)
getProjectRoot = do
    claudeDir <- lookupEnv "CLAUDE_PROJECT_DIR"
    copilotDir <- lookupEnv "COPILOT_CWD"
    workingDir <- getWorkingDirectory
    let dir = fromMaybe workingDir $ claudeDir <|> copilotDir
    files <- listDirectory dir
    if not (any (\f -> ".cabal" `List.isSuffixOf` f || "cabal.project" `List.isPrefixOf` f) files)
        then
            pure $ Left $ "Could not find a `.cabal` file in the resolved project directory: " <> toText dir
        else
            pure $ Right dir
