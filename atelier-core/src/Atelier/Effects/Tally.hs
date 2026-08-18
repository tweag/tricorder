-- | Tally tracking effect for counting occurrences per key
--
-- Tracks the total number of occurrences per key, delegating storage and
-- eviction to a 'Cache' interpreter.
--
-- The effect is polymorphic over both the key type and the status type returned
-- by a caller-supplied classifier function. This allows callers to define their
-- own thresholds and result types rather than relying on a single hard limit.
--
-- == Basic Usage
--
-- @
-- checkDuplicate :: (Tally DuplicateKey :> es) => DuplicateKey -> Config -> Eff es ()
-- checkDuplicate key cfg =
--     withTallyCheck key classify $ \case
--         Nothing      -> pure ()
--         Just Minor   -> warnAboutPeer
--         Just Critical -> banPeer
--   where
--     classify c
--         | c > cfg.criticalThreshold = Just Critical
--         | c > cfg.warningThreshold  = Just Minor
--         | otherwise                 = Nothing
-- @
module Atelier.Effects.Tally
    ( -- * Effect
      Tally
    , withTallyCheck

      -- * Re-exports
    , module Atelier.Effects.Cache.Config

      -- * Interpreters
    , runTally
    , runTallyConst
    )
where

import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Dispatch.Dynamic (interpret, localSeqUnlift, reinterpret)
import Effectful.Reader.Static (Reader)
import Effectful.TH (makeEffect)

import Atelier.Effects.Cache (cacheModify, runCacheTtl)
import Atelier.Effects.Cache.Config
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Log (Log)


-- | Tally tracking effect parameterized by key type
data Tally key :: Effect where
    -- | Increment the hit count for a key and run an action based on a classifier.
    --
    -- The classifier receives the new count and produces a status value of any
    -- type the caller chooses. The continuation then receives that status.
    WithTallyCheck
        :: (Hashable key, Ord key)
        => key -> (Int -> status) -> (status -> m a) -> Tally key m a


makeEffect ''Tally


-- | Run the Tally effect, using a TTL-evicting cache as the backing store
runTally
    :: forall key es a
     . ( Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Delay :> es
       , Hashable key
       , Log :> es
       , Reader Config :> es
       )
    => Eff (Tally key : es) a
    -> Eff es a
runTally = reinterpret (runCacheTtl @key @Int) $ \env -> \case
    WithTallyCheck key classify continuation -> localSeqUnlift env $ \unlift -> do
        count <- cacheModify key (maybe 1 (+ 1))
        unlift $ continuation (classify count)


-- | Interpret 'Tally' with a fixed count for every key, ignoring real
-- tallying. The classifier is always handed @c@, making the outcome
-- deterministic for tests.
runTallyConst :: Int -> Eff (Tally key : es) a -> Eff es a
runTallyConst c = interpret \env -> \case
    WithTallyCheck _ classify f -> localSeqUnlift env \unlift -> unlift $ f (classify c)
