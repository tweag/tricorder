module Tricorder.CLI.Arguments.WaitMode (parser) where

import Options.Applicative (Parser, flag, help, long, short)
import Tricorder.CLI.Command.WaitMode (WaitMode (..), waitForBuildFlagName)


parser :: Parser WaitMode
parser =
    flag ShowCurrent WaitForBuild
        $ long waitForBuildFlagName
            <> short 'w'
            <> help "Block until the current build cycle completes"
