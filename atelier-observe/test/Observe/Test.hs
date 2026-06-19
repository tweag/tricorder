-- | A concrete instantiation of the "Atelier.Observe" framework's open parameters, shared
-- by the spec's examples: a 'Signal' observation vocabulary reduced into an 'Obs' (the @o@
-- half), and a 'Res' resource bundle (the @s@ half) with two samplers. A pipeline under
-- test brings its own region vocabulary (the @r@ key); this module fixes only what an
-- observation and a measurement /are/.
module Observe.Test
    ( -- * Observations (the @o@ half)
      Signal (..)
    , Obs (..)
    , reduce

      -- * Measurements (the @s@ half)
    , Res (..)
    , Stats (..)
    , stat
    , timeSampler
    , allocsSampler
    ) where

import Data.Map.Monoidal (MonoidalMap)
import Data.Semigroup (Max (..), Min (..))
import Effectful (IOE)
import GHC.Clock (getMonotonicTime)
import GHC.Conc.Sync (getAllocationCounter)
import GHC.Generics (Generically (..))

import Data.Map.Monoidal qualified as MMap
import Data.Set qualified as Set

import Atelier.Observe (Sampler, gauge)


-- What a tap observes. The 'Check' payload is lazy (@~Bool@), so the production
-- discharge never forces it.
data Signal
    = Golden Text Text -- name, value
    | Check Text ~Bool
    | Tally Text Int


-- A commutative timing summary, so regions merge order-independently. Each field is a
-- standard monoid wrapper, so the 'Semigroup' derives field-wise. @Min@/@Max@ have no
-- identity, so @Stats@ is a 'Semigroup' but not a 'Monoid' — hence 'timing' is
-- @Maybe Stats@.
data Stats = Stats {n :: Sum Int, total :: Sum Double, lo :: Min Double, hi :: Max Double}
    deriving stock (Eq, Generic, Show)
    deriving (Semigroup) via Generically Stats


stat :: Double -> Stats
stat x = Stats (Sum 1) (Sum x) (Min x) (Max x)


-- The observations half of a report: the observation lanes, keyed by bare name (the
-- path is the map key). This is the only half 'reduce' can fill; a sampler cannot reach
-- it.
data Obs = Obs
    { goldens :: MonoidalMap Text (Set.Set Text)
    , checks :: MonoidalMap Text All
    , counts :: MonoidalMap Text (Sum Int)
    }
    deriving stock (Eq, Generic, Show)
    deriving (Monoid, Semigroup) via Generically Obs


-- The measurements half of a report: the per-region resources as plain fields (@Stats@
-- has no identity, so 'timing' is @Maybe Stats@). This is the only half a 'Sampler' can
-- fill.
data Res = Res
    { timing :: Maybe Stats -- this region's wall-clock
    , bytes :: Sum Int -- this region's allocation
    }
    deriving stock (Eq, Generic, Show)
    deriving (Monoid, Semigroup) via Generically Res


-- The whole observe lane: a total, path-free function filling only the 'observations'
-- half.
reduce :: Signal -> Obs
reduce (Golden k t) = mempty {goldens = MMap.singleton k (Set.singleton t)}
reduce (Check name ok) = mempty {checks = MMap.singleton name (All ok)}
reduce (Tally name i) = mempty {counts = MMap.singleton name (Sum i)}


-- The samplers name only the resource they fold; the framework's @record@ callback
-- files it at the current region. 'gauge' records on exit, so a throwing region still
-- reports its time and bytes.
timeSampler :: (IOE :> es) => Sampler es Res
timeSampler = gauge (liftIO getMonotonicTime) \t0 t1 -> mempty {timing = Just (stat (t1 - t0))}


allocsSampler :: (IOE :> es) => Sampler es Res
allocsSampler = gauge (liftIO getAllocationCounter) \a0 a1 -> mempty {bytes = Sum (fromIntegral (a0 - a1))}
