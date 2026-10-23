module Tricorder.API.Args.Deprecated (parser) where

import Options.Applicative
    ( Parser
    , command
    , commandGroup
    , hidden
    , hsubparser
    , info
    , progDescDoc
    )

import Options.Applicative.Help qualified as Doc

import Tricorder.API.Command (Command (..))

import Tricorder.API.Daemon.Args qualified as Daemon.Args
import Tricorder.API.Daemon.Command qualified as Daemon.Command


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
            ]
