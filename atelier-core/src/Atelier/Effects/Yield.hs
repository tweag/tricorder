-- | The producing half of a 'Yield'\/'Await' coroutine pair.
--
-- A 'Yield' computation emits values one at a time, analogous to the
-- @Writer@\/@Output@ effects. The interpreters here collect the stream
-- ('yieldToList', 'withYieldToList'), drive it ('forEach'), or transform it
-- ('map', 'mapMaybe', 'filter', 'changes', 'enumerate'). The effect itself lives
-- in "Atelier.Effects.Internal.Coroutine" and is re-exported here.
module Atelier.Effects.Yield
    ( -- * Effect
      Yield

      -- * Operations
    , yield
    , inFoldable
    , yieldEvents
    , cycleToYield

      -- * Interpreters
    , forEach
    , yieldToList
    , yieldToReverseList
    , withYieldToList
    , ignoreYield
    , enumerate
    , enumerateFrom
    , map
    , mapMaybe
    , catMaybes
    , changes
    , filter
    )
where

import Effectful.Dispatch.Dynamic (impose_, interpose_)
import Effectful.State.Static.Shared (evalState, get)
import Prelude hiding (catMaybes, filter, map, mapMaybe)

import Atelier.Effects.Internal.Coroutine
    ( Yield (..)
    , catMaybes
    , cycleToYield
    , enumerate
    , enumerateFrom
    , forEach
    , ignoreYield
    , inFoldable
    , map
    , mapMaybe
    , withYieldToList
    , yield
    , yieldEvents
    , yieldToList
    , yieldToReverseList
    )


-- | Forward only the 'yield'ed values that satisfy a predicate, dropping the
-- rest from the stream.
filter :: (a -> Bool) -> Eff (Yield a : es) r -> Eff (Yield a : es) r
filter p = interpose_ \(Yield x) ->
    when (p x) do
        yield x


-- | Re-yield values that differ from a reference value (supplied as the first
-- argument).
changes :: forall a es r. (Eq a) => a -> Eff (Yield a : es) r -> Eff (Yield a : es) r
changes initial = impose_ (evalState initial) \(Yield x) -> do
    curr <- get
    when (curr /= x) do
        yield x
