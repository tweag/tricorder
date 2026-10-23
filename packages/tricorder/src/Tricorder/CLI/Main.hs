module Tricorder.CLI.Main (main) where

import Atelier.Effects.Console (Console)
import Atelier.Signal (installTerminationHandler)
import Data.Default (def)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Provider (provideWith_, runProvider_)

import Atelier.Effects.Arguments qualified as Arguments
import Atelier.Effects.Clock qualified as Clock
import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Console qualified as Console
import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.Env qualified as Env
import Atelier.Effects.Exit qualified as Exit
import Atelier.Effects.File qualified as File
import Atelier.Effects.FileSystem qualified as FileSystem
import Atelier.Effects.FileSystem.Glob qualified as Glob
import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Posix.Daemons qualified as Daemons
import Atelier.Effects.Process qualified as Process
import Atelier.Effects.Timeout qualified as Timeout

import Tricorder.CLI.UI.Brick (runBrick)
import Tricorder.CLI.UI.BrickChan (runBrickChan)
import Tricorder.Config (asInput)
import Tricorder.Runtime (runLogPath, runPidFile, runProjectRoot, runRuntimeDir, runSocketPath)
import Tricorder.Session.CabalFile (inputCabalFiles)

import Tricorder.CLI.App qualified as App
import Tricorder.CLI.Arguments qualified as CLI.Arguments
import Tricorder.CLI.UI.Keys qualified as Keys
import Tricorder.Config.LoadedConfig qualified as LoadedConfig
import Tricorder.Daemon.DaemonInfo qualified as DaemonInfo
import Tricorder.Session qualified as Session
import Tricorder.Session.StackProject qualified as StackProject
import Tricorder.Socket.UnixSocket qualified as UnixSocket
import Tricorder.SourceLookup.GhcPkg qualified as GhcPkg
import Tricorder.SourceLookup.Hackage qualified as Hackage
import Tricorder.SourceLookup.PackageStore qualified as PackageStore


main :: IO ()
main =
    runEff
        . Timeout.run
        . runConcurrent
        . Conc.runIO
        . runBrickChan
        . runBrick
        . Console.runIO
        . runProvider_ @Console @Console.Output Console.runOut
        . Exit.runIO
        . Clock.runIO
        . Delay.runIO
        . File.run
        . FileSystem.runIO
        . Glob.runIO
        . runProjectRoot
        . runRuntimeDir
        . runPidFile
        . runSocketPath
        . runLogPath
        . LoadedConfig.asInput
        . LoadedConfig.asNestedInput @"keybindings" @Keys.Config
        . Input.map (either @_ @Keys.Config (const def) id)
        . Input.toReader @Keys.Config
        . Daemons.run
        . Process.run
        . Arguments.runIO
        . CLI.Arguments.reader
        . UnixSocket.runIO
        . Env.runIO
        . Log.runNoOp
        . StackProject.inputWithCache
        . inputCabalFiles
        . Tricorder.Config.asInput
        $ do
            Session.load >>= \case
                Left err -> do
                    provideWith_ @Console Console.Stderr
                        $ Console.putTextLn
                        $ "Failed to load session: " <> err
                    Exit.failure
                Right session ->
                    Input.withConst session
                        . Input.withEff (Session.buildSession <$> Input.input)
                        . GhcPkg.runGhcPkgIO
                        . PackageStore.run
                        . Hackage.run
                        . DaemonInfo.runInput
                        $ do
                            installTerminationHandler
                            App.run
