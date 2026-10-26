module Tricorder.API.Command
    ( Command (..)
    , EvalCommentsOptions (..)
    , LogMode (..)
    , SourceOptions (..)
    , StatusOptions (..)
    , Verbosity (..)
    , toArgs
    )
where

import Tricorder.API.IfBuildIsPending (IfBuildIsPending)
import Tricorder.API.IfDaemonIsStopped (IfDaemonIsStopped)
import Tricorder.API.OutputFormat (OutputFormat (..))
import Tricorder.SourceLookup.SourceQuery (SourceQuery, renderSourceQuery)

import Tricorder.API.Daemon.Command qualified as Daemon (Command)
import Tricorder.API.Daemon.Command qualified as Daemon.Command
import Tricorder.API.IfBuildIsPending qualified as IfBuildIsPending
import Tricorder.API.OutputFormat qualified as OutputFormat
import Tricorder.API.Test qualified as Test


data Verbosity
    = Concise
    | Verbose
    deriving stock (Eq)


data LogMode = ShowLog | ShowLogPath


data StatusOptions = StatusOptions
    { wait :: IfBuildIsPending
    , format :: OutputFormat
    , verbosity :: Verbosity
    , expand :: Maybe Int
    , ifDaemonIsStopped :: IfDaemonIsStopped
    }


data EvalCommentsOptions = EvalCommentsOptions
    { wait :: IfBuildIsPending
    , format :: OutputFormat
    , ifDaemonIsStopped :: IfDaemonIsStopped
    }


data SourceOptions = SourceOptions
    { queries :: [SourceQuery]
    , maxDepth :: Maybe Word
    -- ^ Most re-export hops to follow for a symbol query; 'Nothing' is the default.
    , maxModules :: Maybe Word
    -- ^ Most modules to read while following re-exports; 'Nothing' is the default.
    }


data Command
    = Status StatusOptions
    | Test Test.Command
    | UI
    | Log LogMode
    | Source SourceOptions
    | EvalComments EvalCommentsOptions
    | Daemon Daemon.Command


-- | Render a 'Command' to the argument list the @tricorder@ CLI expects
-- (subcommand name followed by flags) — the inverse of the parser in
-- "Tricorder.CLI.Arguments". Kept next to 'Command' so a new field or
-- constructor forces both the parser and this renderer to be updated
-- together; this is what @tricorder-mcp@ uses to invoke @tricorder@ without
-- duplicating flag names.
toArgs :: Command -> [String]
toArgs = \case
    Status (StatusOptions {wait, format, verbosity, expand}) ->
        "status"
            : IfBuildIsPending.toArgs wait
                <> OutputFormat.toArgs format
                <> verbosityArgs verbosity
                <> maybe [] (\n -> ["--expand", show n]) expand
    Test testCommand -> "test" : Test.toArgs testCommand
    UI -> ["ui"]
    Log ShowLogPath -> ["log", "--print-path"]
    Log ShowLog -> ["log"]
    Source (SourceOptions {queries, maxDepth, maxModules}) ->
        "source"
            : maybe [] (\n -> ["--max-depth", show n]) maxDepth
                <> maybe [] (\n -> ["--max-modules", show n]) maxModules
                <> map renderSourceQuery queries
    EvalComments (EvalCommentsOptions {wait, format}) ->
        "eval-comments" : IfBuildIsPending.toArgs wait <> OutputFormat.toArgs format
    Daemon daemonCommand -> "daemon" : Daemon.Command.toArgs daemonCommand


verbosityArgs :: Verbosity -> [String]
verbosityArgs Verbose = ["--verbose"]
verbosityArgs Concise = []
