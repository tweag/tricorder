module Tricorder.Daemon.Arguments (run) where

import Atelier.Effects.Arguments (Arguments)
import Options.Applicative (Parser, ParserInfo)

import Atelier.Effects.Arguments qualified as Args
import Options.Applicative qualified as Opt

import Tricorder.Version qualified as Version


run :: (Arguments :> es) => Eff es a -> Eff es a
run eff = do
    () <- Args.execParser opts
    eff


opts :: ParserInfo ()
opts =
    Opt.info (pure () <**> versionOption <**> Opt.helper)
        $ Opt.fullDesc
            <> Opt.progDesc "tricorder-daemon — daemon for the Tricorder CLI"


versionOption :: Parser (a -> a)
versionOption =
    Opt.infoOption (toString Version.gitHash) (Opt.long "version" <> Opt.help "Show version and exit")
