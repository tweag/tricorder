module Tricorder.MCP.Tools
    ( Tool (..)
    , StartOptions (..)
    , StopOptions (..)
    , RestartOptions (..)
    , StatusOptions (..)
    , TestResultsOptions (..)
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
import System.Exit (ExitCode (..))
import System.Process.Typed (proc, readProcess, setWorkingDir)

import Data.ByteString.Lazy qualified as BSL


data Tool
    = Start StartOptions
    | Stop StopOptions
    | Restart RestartOptions
    | Status StatusOptions
    | TestResults TestResultsOptions
    | Source SourceOptions
    | EvalComments EvalCommentsOptions
    | LogPath LogPathOptions
    | LogContents LogContentsOptions


newtype StartOptions = StartOptions {directory :: Text}


data StopOptions = StopOptions
    { directory :: Text
    , force :: Maybe Bool
    }


data RestartOptions = RestartOptions
    { directory :: Text
    , force :: Maybe Bool
    }


data StatusOptions = StatusOptions
    { directory :: Text
    , wait :: Maybe Bool
    , json :: Maybe Bool
    , verbose :: Maybe Bool
    , expand :: Maybe Int
    }


data TestResultsOptions = TestResultsOptions
    { directory :: Text
    , failed :: Maybe Bool
    , wait :: Maybe Bool
    }


data SourceOptions = SourceOptions
    { directory :: Text
    , modules :: [Text]
    }


data EvalCommentsOptions = EvalCommentsOptions
    { directory :: Text
    , wait :: Maybe Bool
    , json :: Maybe Bool
    }


newtype LogPathOptions = LogPathOptions {directory :: Text}


newtype LogContentsOptions = LogContentsOptions {directory :: Text}


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
    ,
        ( "directory"
        , "Absolute path to the project's working directory (the tricorder daemon is scoped per-directory)"
        )
    , ("force", "Ignore pending queries instead of waiting for them to finish")
    , ("wait", "Block until the current build cycle finishes before returning")
    , ("json", "Return machine-readable JSON instead of the default text output")
    , ("verbose", "Include the full GHC message body under each diagnostic")
    , ("expand", "Only show the summary line and full message body for diagnostic #N")
    , ("failed", "Only show output from failed test suites")
    , ("modules", "Module names to look up, e.g. Data.Map.Strict or Data.Map.Strict#insert")
    ]


-- | The @tricorder@ invocation for a tool call: the project directory to run
-- it in, and the subcommand plus flags to pass.
toolCommand :: Tool -> (Text, [String])
toolCommand (Start (StartOptions {directory})) = (directory, ["start"])
toolCommand (Stop (StopOptions {directory, force = doForce})) =
    (directory, "stop" : flagArg "--force" doForce)
toolCommand (Restart (RestartOptions {directory, force = doForce})) =
    (directory, "restart" : flagArg "--force" doForce)
toolCommand (Status (StatusOptions {directory, wait, json, verbose, expand})) =
    ( directory
    , "status"
        : flagArg "--wait" wait
            <> flagArg "--json" json
            <> flagArg "--verbose" verbose
            <> maybe [] (\n -> ["--expand", show n]) expand
    )
toolCommand (TestResults (TestResultsOptions {directory, failed, wait})) =
    (directory, "test-results" : flagArg "--failed" failed <> flagArg "--wait" wait)
toolCommand (Source (SourceOptions {directory, modules})) =
    (directory, "source" : map toString modules)
toolCommand (EvalComments (EvalCommentsOptions {directory, wait, json})) =
    (directory, "eval-comments" : flagArg "--wait" wait <> flagArg "--json" json)
toolCommand (LogPath (LogPathOptions {directory})) = (directory, ["log", "--print-path"])
toolCommand (LogContents (LogContentsOptions {directory})) = (directory, ["log"])


flagArg :: String -> Maybe Bool -> [String]
flagArg flag = maybe [] (\enabled -> [flag | enabled])


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
    let (directory, args) = toolCommand tool
    outcome <-
        try @IOException $ readProcess $ setWorkingDir (toString directory) $ proc "tricorder" args
    pure $ case outcome of
        Left ex -> toolError $ "Failed to run tricorder: " <> show ex
        Right (ExitSuccess, out, _) -> toolResult [ContentText (decodeUtf8 out)]
        Right (ExitFailure _, out, _) | reportsBuildOutcome tool -> toolResult [ContentText (decodeUtf8 out)]
        Right (ExitFailure _, out, err) ->
            toolError $ "tricorder failed: " <> decodeUtf8 (if BSL.null err then out else err)
