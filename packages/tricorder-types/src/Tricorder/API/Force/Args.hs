module Tricorder.API.Force.Args
    ( parser
    , forceFlagName
    , forceShortFlagName
    )
where

import Options.Applicative (Parser, flag, help, long, short)

import Tricorder.API.Force (Force)

import Tricorder.API.Force qualified as Force


parser :: String -> Parser Force
parser helpText =
    flag Force.NoForce Force.Force
        $ short forceShortFlagName <> long forceFlagName <> help helpText


forceFlagName :: String
forceFlagName = "force"


forceShortFlagName :: Char
forceShortFlagName = 'f'
