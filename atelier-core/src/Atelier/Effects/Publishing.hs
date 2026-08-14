module Atelier.Effects.Publishing
    ( runPubSub
    )
where

import Data.Time (UTCTime)
import Effectful.Dispatch.Dynamic (interpret, interpret_, localSeqUnlift)

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Publishing.Pub (Pub (..))
import Atelier.Effects.Publishing.Sub (Sub (..))

import Atelier.Effects.Chan qualified as Chan
import Atelier.Effects.Clock qualified as Clock


-- | Runs 'Pub' and 'Sub' effects with an internal channel for a specific event
-- type.
runPubSub
    :: forall event es a
     . (Chan :> es, Clock :> es)
    => Eff (Pub event : Sub event : es) a -> Eff es a
runPubSub action = do
    (inChan, _) <- Chan.newChan @(UTCTime, event)
    let handlePub = interpret_ \case
            Publish event -> do
                timestamp <- Clock.currentTime
                Chan.writeChan inChan (timestamp, event)

        handleSub = interpret \env -> \case
            ListenWith onSubscribed listener -> localSeqUnlift env \unlift -> do
                chan <- Chan.dupChan inChan
                unlift onSubscribed
                forever do
                    (timestamp, event) <- Chan.readChan chan
                    unlift $ listener timestamp event

    handleSub . handlePub $ action
