module Tricorder.CLI.Arguments (runArguments, parseArguments) where

import Atelier.Effects.Arguments (Arguments)
import Effectful.Reader.Static (Reader)
import Options.Applicative (Parser, ParserInfo)
import Tricorder.API (Command)

import Atelier.Effects.Arguments qualified as Args
import Effectful.Reader.Static qualified as Reader
import Options.Applicative qualified as Opt
import Tricorder.API qualified as API
import Tricorder.API.Args qualified as API.Args

import Tricorder.Version qualified as Version


runArguments :: (Arguments :> es) => Eff (Reader API.Command : es) a -> Eff es a
runArguments eff = do
    args <- parseArguments
    Reader.runReader args eff


parseArguments :: (Arguments :> es) => Eff es Command
parseArguments = Args.execParser opts


opts :: ParserInfo Command
opts =
    Opt.info (API.Args.parser <**> versionOption <**> Opt.helper)
        $ Opt.fullDesc
            <> Opt.progDesc "tricorder — daemon-based GHCi build status"
            <> Opt.header "tricorder — robust GHCi daemon with structured querying"


versionOption :: Parser (a -> a)
versionOption =
    Opt.infoOption (toString Version.gitHash) (Opt.long "version" <> Opt.help "Show version and exit")
