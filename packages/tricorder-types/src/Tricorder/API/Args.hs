module Tricorder.API.Args
    ( parser
    )
where

import Options.Applicative
    ( Parser
    , ReadM
    , argument
    , auto
    , command
    , eitherReader
    , flag
    , help
    , hsubparser
    , info
    , long
    , metavar
    , option
    , progDesc
    , progDescDoc
    , readerError
    , short
    )

import Options.Applicative.Help.Pretty qualified as Doc

import Tricorder.API
    ( Command (..)
    , EvalCommentsOptions (..)
    , LogMode (..)
    , SourceOptions (..)
    , StatusOptions (..)
    , TestOptions (..)
    , Verbosity (..)
    )
import Tricorder.API.Force (Force)
import Tricorder.SourceLookup.ReexportLimits (ReexportLimits (..), defaultReexportLimits)
import Tricorder.SourceLookup.SourceQuery (SourceQuery, parseSourceQuery)

import Tricorder.API.Daemon.Args qualified as Daemon.Args
import Tricorder.API.Force qualified as Force
import Tricorder.API.OutputFormat.Args qualified as OutputFormat.Args
import Tricorder.API.Test.Args qualified as Test.Args
import Tricorder.API.WaitMode.Args qualified as WaitMode.Args


parser :: Parser Command
parser =
    hsubparser
        ( command "start" (info (pure Start) (progDesc "Start the daemon (no-op if already running)"))
            <> command "stop" (info stopParser (progDesc "Stop the daemon"))
            <> command "restart" (info restartParser (progDesc "Restart the daemon"))
            <> command
                "status"
                (info statusParser (progDesc "Print build diagnostics (--json for machine-readable output)"))
            <> command
                "test-results"
                ( info
                    testResultsParser
                    ( progDescDoc
                        $ Just
                        $ "Show output from the latest test run"
                            <> Doc.line
                            <> Doc.annotate Doc.bold "DEPRECATED: use the `test suites` subcommand"
                    )
                )
            <> command "test" (Test <$> Test.Args.parser)
            <> command "ui" (info (pure UI) (progDesc "Auto-refreshing terminal display"))
            <> command "log" (info logParser (progDesc "Show daemon log output"))
            <> command
                "source"
                (info sourceParser (progDesc "Print the Haskell source of one or more project or installed modules"))
            <> command
                "eval-comments"
                (info evalCommentsParser (progDesc "Show eval comments from the latest build"))
            <> command "daemon" (info (Daemon <$> Daemon.Args.parser) (progDesc "Daemon sub-commands"))
        )


logParser :: Parser Command
logParser =
    Log <$> pathFlag
  where
    pathFlag =
        flag
            ShowLog
            ShowLogPath
            ( long "print-path"
                <> help "Print the path to the log file instead of its contents"
            )


statusParser :: Parser Command
statusParser =
    Status
        <$> ( StatusOptions
                <$> WaitMode.Args.parser
                <*> OutputFormat.Args.parser
                <*> flag
                    Concise
                    Verbose
                    ( long "verbose"
                        <> short 'v'
                        <> help "Print full GHC message body under each diagnostic"
                    )
                <*> optional
                    ( option
                        auto
                        ( long "expand"
                            <> metavar "N"
                            <> help "Print full GHC message body for diagnostic #N"
                        )
                    )
            )


testResultsParser :: Parser Command
testResultsParser =
    TestResults
        <$> ( TestOptions
                <$> flag
                    False
                    True
                    ( long "failed"
                        <> help "Only show output from failed test suites"
                    )
                <*> WaitMode.Args.parser
            )


sourceParser :: Parser Command
sourceParser =
    Source
        <$> ( SourceOptions
                <$> some
                    ( argument
                        queryReader
                        (metavar "Module[#function]" <> help "Module or Module#function")
                    )
                <*> optional
                    ( option
                        nonNegative
                        ( long "max-depth"
                            <> metavar "N"
                            <> help
                                ( "Follow at most N re-export hops when a symbol is not defined in the queried module (default: "
                                    <> show defaultReexportLimits.maxDepth
                                    <> ")"
                                )
                        )
                    )
                <*> optional
                    ( option
                        nonNegative
                        ( long "max-modules"
                            <> metavar "N"
                            <> help
                                ( "Read at most N modules while following re-exports (default: "
                                    <> show defaultReexportLimits.maxModules
                                    <> ")"
                                )
                        )
                    )
            )
  where
    nonNegative = do
        n <- auto
        if n < 0 then readerError "must be a non-negative integer" else pure n


stopParser :: Parser Command
stopParser =
    Stop <$> forceParser "Ignore waiting queries when stopping the daemon"


restartParser :: Parser Command
restartParser =
    Restart <$> forceParser "Ignore watiting queries when restarting the daemon"


forceParser :: String -> Parser Force
forceParser helpText = flag Force.NoForce Force.Force $ long "force" <> help helpText


evalCommentsParser :: Parser Command
evalCommentsParser =
    EvalComments
        <$> ( EvalCommentsOptions
                <$> WaitMode.Args.parser
                <*> OutputFormat.Args.parser
            )


queryReader :: ReadM SourceQuery
queryReader = eitherReader $ Right . parseSourceQuery . toText
