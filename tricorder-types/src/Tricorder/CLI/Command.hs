module Tricorder.CLI.Command
    ( Command (..)
    , EvalCommentsOptions (..)
    , FollowMode (..)
    , Force (..)
    , LogMode (..)
    , OutputFormat (..)
    , StatusOptions (..)
    , TestOptions (..)
    , Verbosity (..)
    , WaitMode (..)
    , commandToArgs
    )
where

import Tricorder.SourceLookup.SourceQuery (SourceQuery, renderSourceQuery)


data Force = Force | NoForce


data WaitMode
    = ShowCurrent
    | WaitForBuild
    deriving stock (Eq)


data OutputFormat
    = TextOutput
    | JsonOutput
    deriving stock (Eq)


data Verbosity
    = Concise
    | Verbose
    deriving stock (Eq)


data FollowMode
    = NoFollow
    | Follow
    deriving stock (Eq)


data LogMode
    = ShowLog FollowMode
    | ShowLogPath


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
    | Test TestOptions
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
        : waitArgs wait
            <> formatArgs format
            <> verbosityArgs verbosity
            <> maybe [] (\n -> ["--expand", show n]) expand
commandToArgs (Test (TestOptions {failedOnly, wait})) =
    "test-results" : failedArgs failedOnly <> waitArgs wait
commandToArgs UI = ["ui"]
commandToArgs (Log ShowLogPath) = ["log", "--print-path"]
commandToArgs (Log (ShowLog follow)) = "log" : followArgs follow
commandToArgs (Source queries) = "source" : map renderSourceQuery queries
commandToArgs (Restart doForce) = "restart" : forceArgs doForce
commandToArgs (EvalComments (EvalCommentsOptions {wait, format})) =
    "eval-comments" : waitArgs wait <> formatArgs format


forceArgs :: Force -> [String]
forceArgs Force = ["--force"]
forceArgs NoForce = []


waitArgs :: WaitMode -> [String]
waitArgs WaitForBuild = ["--wait"]
waitArgs ShowCurrent = []


formatArgs :: OutputFormat -> [String]
formatArgs JsonOutput = ["--json"]
formatArgs TextOutput = []


verbosityArgs :: Verbosity -> [String]
verbosityArgs Verbose = ["--verbose"]
verbosityArgs Concise = []


followArgs :: FollowMode -> [String]
followArgs Follow = ["--follow"]
followArgs NoFollow = []


failedArgs :: Bool -> [String]
failedArgs True = ["--failed"]
failedArgs False = []
