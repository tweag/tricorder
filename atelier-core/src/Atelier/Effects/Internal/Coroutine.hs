-- | Internal: the shared implementation of the 'Yield' and 'Await' coroutine
-- effects.
--
-- Both effects, along with their operations and interpreters, are defined here;
-- "Atelier.Effects.Yield" and "Atelier.Effects.Await" re-export curated subsets
-- for public use. Exposed chiefly for testing — prefer the public modules.
module Atelier.Effects.Internal.Coroutine
    ( -- * Yield
      Yield (..)

      -- ** Operations
    , yield
    , inFoldable
    , yieldEvents
    , cycleToYield

      -- ** Interpreters
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

      -- * Await
    , Await (..)

      -- ** Operations
    , await

      -- ** Interpreters
    , eachAwait

      -- * Shared

      -- ** Operations
    , takeAwait

      -- ** Interpreters
    , awaitYield
    ) where

import Effectful (Effect, UnliftStrategy (..), inject, raiseWith)
import Effectful.Dispatch.Dynamic (interpretWith_, interpret_, reinterpretWith_, reinterpret_)
import Effectful.State.Static.Shared (evalState, get, modify, runState, state)
import Effectful.TH (makeEffect)
import Prelude hiding (catMaybes, map, mapMaybe)

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Publishing.Sub (Sub)

import Atelier.Effects.Chan qualified as Chan
import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Publishing.Sub qualified as Sub


-- * Yield


-- | Yield values to the effect system. The producing side of the
-- 'Yield'/'Await' pair. Analogous to 'Writer' and 'Output' effects.
data Yield a :: Effect where
    Yield :: a -> Yield a m ()


makeEffect ''Yield


-- ** Yield operations


-- | 'Yield' all elements of a foldable.
inFoldable :: forall a t es. (Foldable t, Yield a :> es) => t a -> Eff es ()
inFoldable =
    foldl'
        ( \prev x -> do
            prev
            yield x
        )
        (pure ())


-- | 'Yield' all elements of a foldable, cycling it 'forever'.
cycleToYield :: forall a f es. (Foldable f, Yield a :> es) => f a -> Eff es ()
cycleToYield = forever . inFoldable


-- | 'Yield' all events captured from a 'Sub' effect.
yieldEvents :: forall a es. (Conc :> es, Sub a :> es, Yield a :> es) => Eff es ()
yieldEvents = Conc.scoped do
    Conc.fork_ $ Sub.listen_ yield
    pure ()


-- ** Yield interpreters


-- | Perform an action for each value of a 'Yield' stream.
forEach :: (a -> Eff es b) -> Eff (Yield a : es) r -> Eff es r
forEach f = interpret_ \(Yield x) -> void $ f x


-- | Collect all 'Yield'ed values into a list.
yieldToList :: Eff (Yield a : es) r -> Eff es (r, [a])
yieldToList = fmap (second reverse) . yieldToReverseList


-- | Collect all 'Yield'ed values into a list. This function is more optimal to
-- use than 'yieldToList' if the reversed order is acceptable.
yieldToReverseList :: Eff (Yield a : es) r -> Eff es (r, [a])
yieldToReverseList = reinterpret_ (runState []) \(Yield x) -> modify (x :)


-- | Allows a computation to 'Yield' values before performing a function over
-- the 'yield'ed values as a list.
withYieldToList :: Eff (Yield a : es) ([a] -> r) -> Eff es r
withYieldToList act = evalState [] do
    f <- interpretWith_ (inject act) \(Yield x) -> modify (x :)
    xs <- get
    pure $ f $ reverse xs


-- | Ignore all 'Yield'ed values, discarding them.
ignoreYield :: Eff (Yield a : es) r -> Eff es r
ignoreYield = interpret_ \(Yield _) -> pure ()


-- | Pair each 'Yield'ed value with its index in the sequence of yielded
-- values.
enumerate :: Eff (Yield a : es) r -> Eff (Yield (Int, a) : es) r
enumerate = enumerateFrom 0


-- | Pair each 'Yield'ed value with its index in the sequence of yielded
-- values, starting from `initial`.
enumerateFrom :: Int -> Eff (Yield a : es) r -> Eff (Yield (Int, a) : es) r
enumerateFrom initial act = raiseWith SeqUnlift \unlift ->
    reinterpretWith_ (evalState initial) act \(Yield x) -> do
        i <- state \s -> (s, s + 1)
        inject $ unlift $ yield (i, x)


-- | Map a 'Yield' stream of values into a different 'Yield' stream of values.
-- The consumed stream will not be visible to downstream computations, and the
-- produced stream will not be visible to upstream computations.
map :: (a -> b) -> Eff (Yield a : es) r -> Eff (Yield b : es) r
map f act = raiseWith SeqUnlift \unlift ->
    interpretWith_ act \(Yield x) -> unlift $ yield $ f x


-- | Map a 'Yield'  stream of values. Values returned as 'Just' will be
-- included in the resulting 'Yield' stream. Values returned as 'Nothing' will
-- be discarded.
mapMaybe :: (a -> Maybe b) -> Eff (Yield a : es) r -> Eff (Yield b : es) r
mapMaybe f act =
    raiseWith SeqUnlift \unlift -> interpretWith_ act \(Yield x) ->
        case f x of
            Just y -> unlift $ yield y
            Nothing -> pure ()


-- | Eliminate 'Nothing's from a 'Yield' stream, resulting in a 'Yield' stream
-- with all the 'Just' values.
catMaybes :: Eff (Yield (Maybe a) : es) r -> Eff (Yield a : es) r
catMaybes act = raiseWith SeqUnlift \unlift -> interpretWith_ act \case
    Yield (Just x) -> unlift $ yield x
    Yield Nothing -> pure ()


-- * Await


-- | Request a value from the effect system. The consuming side of the
-- 'Yield'/'Await' pair. Analogous to 'Reader' and 'Input'.
data Await a :: Effect where
    Await :: Await a m a


makeEffect ''Await


-- ** Await operations


-- | Take 'n' values from an 'Await' effect and re-'yield' them to a new
-- 'Yield' event.
--
-- This operation is of dubious value given how Effectful's effect system
-- works, but it is included here for brevity's sake.
takeAwait :: (Await a :> es, Yield a :> es) => Int -> Eff es ()
takeAwait 0 = pure ()
takeAwait c = do
    await >>= yield
    takeAwait (c - 1)


-- ** Await interpreters


-- | Answers each `Await` with the passed action's result.
eachAwait :: forall a es r. Eff es a -> Eff (Await a : es) r -> Eff es r
eachAwait mk = interpret_ \Await -> mk


-- | Supplies the `Await` effect of one computation with the `Yield` effect of
-- another.
awaitYield
    :: forall a es r
     . (Chan :> es, Conc :> es)
    => Eff (Yield a : es) r
    -> Eff (Await a : es) r
    -> Eff es r
awaitYield yields awaits = Conc.scoped do
    (inChan, outChan) <- Chan.newChan @a
    let yielder = interpretWith_ yields \(Yield x) -> Chan.writeChan inChan x
        awaiter = interpretWith_ awaits \Await -> Chan.readChan outChan
    -- Ensure the awaiter runs first.
    awaitThread <- Conc.fork awaiter
    yieldThread <- Conc.fork yielder
    either id id <$> Conc.race (Conc.await awaitThread) (Conc.await yieldThread)
