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
import Atelier.Effects.Publishing (runPubSub)
import Atelier.Effects.Timeout (runTimeout)
import Data.Default (def)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState)
import Tricorder.SourceLookup.SourceQuery (ModuleName, SourceQuery)

import Atelier.Effects.Cache.Config qualified as CacheConfig
import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log qualified as Log

import Tricorder.Build (BuildId (..), BuildPhase)
import Tricorder.Config (inputLoadedConfig)
import Tricorder.Daemon.GhciSession (runGhciSession)
import Tricorder.Logging (runLogging)
import Tricorder.Runtime (runLogPath, runProjectRoot, runRuntimeDir, runSocketPath)
import Tricorder.Session (inputSession)
import Tricorder.Session.CabalFile (inputCabalFiles)
import Tricorder.Socket.UnixSocket (runUnixSocketIO)
import Tricorder.SourceLookup.GhcPkg (runGhcPkgIO)
import Tricorder.SourceLookup.PackageId (PackageId)

import Tricorder.Daemon.Core qualified as Core
import Tricorder.Daemon.DaemonInfo qualified as DaemonInfo
import Tricorder.Daemon.EvalCommentRunner qualified as EvalCommentRunner
import Tricorder.Daemon.Hpack.Effect qualified as Hpack
import Tricorder.Daemon.TestRunner qualified as TestRunner
import Tricorder.Session.Command qualified as Repl
import Tricorder.Socket.Server qualified as Server
import Tricorder.SourceLookup qualified as SourceLookup
import Tricorder.SourceLookup.Hackage qualified as Hackage
import Tricorder.SourceLookup.PackageStore qualified as PackageStore
import Tricorder.Version qualified as Version
import Tricorder.Waiters qualified as Waiters


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
        . runEnv
        . inputCabalFiles
        . inputSession
        . runReader @CacheConfig.Config def
        . DaemonInfo.runInput
        . runCacheTtl @ModuleName @PackageId
        . runCacheTtl @(PackageId, SourceQuery) @SourceLookup.ModuleSourceResult
        . runProcessIO
        . runGhcPkgIO
        . runUnixSocketIO
        . runGhciSession
        . evalState (BuildId 1)
        . Input.fromState @BuildId
        . evalState Repl.Unknown
        . Input.fromState @Repl.Repl
        . runPubSub @BuildPhase
        . Hpack.run
        . Hackage.run
        . PackageStore.run
        . EvalCommentRunner.run
        . TestRunner.run
        . Waiters.run
        $ do
            Log.info $ "Starting tricorder " <> Version.gitHash
            Conc.fork_ Core.main
            Conc.fork_ Server.main
            Conc.awaitAll
