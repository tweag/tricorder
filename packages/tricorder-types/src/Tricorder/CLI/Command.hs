module Tricorder.CLI.Command
    ( Command (..)
    , EvalCommentsOptions (..)
    , Force (..)
    , LogMode (..)
    , SourceOptions (..)
    , StatusOptions (..)
    , TestOptions (..)
    , Verbosity (..)
    , WaitMode (..)
    , commandToArgs
    )
where

import Tricorder.CLI.Command.Daemon (DaemonCommand)
import Tricorder.CLI.Command.OutputFormat (OutputFormat (..))
import Tricorder.SourceLookup.SourceQuery (SourceQuery, renderSourceQuery)

import Tricorder.CLI.Command.Daemon qualified as Daemon
import Tricorder.CLI.Command.OutputFormat qualified as OutputFormat


data Force = Force | NoForce


data WaitMode
    = ShowCurrent
    | WaitForBuild
    deriving stock (Eq)


data Verbosity
    = Concise
    | Verbose
    deriving stock (Eq)


data LogMode = ShowLog | ShowLogPath


data StatusOptions = StatusOptions
    { wait :: WaitMode
    , format :: OutputFormat
    , verbosity :: Verbosity
    , expand :: Maybe Int
    }


data TestOptions = TestOptions
    { failedOnly :: Bool
    , wait :: WaitMode
    }


data EvalCommentsOptions = EvalCommentsOptions
    { wait :: WaitMode
    , format :: OutputFormat
    }


data SourceOptions = SourceOptions
    { queries :: [SourceQuery]
    , maxDepth :: Maybe Word
    -- ^ Most re-export hops to follow for a symbol query; 'Nothing' is the default.
    , maxModules :: Maybe Word
    -- ^ Most modules to read while following re-exports; 'Nothing' is the default.
    }


data Command
    = Start
    | Stop Force
    | Status StatusOptions
    | Test TestOptions
    | UI
    | Log LogMode
    | Source SourceOptions
    | Restart Force
    | EvalComments EvalCommentsOptions
    | Daemon DaemonCommand


-- | Render a 'Command' to the argument list the @tricorder@ CLI expects
-- (subcommand name followed by flags) — the inverse of the parser in
-- "Tricorder.CLI.Arguments". Kept next to 'Command' so a new field or
-- constructor forces both the parser and this renderer to be updated
-- together; this is what @tricorder-mcp@ uses to invoke @tricorder@ without
-- duplicating flag names.
commandToArgs :: Command -> [String]
commandToArgs Start = ["start"]
commandToArgs (Stop doForce) = "stop" : forceArgs doForce
commandToArgs (Status (StatusOptions {wait, format, verbosity, expand})) =
    "status"
        : waitArgs wait
            <> OutputFormat.toArgs format
            <> verbosityArgs verbosity
            <> maybe [] (\n -> ["--expand", show n]) expand
commandToArgs (Test (TestOptions {failedOnly, wait})) =
    "test-results" : failedArgs failedOnly <> waitArgs wait
commandToArgs UI = ["ui"]
commandToArgs (Log ShowLogPath) = ["log", "--print-path"]
commandToArgs (Log ShowLog) = ["log"]
commandToArgs (Source (SourceOptions {queries, maxDepth, maxModules})) =
    "source"
        : maybe [] (\n -> ["--max-depth", show n]) maxDepth
            <> maybe [] (\n -> ["--max-modules", show n]) maxModules
            <> map renderSourceQuery queries
commandToArgs (Restart doForce) = "restart" : forceArgs doForce
commandToArgs (EvalComments (EvalCommentsOptions {wait, format})) =
    "eval-comments" : waitArgs wait <> OutputFormat.toArgs format
commandToArgs (Daemon daemonCommand) = "daemon" : Daemon.toArgs daemonCommand


forceArgs :: Force -> [String]
forceArgs Force = ["--force"]
forceArgs NoForce = []


waitArgs :: WaitMode -> [String]
waitArgs WaitForBuild = ["--wait"]
waitArgs ShowCurrent = []


verbosityArgs :: Verbosity -> [String]
verbosityArgs Verbose = ["--verbose"]
verbosityArgs Concise = []


failedArgs :: Bool -> [String]
failedArgs True = ["--failed"]
failedArgs False = []
