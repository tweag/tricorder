module Tricorder.CLI.Arguments.FieldMask (parser) where

import Options.Applicative (Mod, OptionFields, Parser, eitherReader, long, metavar, option)
import Tricorder.CLI.Command.FieldMask (FieldMask, fieldsFlagName)

import Tricorder.CLI.FieldMask qualified as FieldMask


parser :: Mod OptionFields FieldMask -> Parser (Maybe FieldMask)
parser extraMods =
    optional
        $ option (eitherReader $ first toString . FieldMask.parse . toText)
        $ long fieldsFlagName
            <> metavar "FIELDS"
            <> extraMods
