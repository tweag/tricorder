module Tricorder.CLI.UI.Event
    ( Event (..)
    , handleEvent
    ) where

import Brick (BrickEvent (..), EventM, vScrollBy, viewportScroll)
import Brick.Keybindings (KeyDispatcher, handleKey)
import Control.Monad.State (modify)

import Graphics.Vty qualified as Vty

import Tricorder.Build (BuildState (..))
import Tricorder.CLI.UI.Keys (KeyEvent)
import Tricorder.CLI.UI.State (Processed (..), State (..), Viewports (..))
import Tricorder.Socket.Client (Restarting (..))


data Event
    = NewBuildState (Either Restarting BuildState)
    | FailedBuild Text


handleEvent :: KeyDispatcher KeyEvent (EventM Viewports State) -> BrickEvent Viewports Event -> EventM Viewports State ()
handleEvent _ (AppEvent ev) = handleAppEvent ev
handleEvent d (VtyEvent (Vty.EvKey key modifiers)) = void $ handleKey d key modifiers
handleEvent _ (MouseDown vp Vty.BScrollUp _ _) = vScrollBy (viewportScroll vp) (-1)
handleEvent _ (MouseDown vp Vty.BScrollDown _ _) = vScrollBy (viewportScroll vp) 1
handleEvent _ _ = pure ()


handleAppEvent :: Event -> EventM Viewports State ()
handleAppEvent = \case
    NewBuildState (Left Restarting) ->
        modify \s -> s {buildState = Waiting}
    NewBuildState (Right bs) ->
        modify \s -> s {buildState = Success bs}
    FailedBuild reason ->
        modify \s -> s {buildState = Failure reason}
