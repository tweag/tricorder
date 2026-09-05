module Atelier.Effects.Publishing.Sub
    ( Sub (..)
    , listen
    , listen_
    , listenWith
    , listenWith_
    , listenOnce
    , listenOnce_
    , listenUntil
    , listenUntil_
    , listenUntilM
    , listenUntilM_
    , forkListener
    , forkListener_
    )
where

import Data.Time (UTCTime)
import Effectful (Effect, inject)
import Effectful.Concurrent.STM
    ( Concurrent
    , atomically
    , newEmptyTMVar
    , putTMVar
    , takeTMVar
    )
import Effectful.Error.Static (runErrorNoCallStack, throwError)
import Effectful.TH (makeEffect)

import Text.Show qualified as S

import Atelier.Effects.Conc (Conc, fork_)


-- | Effect for subscribing to events of type @event@.
data Sub (event :: Type) :: Effect where
    -- | Subscribe, then run @onSubscribed@ once the subscription is established
    -- — after the internal channel has been duplicated and before any event is
    -- delivered — and thereafter deliver every published event to the listener,
    -- forever. The @onSubscribed@ hook lets a caller synchronize on "subscribed"
    -- so a concurrently-started publisher cannot race ahead of the subscription
    -- and have its events missed. Most callers want 'listen' (no hook); a caller
    -- that forks the listener and then publishes must wait on this hook first.
    ListenWith
        :: m ()
        -- ^ @onSubscribed@ hook to better synchronize on "subscribed".
        -> (UTCTime -> event -> m ())
        -- ^ Listener function to react to events.
        -> Sub event m Void


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


-- | Listens until the passed function returns @Just a@, returning said @a@
-- with a timestamp.
listenUntil :: (Sub event :> es) => (UTCTime -> event -> Maybe a) -> Eff es (UTCTime, a)
listenUntil f = do
    res <- runErrorNoCallStack
        $ listen
        $ \timestamp event -> whenJust (f timestamp event) \a -> do
            throwError $ OnceEx (timestamp, a)
    case res of
        Left (OnceEx x) -> pure x
        Right v -> absurd v


listenUntil_ :: (Sub event :> es) => (event -> Maybe a) -> Eff es a
listenUntil_ f = snd <$> listenUntil (\_ -> f)


-- | Listens until the passed event handler returns @Just a@, returning said
-- @a@ with a timestamp.
listenUntilM :: (Sub event :> es) => (UTCTime -> event -> Eff es (Maybe a)) -> Eff es (UTCTime, a)
listenUntilM f = do
    res <- runErrorNoCallStack
        $ listen
        $ \timestamp event -> whenJustM (inject $ f timestamp event) \a -> do
            throwError $ OnceEx (timestamp, a)
    case res of
        Left (OnceEx x) -> pure x
        Right v -> absurd v


-- | Listens until the passed event handler returns @Just a@, returning said
-- @a@.
listenUntilM_ :: (Sub event :> es) => (event -> Eff es (Maybe a)) -> Eff es a
listenUntilM_ f = snd <$> listenUntilM (\_ -> f)


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
