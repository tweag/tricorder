module Tricorder.API.Command.Args
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
    , readerError
    , short
    )

import Tricorder.API.Command
    ( Command (..)
    , EvalCommentsOptions (..)
    , LogMode (..)
    , SourceOptions (..)
    , StatusOptions (..)
    , Verbosity (..)
    )
import Tricorder.SourceLookup.ReexportLimits (ReexportLimits (..), defaultReexportLimits)
import Tricorder.SourceLookup.SourceQuery (SourceQuery, parseSourceQuery)

import Tricorder.API.Args.Deprecated qualified as Args.Deprecated
import Tricorder.API.Daemon.Args qualified as Daemon.Args
import Tricorder.API.IfDaemonIsStopped.Args qualified as IfDaemonIsStopped.Args
import Tricorder.API.OutputFormat.Args qualified as OutputFormat.Args
import Tricorder.API.Test.Args qualified as Test.Args
import Tricorder.API.WaitMode.Args qualified as WaitMode.Args


parser :: Parser Command
parser =
    asum
        [ hsubparser
            $ mconcat
                [ command "ui"
                    $ info (pure UI)
                    $ progDesc "Auto-refreshing terminal display."
                , command "status"
                    $ info statusParser
                    $ progDesc "Print build diagnostics (--json for machine-readable output.)"
                , command "test" $ Test <$> Test.Args.parser
                , command "source"
                    $ info sourceParser
                    $ progDesc "Print the Haskell source of one or more project or installed modules."
                , command "eval-comments"
                    $ info evalCommentsParser
                    $ progDesc "Show eval comments from the latest build."
                , command "daemon" $ Daemon <$> Daemon.Args.parser
                , command "log"
                    $ info logParser
                    $ progDesc "Show daemon log output."
                ]
        , Args.Deprecated.parser
        ]


logParser :: Parser Command
logParser =
    Log <$> pathFlag
  where
    pathFlag =
        flag
            ShowLog
            ShowLogPath
            $ long "print-path"
                <> help "Print the path to the log file instead of its contents"


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
                        <> help "Print full GHC message body under each diagnostic, and full test suite error messages"
                    )
                <*> optional
                    ( option
                        auto
                        ( long "expand"
                            <> metavar "N"
                            <> help "Print full GHC message body for diagnostic #N"
                        )
                    )
                <*> IfDaemonIsStopped.Args.parser
            )


sourceParser :: Parser Command
sourceParser =
    Source
        <$> ( SourceOptions
                <$> some
                    ( argument
                        queryReader
                        $ metavar "Module[#function]"
                            <> help "Module or Module#function"
                    )
                <*> optional
                    ( option
                        nonNegative
                        $ long "max-depth"
                            <> metavar "N"
                            <> help
                                ( "Follow at most N re-export hops when a symbol is not defined in the queried module (default: "
                                    <> show defaultReexportLimits.maxDepth
                                    <> ")"
                                )
                    )
                <*> optional
                    ( option
                        nonNegative
                        $ long "max-modules"
                            <> metavar "N"
                            <> help
                                ( "Read at most N modules while following re-exports (default: "
                                    <> show defaultReexportLimits.maxModules
                                    <> ")"
                                )
                    )
            )
  where
    nonNegative = do
        n <- auto
        if n < 0 then readerError "must be a non-negative integer" else pure n


evalCommentsParser :: Parser Command
evalCommentsParser =
    EvalComments
        <$> ( EvalCommentsOptions
                <$> WaitMode.Args.parser
                <*> OutputFormat.Args.parser
                <*> IfDaemonIsStopped.Args.parser
            )


queryReader :: ReadM SourceQuery
queryReader = eitherReader $ Right . parseSourceQuery . toText
