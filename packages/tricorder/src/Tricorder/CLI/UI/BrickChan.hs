module Tricorder.CLI.UI.BrickChan
    ( BrickChan
    , BChan
    , newBChan
    , writeBChan
    , readBChan
    , runBrickChan
    )
where

import Brick.BChan (BChan)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)

import Brick.BChan qualified as BChan


data BrickChan :: Effect where
    -- | Lifted `Brick.BChan.newBChan`
    NewBChan :: Int -> BrickChan m (BChan a)
    -- | Lifted `Brick.BChan.writeBChan`
    WriteBChan :: BChan a -> a -> BrickChan m ()
    -- | Lifted `Brick.BChan.readBChan`
    ReadBChan :: BChan a -> BrickChan m a


makeEffect ''BrickChan


runBrickChan :: (IOE :> es) => Eff (BrickChan : es) a -> Eff es a
runBrickChan = interpret_ \case
    NewBChan n -> liftIO $ BChan.newBChan n
    WriteBChan c x -> liftIO $ BChan.writeBChan c x
    ReadBChan c -> liftIO $ BChan.readBChan c
