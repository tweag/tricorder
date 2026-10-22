module Tricorder.API.Args.Deprecated (parser) where

import Options.Applicative
    ( Parser
    , command
    , commandGroup
    , flag
    , help
    , hidden
    , hsubparser
    , info
    , long
    , progDescDoc
    )

import Options.Applicative.Help qualified as Doc

import Tricorder.API.Command (Command (..), TestOptions (..))

import Tricorder.API.Daemon.Args qualified as Daemon.Args
import Tricorder.API.Daemon.Command qualified as Daemon.Command
import Tricorder.API.WaitMode.Args qualified as WaitMode.Args


parser :: Parser Command
parser =
    hsubparser
        $ mconcat
            [ hidden
            , commandGroup "Deprecated:"
            , command
                "start"
                $ info (pure $ Daemon Daemon.Command.Start)
                $ progDescDoc
                $ Just
                $ "Start the daemon (no-op if already running.)"
                    <> Doc.line
                    <> "Use 'daemon start' instead."
            , command
                "stop"
                $ info (Daemon <$> Daemon.Args.stopParser)
                $ progDescDoc
                $ Just
                $ "Stop the daemon."
                    <> Doc.line
                    <> "Use 'daemon stop' instead."
            , command
                "restart"
                $ info (Daemon <$> Daemon.Args.restartParser)
                $ progDescDoc
                $ Just
                $ "Restart the daemon."
                    <> Doc.line
                    <> "Use 'daemon restart' instead."
            , command "test-results"
                $ info testResultsParser
                $ progDescDoc
                $ Just
                $ "Show output from the latest test run"
                    <> Doc.line
                    <> "Use `test suites` instead."
            ]


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
