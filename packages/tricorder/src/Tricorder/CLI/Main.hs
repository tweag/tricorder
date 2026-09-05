module Tricorder.CLI.Main (main) where

import Atelier.Config (runConfig)
import Atelier.Effects.Arguments (runArgumentsIO)
import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Console (runConsole)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.Exit (runExit)
import Atelier.Effects.File (runFile)
import Atelier.Effects.FileSystem (runFileSystemIO)
import Atelier.Effects.Posix.Daemons (runDaemons)
import Atelier.Effects.Process (runProcessIO)
import Atelier.Effects.Timeout (runTimeout)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)

import Tricorder.CLI.Arguments (runArguments)
import Tricorder.CLI.UI.Brick (runBrick)
import Tricorder.CLI.UI.BrickChan (runBrickChan)
import Tricorder.Config (runLoadedConfig)
import Tricorder.Runtime (runLogPath, runPidFile, runProjectRoot, runRuntimeDir, runSocketPath)
import Tricorder.Socket.UnixSocket (runUnixSocketIO)

import Tricorder.CLI.App qualified as App
import Tricorder.CLI.UI.Keys qualified as Keys


main :: IO ()
main =
    runEff
        . runTimeout
        . runConcurrent
        . runConc
        . runBrickChan
        . runBrick
        . runConsole
        . runExit
        . runClock
        . runDelay
        . runFile
        . runFileSystemIO
        . runProjectRoot
        . runRuntimeDir
        . runPidFile
        . runSocketPath
        . runLogPath
        . runLoadedConfig
        . runConfig @"keybindings" @Keys.Config
        . runDaemons
        . runProcessIO
        . runArgumentsIO
        . runArguments
        . runUnixSocketIO
        $ App.run
