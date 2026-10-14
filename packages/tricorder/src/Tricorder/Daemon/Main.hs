module Tricorder.Daemon.Main (main) where

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
import Atelier.Effects.Timeout (runTimeout)
import Atelier.Signal (installTerminationHandler)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.FileSystem.Glob qualified as Glob
import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.PubSub qualified as PubSub
import Atelier.Effects.PubSub.Sub qualified as Sub
import Effectful.Reader.Static qualified as Reader
import Effectful.State.Static.Shared qualified as State

import Tricorder.Build (BuildId (..), BuildPhase)
import Tricorder.Build.Changes (CabalChangeDetected, SourceChangeDetected)
import Tricorder.Config (inputLoadedConfig)
import Tricorder.Daemon.Watch (WatchedFile)
import Tricorder.Logging (runLogging)
import Tricorder.Runtime (runLogPath, runProjectRoot, runRuntimeDir, runSocketPath)
import Tricorder.Session.CabalFile (inputCabalFiles)
import Tricorder.Socket.UnixSocket (runUnixSocketIO)
import Tricorder.SourceLookup.GhcPkg (runGhcPkgIO)

import Tricorder.Daemon.Core qualified as Core
import Tricorder.Daemon.EvalCommentRunner qualified as EvalCommentRunner
import Tricorder.Daemon.Ghci.Session qualified as Ghci.Session
import Tricorder.Daemon.Hpack.Effect qualified as Hpack
import Tricorder.Daemon.IdleTimer qualified as IdleTimer
import Tricorder.Daemon.TestRunner qualified as TestRunner
import Tricorder.Daemon.Watch qualified as Watch
import Tricorder.Session qualified as Session
import Tricorder.Session.StackProject qualified as StackProject
import Tricorder.Session.State qualified as Session.State
import Tricorder.Socket.Server qualified as Server
import Tricorder.Version qualified as Version
import Tricorder.Waiters qualified as Waiters


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
        . Glob.runIO
        . runProjectRoot
        . runExit
        . runFile
        . runRuntimeDir
        . runSocketPath
        . runLogPath
        . runEnv
        . inputLoadedConfig
        . runLogging
        . runChan
        . StackProject.inputWithCache
        . inputCabalFiles
        . runProcessIO
        . runGhcPkgIO
        . runUnixSocketIO
        . Ghci.Session.run
        . State.evalState (BuildId 1)
        . Input.fromState @BuildId
        . Hpack.run
        . EvalCommentRunner.run
        . TestRunner.run
        . Waiters.run
        . PubSub.run @BuildPhase
        . PubSub.run @CabalChangeDetected
        . PubSub.run @SourceChangeDetected
        . PubSub.run @WatchedFile
        . Session.State.eval
        . Input.withEff (Session.idleTimeout <$> Session.State.currentSession)
        . IdleTimer.quitOnTimeout
        $ do
            installTerminationHandler
            Log.info $ "Starting tricorder " <> Version.gitHash
            Conc.fork_ $ Sub.listen_ Watch.publishChange
            Conc.fork_ Server.main
            vacuous $ Session.State.withSession \session -> do
                root <- Reader.ask
                Conc.fork_ $ Watch.files root session
                Core.main session
