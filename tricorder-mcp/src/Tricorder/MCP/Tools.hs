module Tricorder.MCP.Tools
    ( Tool (..)
    , StopOptions (..)
    , RestartOptions (..)
    , StatusOptions (..)
    , TestResultsOptions (..)
    , SourceOptions (..)
    , EvalCommentsOptions (..)
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
import Tricorder.SourceLookup.SourceQuery (parseSourceQuery)

import Data.ByteString.Lazy qualified as BSL
import Data.List qualified as List
import Tricorder.CLI.Command qualified as CLI


data Tool
    = Start
    | Stop StopOptions
    | Restart RestartOptions
    | Status StatusOptions
    | TestResults TestResultsOptions
    | Source SourceOptions
    | EvalComments EvalCommentsOptions
    | LogPath
    | LogContents


newtype StopOptions = StopOptions {force :: Maybe Bool}


newtype RestartOptions = RestartOptions {force :: Maybe Bool}


data StatusOptions = StatusOptions
    { wait :: Maybe Bool
    , verbose :: Maybe Bool
    , expand :: Maybe Int
    }


data TestResultsOptions = TestResultsOptions
    { failed :: Maybe Bool
    , wait :: Maybe Bool
    }


newtype SourceOptions = SourceOptions {modules :: [Text]}


newtype EvalCommentsOptions = EvalCommentsOptions
    { wait :: Maybe Bool
    }


toolDescriptions :: [(String, DefinitionOptions)]
toolDescriptions =
    [
        ( "Start"
        , defaultDefinitionOptions
            { optDescription = Just "Start the tricorder daemon (no-op if already running)."
            , optTitle = Just "Start daemon"
            }
        )
    ,
        ( "Stop"
        , defaultDefinitionOptions
            { optDescription = Just "Stop the tricorder daemon."
            , optTitle = Just "Stop daemon"
            , optFieldDescriptions =
                [ ("force", "Ignore pending queries instead of waiting for them to finish.")
                ]
            }
        )
    ,
        ( "Restart"
        , defaultDefinitionOptions
            { optDescription = Just "Restart the tricorder daemon."
            , optTitle = Just "Restart daemon"
            , optFieldDescriptions =
                [ ("force", "Ignore pending queries instead of waiting for them to finish.")
                ]
            }
        )
    ,
        ( "Status"
        , defaultDefinitionOptions
            { optDescription = Just "Get the current GHCi build status: diagnostics, errors and warnings."
            , optTitle = Just "View built status"
            , optFieldDescriptions =
                [ ("wait", "Block until the current build cycle finishes before returning.")
                , ("verbose", "Include the full GHC message body under each diagnostic.")
                , ("expand", "Only show the summary line and full message body for diagnostic #N.")
                ]
            }
        )
    ,
        ( "TestResults"
        , defaultDefinitionOptions
            { optDescription = Just "Show output from the latest test suite runs."
            , optTitle = Just "View test results"
            , optFieldDescriptions =
                [ ("wait", "Block until the current build cycle finishes before returning.")
                , ("failed", "Only show output from failed test suites.")
                ]
            }
        )
    ,
        ( "Source"
        , defaultDefinitionOptions
            { optDescription =
                Just
                    "Print the Haskell source of one or more installed modules. Prefer this over downloading tarballs."
            , optTitle = Just "Lookup source"
            , optFieldDescriptions =
                [ ("modules", "Module names to look up, e.g. Data.Map.Strict or Data.Map.Strict#insert.")
                ]
            }
        )
    ,
        ( "EvalComments"
        , defaultDefinitionOptions
            { optDescription = Just "Show eval comments and their evaluated results from the latest build."
            , optTitle = Just "View eval comments"
            , optFieldDescriptions =
                [ ("wait", "Block until the current build cycle finishes before returning.")
                ]
            }
        )
    ,
        ( "LogPath"
        , defaultDefinitionOptions
            { optDescription = Just "Print the path to the daemon's log file."
            , optTitle = Just "View log path"
            }
        )
    ,
        ( "LogContents"
        , defaultDefinitionOptions
            { optDescription = Just "Print the daemon's log output."
            , optTitle = Just "View log contents"
            }
        )
    ]


-- | The @tricorder@ invocation for a tool call: the project directory to run
-- it in, and the subcommand plus flags to pass. Builds the shared 'CLI.Command'
-- and renders it via 'CLI.commandToArgs' so the flags stay in sync with
-- "Tricorder.CLI.Arguments" instead of being duplicated here.
toolCommand :: Tool -> [String]
toolCommand =
    CLI.commandToArgs . \case
        Start ->
            CLI.Start
        (Stop (StopOptions {force = doForce})) ->
            CLI.Stop $ toForce doForce
        (Restart (RestartOptions {force = doForce})) ->
            CLI.Restart $ toForce doForce
        (Status (StatusOptions {wait, verbose, expand})) ->
            CLI.Status
                CLI.StatusOptions
                    { wait = toWaitMode wait
                    , format = CLI.JsonOutput
                    , verbosity = toVerbosity verbose
                    , expand
                    }
        (TestResults (TestResultsOptions {failed, wait})) ->
            CLI.Test
                CLI.TestOptions
                    { failedOnly = fromMaybe False failed
                    , wait = toWaitMode wait
                    }
        (Source (SourceOptions {modules})) ->
            CLI.Source $ parseSourceQuery <$> modules
        (EvalComments (EvalCommentsOptions {wait})) ->
            CLI.EvalComments
                CLI.EvalCommentsOptions
                    { wait = toWaitMode wait
                    , format = CLI.JsonOutput
                    }
        LogPath ->
            CLI.Log CLI.ShowLogPath
        LogContents ->
            CLI.Log $ CLI.ShowLog CLI.NoFollow


toForce :: Maybe Bool -> CLI.Force
toForce = maybe CLI.NoForce (\enabled -> if enabled then CLI.Force else CLI.NoForce)


toWaitMode :: Maybe Bool -> CLI.WaitMode
toWaitMode = maybe CLI.ShowCurrent (\enabled -> if enabled then CLI.WaitForBuild else CLI.ShowCurrent)


toVerbosity :: Maybe Bool -> CLI.Verbosity
toVerbosity = maybe CLI.Concise (\enabled -> if enabled then CLI.Verbose else CLI.Concise)


-- | Whether a tool's exit code reports a build/test outcome (errors present,
-- tests failed) rather than the CLI process itself failing. @tricorder
-- status@, @test-results@ and @eval-comments@ exit non-zero to signal what
-- they found, not that the command failed, so their output is trusted
-- regardless of exit code; every other command only exits non-zero on a
-- genuine execution failure.
reportsBuildOutcome :: Tool -> Bool
reportsBuildOutcome (Status _) = True
reportsBuildOutcome (TestResults _) = True
reportsBuildOutcome (EvalComments _) = True
reportsBuildOutcome _ = False


-- | Spawning @tricorder@ can fail before it ever runs (e.g. the given
-- directory does not exist, or the binary is not on @PATH@): 'readProcess'
-- reports that as an 'IOException' rather than an 'ExitCode', and left
-- uncaught it would take the whole server down with it, not just this
-- request.
handleTool :: ClientContext -> Tool -> IO ToolResult
handleTool _ tool = do
    mDir <- projectRoot
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
    args = toolCommand tool


projectRoot :: IO (Either Text FilePath)
projectRoot = do
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
