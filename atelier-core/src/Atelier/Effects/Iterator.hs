-- | A pull-based iterator over a (possibly infinite) stream of values.
--
-- Where the 'Yield' effect pushes values to a consumer, an 'Iterator' is pulled
-- one value at a time with 'next'. 'fromEvents' adapts a 'Sub' event source into
-- an iterator with a buffered, race-free subscription, and a stream can be
-- narrowed with 'filter' and 'changes'.
module Atelier.Effects.Iterator
    ( Iterator
    , next
    , fromEvents
    , filter
    , changes
    ) where

import Effectful.Concurrent (Concurrent)
import Prelude hiding (filter)

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Publishing.Sub (Sub)

import Atelier.Effects.Chan qualified as Chan
import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Publishing.Sub qualified as Sub


-- | A pull-based iterator of (potentially infinite) values.
newtype Iterator es a = Iterator
    { next :: Eff es a
    -- ^ Pull the next value from the iterator, performing whatever effects that
    -- requires.
    }
    deriving (Functor) via (Eff es)


-- | Run a continuation with a buffered iterator of 'Sub' events. The iterator
-- subscribes before the continuation runs, so no events are missed: we use
-- 'Sub.forkListener_', which forks the listener and blocks until it has
-- actually subscribed before returning. Without that barrier the subscription
-- races a publisher started inside @use@, which under scheduler pressure can
-- drop early events and wedge 'next' forever. The listener thread is scoped to
-- the continuation and is killed when it returns.
fromEvents
    :: forall event es a
     . (Chan :> es, Conc :> es, Concurrent :> es, Sub event :> es)
    => (Iterator es event -> Eff es a)
    -> Eff es a
fromEvents use = Conc.scoped do
    (inChan, outChan) <- Chan.newChan
    Sub.forkListener_ (Chan.writeChan inChan)
    use $ Iterator (Chan.readChan outChan)


-- | Iterate only over values that pass a predicate.
filter :: (a -> Bool) -> Iterator es a -> Iterator es a
filter p (Iterator n) = Iterator loop
  where
    loop = do
        x <- n
        if p x then pure x else loop


-- | Iterate only values that differ from the previous one.
changes :: (Eq a) => a -> Iterator es a -> Iterator es a
changes initial iterator = Iterator (loop initial)
  where
    loop prev = do
        x <- next (filter (/= prev) iterator)
        pure x
