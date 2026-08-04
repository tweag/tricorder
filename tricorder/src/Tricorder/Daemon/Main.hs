module Tricorder.Daemon.Main (main) where

import Atelier.Effects.Cache (runCacheTtl)
import Atelier.Effects.Chan (runChan)
import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Debounce (runDebounce)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.Env (runEnv)
import Atelier.Effects.Exit (runExit)
import Atelier.Effects.File (runFile)
import Atelier.Effects.FileSystem (runFileSystemIO)
import Atelier.Effects.FileWatcher (runFileWatcherIO)
import Atelier.Effects.Process (runProcessIO)
import Atelier.Effects.Publishing (runPubSub_)
import Atelier.Effects.Timeout (runTimeout)
import Data.Default (def)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState)

import Atelier.Effects.Cache.Config qualified as CacheConfig
import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log qualified as Log

import Tricorder.BuildState (BuildId (..))
import Tricorder.Config (inputLoadedConfig)
import Tricorder.Daemon.Progress (Progress)
import Tricorder.Effects.Cabal (runCabalIO)
import Tricorder.Effects.GhcPkg (runGhcPkgIO)
import Tricorder.Effects.GhciSession (runGhciSession)
import Tricorder.Effects.Logging (runLogging)
import Tricorder.Effects.UnixSocket (runUnixSocketIO)
import Tricorder.Runtime (runLogPath, runProjectRoot, runRuntimeDir, runSocketPath)
import Tricorder.Session (inputCabalFiles, inputSession)

import Tricorder.Daemon.Core qualified as Core
import Tricorder.Daemon.DaemonInfo qualified as DaemonInfo
import Tricorder.Daemon.EvalCommentRunner qualified as EvalCommentRunner
import Tricorder.Daemon.TestRunner qualified as TestRunner
import Tricorder.Effects.Waiters qualified as Waiters
import Tricorder.GhcPkg.Types qualified as GhcPkg
import Tricorder.Socket.Server qualified as Server
import Tricorder.SourceLookup qualified as SourceLookup
import Tricorder.Version qualified as Version


-- | Run the daemon for the given project root.
-- Blocks forever; all work happens inside the component system.
main :: IO ()
main =
    runEff
        . runConcurrent
        . runConc
        . runClock
        . runDelay
        . runTimeout
        . runDebounce @FilePath
        . runFileWatcherIO
        . runFileSystemIO
        . runProjectRoot
        . runExit
        . runFile
        . runRuntimeDir
        . runSocketPath
        . runLogPath
        . runLogging
        . inputLoadedConfig
        . runChan
        . inputCabalFiles
        . inputSession
        . runReader @CacheConfig.Config def
        . DaemonInfo.runInput
        . runCacheTtl @GhcPkg.ModuleName @GhcPkg.PackageId
        . runCacheTtl @(GhcPkg.PackageId, GhcPkg.SourceQuery) @SourceLookup.ModuleSourceResult
        . runProcessIO
        . runCabalIO
        . runEnv
        . runGhcPkgIO
        . runUnixSocketIO
        . runGhciSession
        . evalState (BuildId 1)
        . Input.fromState @BuildId
        . runPubSub_ @Progress
        . EvalCommentRunner.run
        . TestRunner.run
        . Waiters.run
        $ do
            Log.info $ "Starting tricorder " <> Version.gitHash
            Conc.fork_ Core.main
            Conc.fork_ Server.main
            Conc.awaitAll
