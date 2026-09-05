module Atelier.Effects.Publishing.Traced
    ( runPubSub
    )
where

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Publishing.Pub (Pub (..))
import Atelier.Effects.Publishing.Sub (Sub (..))
import Data.Time (UTCTime)
import Effectful.Dispatch.Dynamic (interpretWith, interpretWith_, localSeqUnlift)

import Atelier.Effects.Chan qualified as Chan
import Atelier.Effects.Clock qualified as Clock

import Atelier.Effects.Monitoring.Tracing (SpanContext, Tracing)

import Atelier.Effects.Monitoring.Tracing qualified as Tracing


-- | Internal wrapper for events with trace context
data TracedEvent event = TracedEvent
    { event :: event
    , timestamp :: UTCTime
    , publisherSpanContext :: Maybe SpanContext
    }


-- | Runs 'Pub' and 'Sub' effects with an internal channel for a specific event
-- type. Automatically captures span context from the publisher and creates
-- linked spans in listeners.
runPubSub
    :: forall event es a
     . ( Chan :> es
       , Clock :> es
       , Tracing :> es
       )
    => Eff (Pub event : Sub event : es) a -> Eff es a
runPubSub action = do
    (inChan, _) <- Chan.newChan @(TracedEvent event)

    let handlePub eff = interpretWith_ eff \case
            Publish event -> do
                timestamp <- Clock.currentTime
                -- Capture the current span context from the publisher
                publisherSpanContext <- Tracing.getSpanContext
                Chan.writeChan inChan TracedEvent {event, timestamp, publisherSpanContext}

        handleSub eff = interpretWith eff \env -> \case
            ListenWith onSubscribed listener -> localSeqUnlift env \unlift -> do
                chan <- Chan.dupChan inChan
                unlift onSubscribed
                forever do
                    TracedEvent {event, timestamp, publisherSpanContext} <- Chan.readChan chan
                    Tracing.withLinkPropagation publisherSpanContext $ unlift $ listener timestamp event

    handleSub . handlePub $ action
