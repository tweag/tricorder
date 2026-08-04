module Tricorder.CLI.UI.Brick
    ( -- * Brick
      Brick
    , runBrickApp
    , runBrick
    ) where

import Brick.Main (App, customMain)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)
import Graphics.Vty (Mode (Mouse), outputIface, setMode)
import Graphics.Vty.Config (userConfig)
import Graphics.Vty.CrossPlatform (mkVty)

import Tricorder.CLI.UI.BrickChan (BChan)


data Brick :: Effect where
    RunBrickApp
        :: (Ord resource)
        => BChan event
        -- ^ Channel for publishing events for the app from outside the app
        -> App state event resource
        -- ^ App to run
        -> state
        -- ^ Initial state
        -> Brick m state


makeEffect ''Brick


runBrick :: (IOE :> es) => Eff (Brick : es) a -> Eff es a
runBrick = interpret_ \case
    RunBrickApp chan app initialState -> liftIO do
        let buildVty = do
                cfg <- userConfig
                vty <- mkVty cfg
                setMode (outputIface vty) Mouse True
                pure vty
        initialVty <- liftIO buildVty
        customMain
            initialVty
            buildVty
            (Just chan)
            app
            initialState
