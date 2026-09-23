module Tricorder.CLI.Main (main) where

import Atelier.Config (runConfig)
import Atelier.Effects.Arguments (runArgumentsIO)
import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Console (runConsole)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.Env (runEnv)
import Atelier.Effects.Exit (runExit)
import Atelier.Effects.File (runFile)
import Atelier.Effects.FileSystem (runFileSystemIO)
import Atelier.Effects.Input (input, runInputEff)
import Atelier.Effects.Log (runLogNoOp)
import Atelier.Effects.Posix.Daemons (runDaemons)
import Atelier.Effects.Process (runProcessIO)
import Atelier.Effects.Timeout (runTimeout)
import Atelier.Signal (installTerminationHandler)
import Data.Default (def)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Reader.Static (runReader)
import Tricorder.SourceLookup.SourceQuery (ModuleName, SourceQuery)

import Atelier.Effects.Cache qualified as Cache
import Atelier.Effects.Cache qualified as CacheConfig
import Atelier.Effects.FileSystem.Glob qualified as Glob

import Tricorder.CLI.Arguments (runArguments)
import Tricorder.CLI.UI.Brick (runBrick)
import Tricorder.CLI.UI.BrickChan (runBrickChan)
import Tricorder.Config (inputLoadedConfig, runLoadedConfig)
import Tricorder.Runtime (runLogPath, runPidFile, runProjectRoot, runRuntimeDir, runSocketPath)
import Tricorder.Session (Session (..), loadSession)
import Tricorder.Session.CabalFile (inputCabalFiles)
import Tricorder.Session.Command (Command (..))
import Tricorder.Socket.UnixSocket (runUnixSocketIO)
import Tricorder.SourceLookup.PackageId (PackageId)

import Tricorder.CLI.App qualified as App
import Tricorder.CLI.UI.Keys qualified as Keys
import Tricorder.Session.StackYaml qualified as StackYaml
import Tricorder.SourceLookup qualified as SourceLookup
import Tricorder.SourceLookup.GhcPkg qualified as GhcPkg
import Tricorder.SourceLookup.Hackage qualified as Hackage
import Tricorder.SourceLookup.PackageStore qualified as PackageStore


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
        . Glob.runIO
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
        . runEnv
        . inputLoadedConfig
        . runLogNoOp
        . StackYaml.runWithCache
        . inputCabalFiles
        . runInputEff loadSession
        . runInputEff ((.command.repl) <$> input)
        . runReader @CacheConfig.Config def
        . Cache.runCacheTtl @ModuleName @PackageId
        . Cache.runCacheTtl @(PackageId, SourceQuery) @SourceLookup.ModuleSourceResult
        . GhcPkg.runGhcPkgIO
        . PackageStore.run
        . Hackage.run
        $ do
            installTerminationHandler
            App.run
