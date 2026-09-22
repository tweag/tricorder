module Tricorder.CLI.Command
    ( Command (..)
    , EvalCommentsOptions (..)
    , Force (..)
    , LogMode (..)
    , OutputFormat (..)
    , StatusOptions (..)
    , TestOptions (..)
    , Verbosity (..)
    , commandToArgs
    )
where

import Tricorder.CLI.Command.WaitMode (WaitMode)
import Tricorder.SourceLookup.SourceQuery (SourceQuery, renderSourceQuery)

import Tricorder.CLI.Command.Test qualified as Test
import Tricorder.CLI.Command.WaitMode qualified as WaitMode


data Force = Force | NoForce


data OutputFormat
    = TextOutput
    | JsonOutput
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


data Command
    = Start
    | Stop Force
    | Status StatusOptions
    | -- | DEPRECATED: Use 'Test' instead.
      TestResults TestOptions
    | Test Test.Command
    | UI
    | Log LogMode
    | Source [SourceQuery]
    | Restart Force
    | EvalComments EvalCommentsOptions


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
        : WaitMode.toArgs wait
            <> formatArgs format
            <> verbosityArgs verbosity
            <> maybe [] (\n -> ["--expand", show n]) expand
commandToArgs (TestResults (TestOptions {failedOnly, wait})) =
    "test-results" : failedArgs failedOnly <> WaitMode.toArgs wait
commandToArgs (Test testCommand) = Test.commandToArgs testCommand
commandToArgs UI = ["ui"]
commandToArgs (Log ShowLogPath) = ["log", "--print-path"]
commandToArgs (Log ShowLog) = ["log"]
commandToArgs (Source queries) = "source" : map renderSourceQuery queries
commandToArgs (Restart doForce) = "restart" : forceArgs doForce
commandToArgs (EvalComments (EvalCommentsOptions {wait, format})) =
    "eval-comments" : WaitMode.toArgs wait <> formatArgs format


forceArgs :: Force -> [String]
forceArgs Force = ["--force"]
forceArgs NoForce = []


formatArgs :: OutputFormat -> [String]
formatArgs JsonOutput = ["--json"]
formatArgs TextOutput = []


verbosityArgs :: Verbosity -> [String]
verbosityArgs Verbose = ["--verbose"]
verbosityArgs Concise = []


failedArgs :: Bool -> [String]
failedArgs True = ["--failed"]
failedArgs False = []
