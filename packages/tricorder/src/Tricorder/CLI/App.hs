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
import Effectful.Provider (Provider_)
import Effectful.Reader.Static (Reader)
import Tricorder.API.Command
    ( Command (..)
    , EvalCommentsOptions (..)
    , LogMode (..)
    , StatusOptions (..)
    )
import Prelude hiding (force)

import Atelier.Effects.Console qualified as Console
import Effectful.Reader.Static qualified as Reader
import Tricorder.API.IfDaemonIsStopped qualified as IfDaemonIsStopped

import Tricorder.CLI.Daemon (startDaemon, waitForDaemon)
import Tricorder.CLI.Operations (showEvalComments, showLog, showSource, showStatus)
import Tricorder.CLI.UI (viewUi)
import Tricorder.CLI.UI.Brick (Brick)
import Tricorder.CLI.UI.BrickChan (BrickChan)
import Tricorder.Daemon.DaemonInfo (DaemonInfo)
import Tricorder.Session.CabalFile (CabalFile)
import Tricorder.Socket.Client (isDaemonRunning)
import Tricorder.Socket.UnixSocket (UnixSocket)
import Tricorder.SourceLookup.GhcPkg (GhcPkg)
import Tricorder.SourceLookup.Hackage (Hackage)
import Tricorder.SourceLookup.PackageStore (PackageStore)

import Tricorder.CLI.App.Daemon qualified as Daemon
import Tricorder.CLI.App.Test qualified as Test
import Tricorder.CLI.UI.Keys qualified as Keys
import Tricorder.Runtime.LogPath qualified as Runtime (LogPath (..))
import Tricorder.Runtime.PidFile qualified as Runtime (PidFile)
import Tricorder.Runtime.SocketPath qualified as Runtime (SocketPath)
import Tricorder.Session.Stage.Build.Session qualified as Build (Session)


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
       , Input Build.Session :> es
       , Input DaemonInfo :> es
       , Input [CabalFile] :> es
       , Log :> es
       , PackageStore :> es
       , Process :> es
       , Provider_ Console Console.Output :> es
       , Reader Command :> es
       , Reader Keys.Config :> es
       , Reader Runtime.LogPath :> es
       , Reader Runtime.PidFile :> es
       , Reader Runtime.SocketPath :> es
       , Timeout :> es
       , UnixSocket :> es
       )
    => Eff es ()
run =
    Reader.ask >>= \case
        Status opts -> do
            running <- isDaemonRunning
            if
                | not running && opts.ifDaemonIsStopped == IfDaemonIsStopped.StartDaemon -> do
                    startDaemon
                    void waitForDaemon
                    showStatus opts
                | not running -> Console.putStrLn "Stopped."
                | otherwise -> showStatus opts
        Log logMode -> do
            Runtime.LogPath logFile <- Reader.ask
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
