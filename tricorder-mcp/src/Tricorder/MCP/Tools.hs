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
    , json :: Maybe Bool
    , verbose :: Maybe Bool
    , expand :: Maybe Int
    }


data TestResultsOptions = TestResultsOptions
    { failed :: Maybe Bool
    , wait :: Maybe Bool
    }


newtype SourceOptions = SourceOptions {modules :: [Text]}


data EvalCommentsOptions = EvalCommentsOptions
    { wait :: Maybe Bool
    , json :: Maybe Bool
    }


toolDescriptions :: [(String, String)]
toolDescriptions =
    [ ("Start", "Start the tricorder daemon for a project (no-op if already running)")
    , ("Stop", "Stop the tricorder daemon for a project")
    , ("Restart", "Restart the tricorder daemon for a project")
    , ("Status", "Get the current GHCi build status: diagnostics, errors and warnings")
    , ("TestResults", "Show output from the latest test run")
    , ("Source", "Print the Haskell source of one or more installed modules")
    , ("EvalComments", "Show eval comments and their evaluated results from the latest build")
    , ("LogPath", "Print the path to the daemon's log file")
    , ("LogContents", "Print the daemon's log output")
    , ("force", "Ignore pending queries instead of waiting for them to finish")
    , ("wait", "Block until the current build cycle finishes before returning")
    , ("json", "Return machine-readable JSON instead of the default text output")
    , ("verbose", "Include the full GHC message body under each diagnostic")
    , ("expand", "Only show the summary line and full message body for diagnostic #N")
    , ("failed", "Only show output from failed test suites")
    , ("modules", "Module names to look up, e.g. Data.Map.Strict or Data.Map.Strict#insert")
    ]


-- | The @tricorder@ invocation for a tool call: the project directory to run
-- it in, and the subcommand plus flags to pass. Builds the shared 'CLI.Command'
-- and renders it via 'CLI.commandToArgs' so the flags stay in sync with
-- "Tricorder.CLI.Arguments" instead of being duplicated here.
toolCommand :: Tool -> [String]
toolCommand = \case
    Start ->
        CLI.commandToArgs CLI.Start
    (Stop (StopOptions {force = doForce})) ->
        CLI.commandToArgs (CLI.Stop (toForce doForce))
    (Restart (RestartOptions {force = doForce})) ->
        CLI.commandToArgs (CLI.Restart (toForce doForce))
    (Status (StatusOptions {wait, json, verbose, expand})) ->
        CLI.commandToArgs
            $ CLI.Status
                CLI.StatusOptions
                    { wait = toWaitMode wait
                    , format = toFormat json
                    , verbosity = toVerbosity verbose
                    , expand
                    }
    (TestResults (TestResultsOptions {failed, wait})) ->
        CLI.commandToArgs
            $ CLI.Test CLI.TestOptions {failedOnly = fromMaybe False failed, wait = toWaitMode wait}
    (Source (SourceOptions {modules})) ->
        CLI.commandToArgs (CLI.Source (map parseSourceQuery modules))
    (EvalComments (EvalCommentsOptions {wait, json})) ->
        CLI.commandToArgs
            $ CLI.EvalComments CLI.EvalCommentsOptions {wait = toWaitMode wait, format = toFormat json}
    LogPath ->
        CLI.commandToArgs (CLI.Log CLI.ShowLogPath)
    LogContents ->
        CLI.commandToArgs (CLI.Log (CLI.ShowLog CLI.NoFollow))


toForce :: Maybe Bool -> CLI.Force
toForce = maybe CLI.NoForce (\enabled -> if enabled then CLI.Force else CLI.NoForce)


toWaitMode :: Maybe Bool -> CLI.WaitMode
toWaitMode = maybe CLI.ShowCurrent (\enabled -> if enabled then CLI.WaitForBuild else CLI.ShowCurrent)


toFormat :: Maybe Bool -> CLI.OutputFormat
toFormat = maybe CLI.TextOutput (\enabled -> if enabled then CLI.JsonOutput else CLI.TextOutput)


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
