-- | Tally tracking effect for counting occurrences per key
module Atelier.Effects.Tally
    ( -- * Effect
      Tally
    , count

      -- * Interpreters
    , run
    , runConst
    )
where

import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Dispatch.Dynamic (interpret, localSeqUnlift, reinterpret)
import Effectful.Reader.Static (Reader)
import Effectful.TH (makeEffect)

import Atelier.Effects.Cache.Config
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Log (Log)

import Atelier.Effects.Cache qualified as Cache


-- | Tally tracking effect parameterized by key type
data Tally key :: Effect where
    -- | Increment the hit count for a key and run an action with said count.
    --
    -- @
    -- checkDuplicate :: (Tally DuplicateKey :> es) => DuplicateKey -> Config -> Eff es ()
    -- checkDuplicate key cfg =
    --     withTallyCheck key $ action . classify
    --   where
    --     action = \case
    --         Nothing      -> pure ()
    --         Just Minor   -> warnAboutPeer
    --         Just Critical -> banPeer
    --     classify c
    --         | c > cfg.criticalThreshold = Just Critical
    --         | c > cfg.warningThreshold  = Just Minor
    --         | otherwise                 = Nothing
    -- @
    Count
        :: (Hashable key, Ord key)
        => key -> (Int -> m a) -> Tally key m a


makeEffect ''Tally


-- | Run the Tally effect, using a TTL-evicting cache as the backing store
run
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
run = reinterpret (Cache.runTTL @key @Int) $ \env -> \case
    Count key continuation -> localSeqUnlift env $ \unlift -> do
        c <- Cache.modify key (maybe 1 (+ 1))
        unlift $ continuation c


-- | Interpret 'Tally' with a fixed count for every key, ignoring real
-- tallying. The classifier is always handed @c@, making the outcome
-- deterministic for tests.
runConst :: Int -> Eff (Tally key : es) a -> Eff es a
runConst c = interpret \env -> \case
    Count _ f -> localSeqUnlift env \unlift -> unlift $ f c
