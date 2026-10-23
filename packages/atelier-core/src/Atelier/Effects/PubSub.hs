module Atelier.Effects.PubSub (run) where

import Data.Time (UTCTime)
import Effectful.Dispatch.Dynamic (interpret, interpret_, localSeqUnlift)

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.PubSub.Pub (Pub (..))
import Atelier.Effects.PubSub.Sub (Sub (..))

import Atelier.Effects.Chan qualified as Chan
import Atelier.Effects.Clock qualified as Clock


-- | Runs 'Pub' and 'Sub' effects with an internal channel for a specific event
-- type.
run
    :: forall event es a
     . (Chan :> es, Clock :> es)
    => Eff (Pub event : Sub event : es) a -> Eff es a
run action = do
    (inChan, _) <- Chan.new @(UTCTime, event)
    let handlePub = interpret_ \case
            Publish event -> do
                timestamp <- Clock.currentTime
                Chan.write inChan (timestamp, event)

        handleSub = interpret \env -> \case
            ListenWith onSubscribed listener -> localSeqUnlift env \unlift -> do
                chan <- Chan.dup inChan
                unlift onSubscribed
                forever do
                    (timestamp, event) <- Chan.read chan
                    unlift $ listener timestamp event

    handleSub . handlePub $ action
