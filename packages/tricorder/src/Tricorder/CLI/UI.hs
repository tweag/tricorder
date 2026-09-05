module Tricorder.CLI.UI
    ( viewUi
    )
where

import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Console (Console)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.File (File)
import Atelier.Effects.Process (Process, getExecutablePath, proc, runProcess)
import Brick (App (..), neverShowCursor)
import Brick.BChan (BChan, writeBChanNonBlocking)
import Brick.Keybindings (KeyConfig)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (TVar, atomically, newTVarIO, readTVarIO, writeTVar)
import Effectful.Exception (bracket_, trySync)
import Effectful.Reader.Static (Reader, ask)

import Atelier.Effects.Conc qualified as Conc

import Tricorder.CLI.Daemon (waitForDaemon)
import Tricorder.CLI.UI.Brick (Brick)
import Tricorder.CLI.UI.BrickChan (BrickChan)
import Tricorder.CLI.UI.Event (Event (..), handleEvent)
import Tricorder.CLI.UI.Keys (KeyEvent, dispatcher)
import Tricorder.CLI.UI.State (State (..), Viewports (..))
import Tricorder.CLI.UI.View (mkAttrMap, view)
import Tricorder.Runtime (SocketPath (..))
import Tricorder.Socket.Client (queryWatch)
import Tricorder.Socket.UnixSocket (UnixSocket)

import Tricorder.CLI.UI.Brick qualified as Brick
import Tricorder.CLI.UI.BrickChan qualified as BrickChan
import Tricorder.CLI.UI.Keys qualified as Keys
import Tricorder.CLI.UI.State qualified as Model


-- | Connect to the daemon and render a live-updating build status display using
-- a brick TUI. Quits on @q@ or @Esc@; arrow keys scroll the viewport; @R@
-- restarts the daemon.
viewUi
    :: ( Brick :> es
       , BrickChan :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Console :> es
       , Delay :> es
       , File :> es
       , Process :> es
       , Reader Keys.Config :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Eff es ()
viewUi = do
    SocketPath sockPath <- ask
    chan <- BrickChan.newBChan 10
    restartChan <- BrickChan.newBChan 1
    -- Set while a restart we triggered is in flight, so the watch loop stays
    -- patient and reconnects to the fresh daemon instead of giving up.
    restarting <- newTVarIO False
    initialState <- Model.init
    Conc.scoped do
        _ <-
            Conc.fork do
                queryWatch sockPath (readTVarIO restarting)
                    $ BrickChan.writeBChan chan . NewBuildState
                BrickChan.writeBChan chan $ FailedBuild "Lost contact with the daemon"
        _ <- Conc.fork $ restartWorker restartChan restarting
        keyConfig <- Keys.mkKeyConfig
        let requestRestart = void $ writeBChanNonBlocking restartChan ()
        void
            $ Brick.runBrickApp
                chan
                (watchApp requestRestart keyConfig)
                initialState


-- | Wait for restart requests from the TUI and service each one by spawning a
-- fresh @tricorder restart@ process.
--
-- The restart must happen out-of-process: starting the daemon double-forks (see
-- "System.Posix.Daemon"), and forking this vty-controlled process knocks the
-- terminal out of the raw mode brick set up, so keystrokes stop being captured.
-- Delegating to a separate process keeps the fork isolated. The brick event
-- handler signals us over @restartChan@ because it cannot run these effects.
restartWorker
    :: ( BrickChan :> es
       , Concurrent :> es
       , Delay :> es
       , Process :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => BChan ()
    -> TVar Bool
    -> Eff es ()
restartWorker restartChan restarting = forever
    $ bracket_
        (BrickChan.readBChan restartChan >> atomically (writeTVar restarting True))
        (atomically $ writeTVar restarting False)
        do
            self <- getExecutablePath
            -- Swallow failures: a restart that errors must not take down the TUI, and
            -- the flag has to be cleared either way.
            _ <- trySync $ runProcess $ proc self ["restart"]
            void waitForDaemon


watchApp :: IO () -> KeyConfig KeyEvent -> App State Event Viewports
watchApp requestRestart kc =
    App
        { appDraw = view kc
        , appHandleEvent = handleEvent $ dispatcher requestRestart kc
        , appStartEvent = pure ()
        , appAttrMap = mkAttrMap
        , appChooseCursor = neverShowCursor
        }
