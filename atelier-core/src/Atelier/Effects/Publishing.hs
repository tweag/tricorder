-- | A typed publish/subscribe effect pair.
--
-- 'Pub' publishes events of a given type; 'Sub' subscribes and delivers each
-- published event to a listener. 'runPubSub' wires the two together over an
-- internal broadcast channel, propagating tracing context from publisher to
-- listener; 'runPubWriter' instead records published events to a 'Writer', for
-- tests.
--
-- Subscriptions are established asynchronously, so a listener you intend to
-- publish to should be started with 'forkListener' or 'forkListener_', which
-- block until the subscription is live and therefore cannot miss early events.
module Atelier.Effects.Publishing
    ( Pub (..)
    , Sub
    , listen
    , listen_
    , listenWith
    , listenWith_
    , listenOnce
    , listenOnce_
    , forkListener
    , forkListener_
    , publish
    , runPubSub
    , runPubWriter
    )
where

import Data.Time (UTCTime)
import Effectful (Effect)
import Effectful.Concurrent.STM
    ( Concurrent
    , atomically
    , newEmptyTMVar
    , putTMVar
    , takeTMVar
    )
import Effectful.Dispatch.Dynamic (interpretWith, interpretWith_, interpret_, localSeqUnlift)
import Effectful.Error.Static (runErrorNoCallStack, throwError)
import Effectful.TH (makeEffect)
import Effectful.Writer.Static.Shared (Writer, tell)

import Text.Show qualified as S

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc, fork_)
import Atelier.Effects.Monitoring.Tracing (SpanContext, Tracing)

import Atelier.Effects.Chan qualified as Chan
import Atelier.Effects.Clock qualified as Clock
import Atelier.Effects.Monitoring.Tracing qualified as Tracing


-- | Effect for publishing events of type @event@.
data Pub (event :: Type) :: Effect where
    -- | Publish an event to all current subscribers.
    Publish :: event -> Pub event m ()


-- | Effect for subscribing to events of type @event@.
data Sub (event :: Type) :: Effect where
    -- | Subscribe, then run @onSubscribed@ once the subscription is established
    -- — after the internal channel has been duplicated and before any event is
    -- delivered — and thereafter deliver every published event to the listener,
    -- forever. The @onSubscribed@ hook lets a caller synchronize on "subscribed"
    -- so a concurrently-started publisher cannot race ahead of the subscription
    -- and have its events missed. Most callers want 'listen' (no hook); a caller
    -- that forks the listener and then publishes must wait on this hook first.
    ListenWith :: m () -> (UTCTime -> event -> m ()) -> Sub event m Void


makeEffect ''Pub
makeEffect ''Sub


-- | Subscribe and deliver every published event to the listener, forever.
-- Defined in terms of 'listenWith' with a no-op subscribed hook.
listen :: (Sub event :> es) => (UTCTime -> event -> Eff es ()) -> Eff es Void
listen = listenWith (pure ())


-- | Like 'listen', but the listener ignores the event timestamp.
listen_ :: (Sub event :> es) => (event -> Eff es ()) -> Eff es Void
listen_ listener = listen $ \_timestamp event -> listener event


-- | Like 'listen_', but runs @onSubscribed@ once the subscription is
-- established and before any event is delivered. See 'ListenWith'.
listenWith_ :: (Sub event :> es) => Eff es () -> (event -> Eff es ()) -> Eff es Void
listenWith_ onSubscribed listener = listenWith onSubscribed $ \_timestamp event -> listener event


-- | Fork a background listener and block until it has actually subscribed,
-- then return. The listener runs until the enclosing 'Conc' scope closes.
--
-- This is the safe way to start a listener you intend to publish to: a plain
-- @'fork_' . 'listen'@ followed by a 'publish' races the subscription (which
-- happens asynchronously in the forked thread) and, under scheduler pressure,
-- can drop early events and wedge the listener forever. 'forkListener' closes
-- that window by waiting on the subscribed hook before returning.
forkListener
    :: forall event es
     . (Conc :> es, Concurrent :> es, Sub event :> es)
    => (UTCTime -> event -> Eff es ())
    -> Eff es ()
forkListener listener = do
    subscribed <- atomically newEmptyTMVar
    fork_ $ listenWith (atomically (putTMVar subscribed ())) listener
    atomically (takeTMVar subscribed)


-- | Like 'forkListener', but the listener ignores the timestamp.
forkListener_
    :: forall event es
     . (Conc :> es, Concurrent :> es, Sub event :> es)
    => (event -> Eff es ())
    -> Eff es ()
forkListener_ listener = forkListener @event (\_timestamp event -> listener event)


-- | Wait for a single event and then return said event.
listenOnce :: forall event es. (Sub event :> es) => Eff es (UTCTime, event)
listenOnce = do
    res <- runErrorNoCallStack
        $ listen
        $ \timestamp event -> throwError $ OnceEx (timestamp, event)
    case res of
        Left (OnceEx x) -> pure x
        Right v -> absurd v


-- | Same as 'listenOnce', but discards the timestamp.
listenOnce_ :: (Sub event :> es) => Eff es event
listenOnce_ = snd <$> listenOnce


data OnceEx ev = OnceEx ev
instance Show (OnceEx ev) where show _ = "OnceEx"


-- | Internal wrapper for events with trace context
data TracedEvent event = TracedEvent
    { event :: event
    , timestamp :: UTCTime
    , publisherSpanContext :: Maybe SpanContext
    }


-- | Runs Pub and Sub effects with an internal channel for a specific event type.
-- Automatically captures span context from the publisher and creates linked spans in listeners.
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


-- | Handler that uses a provided Writer effect instead of actually publishing.
-- Useful for testing and inspecting what events were published.
runPubWriter :: forall event es a. (Writer [event] :> es) => Eff (Pub event : es) a -> Eff es a
runPubWriter =
    interpret_ \case
        Publish event -> tell [event]
