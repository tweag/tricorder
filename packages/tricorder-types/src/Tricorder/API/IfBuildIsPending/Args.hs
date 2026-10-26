module Tricorder.API.IfBuildIsPending.Args (parser) where

import Options.Applicative (Parser, flag, help, long, short)

import Tricorder.API.IfBuildIsPending (IfBuildIsPending (..), waitForBuildFlagName)


parser :: Parser IfBuildIsPending
parser =
    flag ShowCurrent WaitForBuild
        $ long waitForBuildFlagName
            <> short 'w'
            <> help "Block until the current build cycle completes"
