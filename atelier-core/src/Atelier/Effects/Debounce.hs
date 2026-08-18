-- | Debounce effect for coalescing rapid bursts of keyed events.
--
-- == Overview
--
-- 'debouncedWith' is the fundamental operation: it accumulates rapid successive
-- calls with the same key using a merge function, then fires the callback once
-- after the settle window with the merged result.
--
-- 'debounced' is a convenience wrapper for the common case where only timing
-- matters and the last-registered action should fire.
--
-- == Example
--
-- @
-- -- Coalesce rapid saves per file: only the last edit within a 200ms window
-- -- triggers a rebuild, keyed by path.
-- onEdit :: (Debounce FilePath :> es) => FilePath -> Eff es ()
-- onEdit path = debounced 200 path (rebuild path)
--
-- -- Or merge the burst instead of keeping just the last value. Here every
-- -- event seen within the window is combined (list append) before a single
-- -- rebuild fires with the full batch.
-- onChange :: (Debounce FilePath :> es) => FilePath -> FileEvent -> Eff es ()
-- onChange path event =
--     debouncedWith 200 (<>) path [event] (rebuildWith path)
-- @
module Atelier.Effects.Debounce
    ( -- * Effect
      Debounce
    , debouncedWith
    , debounced

      -- * Interpreters
    , runDebounce
    , runDebounceNoOp

      -- * Helpers
    , ensureEntry
    , ensureCallback
    , Entry (..)
    )
where

import Data.Dynamic (Dynamic, fromDynamic, toDyn)
import Effectful (Effect, Limit (..), Persistence (..), UnliftStrategy (..))
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (STM)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift, localUnlift)
import Effectful.TH (makeEffect)

import Effectful.Concurrent.STM qualified as STM
import StmContainers.Map qualified as Map

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay)
import Atelier.Time (Millisecond)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Delay qualified as Delay


-- | Effect for coalescing rapid bursts of keyed events into a single delayed
-- callback.
data Debounce key :: Effect where
    -- | Schedule @callback merged@ after the settle window. If another call
    -- with the same @key@ arrives before the window expires, the two values are
    -- combined with @merge old new@ and the timer resets. The callback fires at
    -- most once per burst.
    DebouncedWith
        :: (Typeable arg)
        => Millisecond
        -> (arg -> arg -> arg)
        -> key
        -> arg
        -> (arg -> m a)
        -> Debounce key m ()


makeEffect ''Debounce


-- | Schedule @action@ to run after the settle window unless a newer call with
-- the same @key@ arrives first. The last-registered action fires.
debounced :: (Debounce key :> es) => Millisecond -> key -> Eff es a -> Eff es ()
debounced settleMs key action = debouncedWith settleMs (\_ _ -> ()) key () (\_ -> action)


-- | Per-key debounce state: the latest (merged) pending argument and a
-- generation counter used to tell whether a scheduled fire is still the most
-- recent call for that key.
data Entry = Entry
    { arg :: Maybe Dynamic
    -- ^ The latest pending argument (type-erased), or 'Nothing' once consumed.
    , generation :: Int
    -- ^ Counter bumped on every call for the key; identifies the latest one.
    }


-- | Run the 'Debounce' effect.
--
-- Each key maintains a generation counter. Rapid calls for the same key merge
-- their values and reset the settle timer; only the last generation fires.
runDebounce
    :: forall key es a
     . ( Conc :> es
       , Concurrent :> es
       , Delay :> es
       , Hashable key
       )
    => Eff (Debounce key : es) a
    -> Eff es a
runDebounce eff = do
    state <- STM.atomically (Map.new @key @Entry)
    interpretWith eff \env -> \case
        DebouncedWith settleMs merge key arg callback -> do
            entry <- STM.atomically $ ensureEntry key arg state merge
            localUnlift env (ConcUnlift Persistent (Limited 1)) \unlift ->
                void
                    $ Conc.fork
                    $ ensureCallback settleMs state key entry.generation
                    $ unlift . callback


-- | Sleep for @settleMs@, then atomically check whether this fork's
-- @generation@ is still the latest in the map for @key@. If yes, take the
-- (possibly merged) argument, remove the entry, and fire the callback. If a
-- newer call has bumped the generation in the meantime, exit silently.
ensureCallback
    :: forall key arg es a
     . ( Concurrent :> es
       , Delay :> es
       , Hashable key
       , Typeable arg
       )
    => Millisecond
    -> Map.Map key Entry
    -> key
    -> Int
    -> (arg -> Eff es a)
    -> Eff es ()
ensureCallback settleMs state key myGeneration callback = do
    Delay.wait settleMs
    fire <- STM.atomically do
        Map.lookup key state >>= \case
            Just e | e.generation == myGeneration -> do
                Map.delete key state
                pure $ fromDynamic =<< e.arg
            _ -> pure Nothing
    case fire of
        Just arg -> void $ callback arg
        Nothing -> pure ()


ensureEntry
    :: (Hashable key, Typeable value)
    => key
    -> value
    -> Map.Map key Entry
    -> (value -> value -> value)
    -> STM Entry
ensureEntry key value state merge = do
    current <- Map.lookup key state
    let (gen, prior) = case current of
            Nothing -> (0, Nothing)
            Just e -> (e.generation + 1, e.arg >>= fromDynamic)
    let merged = case prior of
            Just p -> merge p value
            Nothing -> value
    let updatedEntry =
            Entry
                { arg = Just (toDyn merged)
                , generation = gen
                }
    Map.insert updatedEntry key state
    pure updatedEntry


-- | No-op interpreter — fires every callback immediately with its value, without
-- debouncing. Useful for tests where timing is controlled externally.
runDebounceNoOp :: Eff (Debounce key : es) a -> Eff es a
runDebounceNoOp eff = interpretWith eff \env -> \case
    DebouncedWith _ _ _ value callback -> localSeqUnlift env \unlift -> void $ unlift (callback value)
