module Tricorder.Daemon.Main (main) where

import Atelier.Component (runSystem)
import Atelier.Config (runConfig)
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
import Atelier.Effects.Monitoring.Metrics.Server (runMetricsServerIO)
import Atelier.Effects.Monitoring.Tracing (TracingConfig, runTracingFromConfig)
import Atelier.Effects.Process (runProcessIO)
import Atelier.Effects.Publishing (runPubSub)
import Atelier.Effects.Timeout (runTimeout)
import Data.Default (def)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState)

import Atelier.Effects.Cache.Config qualified as CacheConfig
import Atelier.Effects.Log qualified as Log

import Tricorder.BuildState (BuildId (..), runDaemonInfo)
import Tricorder.Config (restartOnConfigChange, runLoadedConfig)
import Tricorder.Effects.BuildStore (runBuildStore)
import Tricorder.Effects.Cabal (runCabalIO)
import Tricorder.Effects.GhcPkg (runGhcPkgIO)
import Tricorder.Effects.GhciSession (runGhciSession)
import Tricorder.Effects.Logging (runLogging)
import Tricorder.Effects.SessionStore (runSessionStore)
import Tricorder.Effects.TestRunner (runTestRunnerIO)
import Tricorder.Effects.UnixSocket (runUnixSocketIO)
import Tricorder.Runtime (runLogPath, runProjectRoot, runRuntimeDir, runSocketPath)
import Tricorder.Session (runCabalFiles)

import Tricorder.BuildState qualified as BuildState
import Tricorder.Builder qualified as Builder
import Tricorder.Builder.Dispatch qualified as Dispatch
import Tricorder.Effects.SessionStore qualified as SessionStore
import Tricorder.GhcPkg.Types qualified as GhcPkg
import Tricorder.Observability qualified as Observability
import Tricorder.Socket.Server qualified as SocketServer
import Tricorder.SourceLookup qualified as SourceLookup
import Tricorder.Version qualified as Version
import Tricorder.Watcher qualified as Watcher


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
        . runDebounce @Text
        . runFileWatcherIO
        . runFileSystemIO
        . runProjectRoot
        . restartOnConfigChange
        . runExit
        . runFile
        . runRuntimeDir
        . runSocketPath
        . runLogPath
        . runLogging
        . runLoadedConfig
        . runConfig @"observability" @Observability.Config
        . runConfig @"observability.tracing" @TracingConfig
        . runTracingFromConfig
        . runChan
        . runPubSub @SessionStore.SessionStoreReloaded
        . runCabalFiles
        . runSessionStore
        . runReader @CacheConfig.Config def
        . runPubSub @Watcher.WatchedFile
        . runPubSub @BuildState.CabalChangeDetected
        . runPubSub @BuildState.SourceChangeDetected
        . runDaemonInfo
        . runCacheTtl @GhcPkg.ModuleName @GhcPkg.PackageId
        . runCacheTtl @(GhcPkg.PackageId, GhcPkg.SourceQuery) @SourceLookup.ModuleSourceResult
        . runBuildStore
        . runProcessIO
        . runCabalIO
        . runEnv
        . runMetricsServerIO
        . runTestRunnerIO
        . runGhcPkgIO
        . runUnixSocketIO
        . runGhciSession
        . evalState (BuildId 1)
        . evalState @Dispatch.BuilderState Dispatch.emptyBuilderState
        $ do
            Log.info $ "Starting tricorder " <> Version.gitHash
            runSystem
                [ Observability.component
                , Watcher.component
                , Builder.component
                , SocketServer.component
                ]
