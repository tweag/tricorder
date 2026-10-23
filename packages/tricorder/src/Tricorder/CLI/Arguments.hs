module Tricorder.CLI.Arguments (reader) where

import Atelier.Effects.Arguments (Arguments)
import Effectful.Reader.Static (Reader)
import Options.Applicative (Parser, ParserInfo)
import Tricorder.API.Command (Command)

import Atelier.Effects.Arguments qualified as Args
import Effectful.Reader.Static qualified as Reader
import Options.Applicative qualified as Opt
import Tricorder.API.Command.Args qualified as Command.Args

import Tricorder.Version qualified as Version


reader :: (Arguments :> es) => Eff (Reader Command : es) a -> Eff es a
reader eff = do
    args <- Args.execParser opts
    Reader.runReader args eff


opts :: ParserInfo Command
opts =
    Opt.info (Command.Args.parser <**> versionOption <**> Opt.helper)
        $ Opt.fullDesc
            <> Opt.progDesc "tricorder — daemon-based GHCi build status"
            <> Opt.header "tricorder — robust GHCi daemon with structured querying"


versionOption :: Parser (a -> a)
versionOption =
    Opt.infoOption (toString Version.gitHash) (Opt.long "version" <> Opt.help "Show version and exit")
