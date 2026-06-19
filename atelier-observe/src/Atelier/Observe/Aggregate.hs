-- | The hierarchical-rollup harvest for "Atelier.Observe": a 'Region' trie of two-laned 'Report's, keyed
-- by trace identity into 'Traces', and the 'collecting' 'Consumer' that builds it from a 'Moment'
-- stream. This is /one/ way to summarize a run — the right one when the run is a tree of nested
-- regions and you want per-region, prefix, and whole-run rollups. A flat event log, an order-
-- sensitive causal check, or a streaming exporter wants none of it and stays on the core
-- combinators ('foldMoments'\/'eachMoment') alone.
--
-- It lives apart from the core precisely because it is a policy, not machinery: every definition
-- here is a pure function of the public 'Moment' stream — @'collecting' reduce = 'foldMoments'
-- ('collectMoment' reduce)@, and the trie types touch no discharge internals — so the core never
-- depends on it, and a domain pulls it in only when its runs are hierarchical.
module Atelier.Observe.Aggregate
    ( -- * The harvest
      Report (..)
    , Region (..)
    , Traces
    , reportAt
    , subtreeAt
    , cumulative
    , rollUp
    , traceOf
    , collapse
    , digest

      -- * The collecting consumer
    , collecting
    , collectMoment
    ) where

import Control.Comonad (Comonad (..))
import Data.Map.Monoidal (MonoidalMap)
import GHC.Generics (Generically (..))

import Data.Map.Monoidal qualified as MMap

import Atelier.Observe (Consumer, Moment (..), MomentCtx (MomentCtx), Path, foldMoments)


-- | Everything recorded at one region, split into two write-isolated halves: 'observations'
-- holds what a 'Atelier.Observe.Tap' emitted (through the reducer), 'measurements' holds what the
-- 'Atelier.Observe.Sampler's read. The halves merge field-wise as a 'Region' coalesces.
data Report o s = Report {observations :: o, measurements :: s}
    deriving stock (Eq, Generic, Show)
    deriving (Monoid, Semigroup) via Generically (Report o s)


-- | A region trie: each node holds a payload @a@ filed /exactly/ at it ('here') and its
-- 'children', keyed one region label deep. A region only passed through on the way to something
-- deeper survives as a spine node with @'here' = 'mempty'@. The recursive 'Monoid' merges 'here'
-- field-wise and unions 'children', recursing on collision — the same coalescing the old flat
-- map's monoid did, but comparing single labels rather than whole paths.
--
-- The payload is the last parameter, so the derived 'Functor', 'Foldable', and 'Traversable'
-- range over /every node's payload/ with the tree intact: 'fmap' projects a lane across all
-- regions, 'fold' rolls the whole tree up, 'foldMap'\/'toList' answer cross-cutting queries, and
-- 'traverse' runs an effect per node. A run's harvest is a @'Region' r ('Report' o s)@.
data Region r a = Region
    { here :: a
    , children :: MonoidalMap r (Region r a)
    }
    deriving stock (Eq, Foldable, Functor, Generic, Show, Traversable)


instance (Ord r, Semigroup a) => Semigroup (Region r a) where
    Region h1 c1 <> Region h2 c2 = Region (h1 <> h2) (c1 <> c2)


instance (Monoid a, Ord r) => Monoid (Region r a) where
    mempty = Region mempty mempty


-- A 'Region' is the cofree comonad over @'MonoidalMap' r@ — @'here'@ extracts the node's payload,
-- and @'duplicate'@ relabels every node with the subtree rooted at it. That is what 'cumulative'
-- exploits: 'extend' a whole-subtree fold over the tree in one pass.
instance Comonad (Region r) where
    extract = here
    duplicate node@(Region _ cs) = Region node (fmap duplicate cs)


-- | The whole harvest: each trace's 'Region' trie of 'Report's, keyed by the optional identity
-- set with a 'Atelier.Observe.Tap'. The rootless key 'Nothing' collects whatever was observed outside any
-- trace.
type Traces i r o s = MonoidalMap (Maybe i) (Region r (Report o s))


-- | The test-runner consumer: fold the stream into a 'Traces'. @reduce@ says what each
-- observation contributes to its region's 'observations' half; each 'Atelier.Observe.Sampler' reading
-- fills the 'measurements' half. The signal moments — entry, exit, and failure — all reduce the
-- same way into their region's report, so they share one arm; only 'Measured' fills the other half.
-- The two lanes write-isolate by construction. @'observe' ('collecting' reduce) plan prog@ harvests
-- a run.
--
-- A single report is placed with 'singletonPath' — a spine of mempty ancestor nodes down to the
-- region that observed it — and the recursive 'Region' monoid coalesces the lot.
collecting
    :: (Monoid o, Monoid s, Ord i, Ord r)
    => (e -> o)
    -> Consumer es i r e s (Traces i r o s)
collecting reduce = foldMoments (collectMoment reduce)


-- | What one 'Moment' contributes to a 'Traces' harvest — the fold inside
-- 'collecting', exposed for 'Atelier.Observe.observeInto' (which needs the contribution function, not a
-- packaged 'Consumer'). @'collecting' reduce = 'foldMoments' ('collectMoment' reduce)@.
collectMoment :: (Monoid o, Monoid s, Ord r) => (e -> o) -> Moment i r e s -> Traces i r o s
collectMoment reduce = \case
    Entered ctx _ es -> fileSignals ctx es
    Exited ctx es -> fileSignals ctx es
    Failed ctx es _ -> fileSignals ctx es
    Measured ctx s -> fileAt ctx (Report mempty s)
  where
    -- Reduce a boundary's signals into its region's observations half.
    fileSignals ctx es = fileAt ctx (Report (foldMap reduce es) mempty)
    -- File a report under the ambient identity (outer key) and down the given path (the trie).
    fileAt (MomentCtx mid path _ _ _) = MMap.singleton mid . singletonPath path


-- A spine of mempty ancestor nodes down to a leaf holding the payload; the payload sits at the
-- root for the empty path (an observation made outside every scope).
singletonPath :: (Monoid a, Ord r) => Path r -> a -> Region r a
singletonPath path x =
    foldr (\r child -> Region mempty (MMap.singleton r child)) (Region x mempty) path


-- | The subtree rooted at a path, or the empty 'Region' if nothing reached it. This is the
-- prefix query the flat map made expensive: "everything under @path@" is a subtree, not a scan.
-- Roll it up with 'fold': @'fold' ('subtreeAt' path t)@ aggregates every payload beneath @path@.
subtreeAt :: (Monoid a, Ord r) => Path r -> Region r a -> Region r a
subtreeAt [] reg = reg
subtreeAt (r : rs) reg = maybe mempty (subtreeAt rs) (MMap.lookup r (children reg))


-- | The payload filed /exactly/ at a path, or 'mempty' if nothing reached it — the 'here' of the
-- subtree at that path. Does /not/ aggregate descendants; use @'fold' . 'subtreeAt'@ for that.
reportAt :: (Monoid a, Ord r) => Path r -> Region r a -> a
reportAt path = here . subtreeAt path


-- | Relabel every node with the 'fold' of its /own/ subtree — the comonadic @'extend' 'fold'@.
-- One pass turns the per-region payloads into cumulative rollups: where 'fold' gives only the
-- root's total, 'cumulative' gives every node's, the shape a flamegraph or a tail-based sampler
-- reads. The tree's structure is untouched; only the payloads change.
--
-- This rolls up /every/ payload, so it is correct only when each node's payload is its own
-- (exclusive) contribution — true of the observation lane, but __not__ the measurement lane, which
-- a 'Atelier.Observe.Sampler' fills inclusively (see 'Atelier.Observe.gauge'). On a harvested @'Report' o s@
-- trie use 'rollUp', which rolls the observations and leaves the already-inclusive measurements be.
cumulative :: (Monoid a) => Region r a -> Region r a
cumulative = extend fold


-- | The two-lane cumulative rollup for a harvested 'Report' trie. The observation lane is
-- per-region (exclusive), so it rolls up like 'cumulative': each node gains the 'fold' of its
-- subtree's 'observations'. The measurement lane is /already inclusive/ — a 'Atelier.Observe.Sampler'
-- brackets a region's whole body, nested regions included (see 'Atelier.Observe.gauge') — so each node
-- keeps the reading it took; re-summing it down the tree, as plain 'cumulative' would, double-counts
-- every nested region into its ancestors. The tree's structure is untouched.
rollUp :: (Monoid o) => Region r (Report o s) -> Region r (Report o s)
rollUp = extend \sub ->
    Report
        { observations = foldMap observations sub
        , measurements = measurements (extract sub)
        }


-- | The 'Region' filed under one trace identity, or the empty trie if nothing reached it.
traceOf :: (Monoid o, Monoid s, Ord i, Ord r) => Maybe i -> Traces i r o s -> Region r (Report o s)
traceOf i = fromMaybe mempty . MMap.lookup i


-- | Forget the trace dimension: merge every trace's trie into one.
collapse :: (Monoid o, Monoid s, Ord r) => Traces i r o s -> Region r (Report o s)
collapse = mconcat . MMap.elems


-- | The whole run as one merged 'Report' — every trace, every region coalesced. The flat,
-- region-blind summary: @('digest' traces).'observations'@ is every signal the run reduced,
-- @.'measurements'@ every sampler reading totalled. @'digest' = 'fold' . 'collapse'@; reach for it
-- when a cross-cutting total is all you want and the trie structure is noise. For per-region or
-- prefix views keep the trie and use 'reportAt' \/ 'subtreeAt' \/ 'fold'.
digest :: (Monoid o, Monoid s, Ord r) => Traces i r o s -> Report o s
digest = fold . collapse
