module Tricorder.CLI.App (run) where

import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Console (Console)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Exit (Exit)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Input (Input)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Posix.Daemons (Daemons)
import Atelier.Effects.Process (Process)
import Atelier.Effects.Timeout (Timeout)
import Effectful (IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Reader.Static (Reader, ask, asks)
import Tricorder.API.Command
    ( Command (..)
    , EvalCommentsOptions (..)
    , LogMode (..)
    , StatusOptions (..)
    )
import Prelude hiding (force)

import Atelier.Effects.Console qualified as Console
import Tricorder.API.IfDaemonIsStopped qualified as IfDaemonIsStopped

import Tricorder.CLI.Daemon (startDaemon, waitForDaemon)
import Tricorder.CLI.Operations (showEvalComments, showLog, showSource, showStatus, showTests)
import Tricorder.CLI.UI (viewUi)
import Tricorder.CLI.UI.Brick (Brick)
import Tricorder.CLI.UI.BrickChan (BrickChan)
import Tricorder.Daemon.DaemonInfo (DaemonInfo)
import Tricorder.Runtime (LogPath (..), PidFile (..), SocketPath (..))
import Tricorder.Session.CabalFile (CabalFile)
import Tricorder.Session.Repl (Repl)
import Tricorder.Socket.Client (isDaemonRunning)
import Tricorder.Socket.UnixSocket (UnixSocket)
import Tricorder.SourceLookup.GhcPkg (GhcPkg)
import Tricorder.SourceLookup.Hackage (Hackage)
import Tricorder.SourceLookup.PackageStore (PackageStore)

import Tricorder.CLI.App.Daemon qualified as Daemon
import Tricorder.CLI.App.Test qualified as Test
import Tricorder.CLI.UI.Keys qualified as Keys


run
    :: ( Brick :> es
       , BrickChan :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Console :> es
       , Daemons :> es
       , Delay :> es
       , Exit :> es
       , File :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Hackage :> es
       , IOE :> es
       , Input DaemonInfo :> es
       , Input Repl :> es
       , Input [CabalFile] :> es
       , Log :> es
       , PackageStore :> es
       , Process :> es
       , Reader Command :> es
       , Reader Keys.Config :> es
       , Reader LogPath :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , Timeout :> es
       , UnixSocket :> es
       )
    => Eff es ()
run =
    ask >>= \case
        Status opts -> do
            running <- isDaemonRunning
            if
                | not running && opts.ifDaemonIsStopped == IfDaemonIsStopped.StartDaemon -> do
                    startDaemon
                    void waitForDaemon
                    showStatus opts
                | not running -> Console.putStrLn "Stopped."
                | otherwise -> showStatus opts
        TestResults opts -> do
            running <- isDaemonRunning
            if not running
                then Console.putStrLn "Stopped."
                else showTests opts
        Log logMode -> do
            logFile <- asks @LogPath (.getLogPath)
            case logMode of
                ShowLog -> showLog logFile
                ShowLogPath -> Console.putTextLn (toText logFile)
        UI -> do
            running <- isDaemonRunning
            unless running do
                startDaemon
                void waitForDaemon
            viewUi
        Source opts -> do
            showSource opts
        EvalComments opts -> do
            when (opts.ifDaemonIsStopped == IfDaemonIsStopped.StartDaemon) do
                running <- isDaemonRunning
                unless running do
                    startDaemon
                    void waitForDaemon
            showEvalComments opts
        Test testCmd -> Test.run testCmd
        Daemon cmd -> Daemon.run cmd
