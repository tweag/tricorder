-- | An OpenTelemetry exporter for "Atelier.Observe": a 'Consumer' that folds a run's 'Moment' stream
-- into OpenTelemetry spans through a 'OT.Tracer'. It is the streaming counterpart to the trie
-- harvest in "Atelier.Observe.Aggregate" — where that summarizes a finished run, this emits spans
-- live as the run unfolds.
--
-- The mapping:
--
--   * 'Entered' opens a span. Its parent is the span of the enclosing region (same trace identity,
--     one shorter 'Path'); a region with no enclosing span starts a fresh trace. The entry signals
--     become span attributes, and the 'Atelier.Observe.linkedTo' targets become span /links/ to the
--     root spans of those traces (resolved best-effort: a link to a trace not yet started is dropped).
--   * 'Exited' ends the span with 'OT.Ok' status, its exit signals added as attributes.
--   * 'Failed' ends the span with 'OT.Error' status, the exception recorded ('OT.recordException')
--     and its failure signals added as attributes.
--   * 'Measured' adds a span event carrying the sampler reading.
--
-- The signal and measurement lanes are polymorphic, so the caller supplies a 'Render' saying how a
-- region path becomes a span name and how each lane becomes attributes. The consumer's harvest is
-- @()@: spans are the side effect. Bracketed by 'Atelier.Observe.observe', its teardown ends any
-- span left open by a short-circuit, so a failing run still flushes well-formed spans.
module Atelier.Observe.OpenTelemetry
    ( exporting
    , Render (..)
    , simpleRender
    ) where

import Atelier.Observe (Consumer, Link (..), Moment (..), MomentCtx (MomentCtx), Path, consumer)
import Data.List (minimumBy)
import Effectful (IOE)

import Data.HashMap.Strict qualified as HM
import Data.Map.Strict qualified as Map
import Data.Text qualified as Text
import OpenTelemetry.Context qualified as Ctx
import OpenTelemetry.Trace.Core qualified as OT


-- | How to render the polymorphic lanes of a 'Moment' into the OpenTelemetry vocabulary: the region
-- 'Path' into a span name, and each signal (@e@) and sampler reading (@s@) into attributes. A span's
-- trace identity (@i@) can also contribute attributes, for correlation.
data Render i r e s = Render
    { renderName :: Path r -> Text
    -- ^ the span name for a region, from its full path
    , renderKind :: Path r -> OT.SpanKind
    -- ^ the 'OT.SpanKind' for a region (e.g. 'OT.Server' / 'OT.Client' / 'OT.Producer' /
    -- 'OT.Consumer'); drives backend topology and span metrics. 'OT.Internal' if you have no better.
    , renderSignal :: e -> [(Text, OT.Attribute)]
    -- ^ attributes contributed by one signal (the @e@ lane), added on enter, leave, and failure
    , renderMeasurement :: s -> [(Text, OT.Attribute)]
    -- ^ attributes for a sampler reading (the @s@ lane), attached as a span event
    , renderTraceId :: i -> [(Text, OT.Attribute)]
    -- ^ attributes derived from a span's trace identity, for correlation
    }


-- | A 'Render' for the common case: the span name is the region's /leaf/ label (the OpenTelemetry
-- convention — hierarchy is carried by parent\/child links, not baked into the name, and leaf naming
-- keeps per-operation aggregation intact), every span is 'OT.Internal', and no attributes are
-- emitted. Takes the label renderer explicitly (@'simpleRender' 'id'@ for @r ~ Text@,
-- @'simpleRender' (Text.pack . show)@ otherwise). Layer the rest on with record updates, e.g.
-- @('simpleRender' id) {renderSignal = \\sig -> …}@.
simpleRender :: (r -> Text) -> Render i r e s
simpleRender label =
    Render
        { renderName = maybe "root" label . viaNonEmpty last
        , renderKind = const OT.Internal
        , renderSignal = const []
        , renderMeasurement = const []
        , renderTraceId = const []
        }


-- A tiny pure bounded LRU map: at most 'lruCap' entries, evicting the least-recently inserted-or-read
-- when full. Recency is a monotonic tick stamped on insert and refreshed on a read hit. It backs the
-- exporter's 'regionCtxs', whose live cardinality (fork-site parents currently linked to) is small.
data Lru k v = Lru
    { lruCap :: Int
    , lruTick :: Word64
    , lruItems :: Map.Map k (Word64, v)
    }


emptyLru :: Int -> Lru k v
emptyLru cap = Lru cap 0 Map.empty


insertLru :: (Ord k) => k -> v -> Lru k v -> Lru k v
insertLru k v (Lru cap t items) = evict (Lru cap (t + 1) (Map.insert k (t, v) items))
  where
    evict lru
        | Map.size lru.lruItems <= lru.lruCap = lru
        | otherwise = lru {lruItems = Map.delete (leastRecent lru.lruItems) lru.lruItems}
    leastRecent = fst . minimumBy (comparing (fst . snd)) . Map.toList


-- Look a key up, refreshing its recency on a hit so a still-live fork-site parent is not evicted.
lookupLru :: (Ord k) => k -> Lru k v -> (Maybe v, Lru k v)
lookupLru k lru = case Map.lookup k lru.lruItems of
    Nothing -> (Nothing, lru)
    Just (_, v) -> (Just v, lru {lruTick = lru.lruTick + 1, lruItems = Map.insert k (lru.lruTick, v) lru.lruItems})


-- The exporter's fold state. 'openSpans' holds the spans currently open, keyed by the firing thread
-- id alongside the region coordinate so concurrent same-path regions (forked siblings) stay distinct
-- and a child thread's regions never nest under the parent's. 'rootCtxs' keeps each trace's root span
-- context, for 'LinkTrace' (root-granularity) resolution; 'regionCtxs' keeps every region's own span
-- context past its exit, for 'LinkRegion' (region-granularity) resolution — bounded, since a
-- long-running run would otherwise accumulate one entry per distinct region coordinate.
data Live i r = Live
    { openSpans :: Map.Map (Word64, Maybe i, Path r) OT.Span
    , rootCtxs :: Map.Map i OT.SpanContext
    , regionCtxs :: Lru (Maybe i, Path r) OT.SpanContext
    }


-- | Fold a 'Moment' stream into OpenTelemetry spans through the given 'OT.Tracer'. Pair it with
-- 'Atelier.Observe.observe' (or fan out alongside another consumer with 'Atelier.Observe.teeC'):
--
-- @
-- (a, ()) <- 'Atelier.Observe.observe' ('exporting' tracer render) plan program
-- @
--
-- The 'OT.Tracer' comes from any provider — "Atelier.Observe.OpenTelemetry.Provider" for an OTLP one,
-- or an in-memory provider in tests.
exporting
    :: (IOE :> es, Ord i, Ord r)
    => OT.Tracer
    -> Render i r e s
    -> Consumer es i r e s ()
exporting tracer render = consumer (pure (Live Map.empty Map.empty (emptyLru regionCtxBound))) step stop
  where
    step live = \case
        Entered (MomentCtx mid path scopeSigs _ _ tid) links entrySigs -> liftIO do
            let key = (tid, mid, path)
                parent = Map.lookup (tid, mid, parentPath path) live.openSpans
                ctx = maybe Ctx.empty (`Ctx.insertSpan` Ctx.empty) parent
                (linkCtxs, regionCtxs') = resolveLinks live.rootCtxs live.regionCtxs links
                -- scope signals in effect here (this region's plus every enclosing one) attach to
                -- every span in the subtree, so a whole subtree can be filtered/attributed by them
                attrs =
                    HM.fromList
                        ( concatMap (renderSignal render) entrySigs
                            <> concatMap (renderSignal render) scopeSigs
                            <> foldMap (renderTraceId render) mid
                        )
                args =
                    OT.defaultSpanArguments
                        { OT.kind = renderKind render path
                        , OT.attributes = attrs
                        , OT.links =
                            map (\c -> OT.NewLink {OT.linkContext = c, OT.linkAttributes = HM.empty}) linkCtxs
                        }
            sp <- OT.createSpanWithoutCallStack tracer ctx (renderName render path) args
            sctx <- OT.getSpanContext sp
            -- a region with no enclosing span is a trace root; remember its context for LinkTrace
            let roots' = case mid of
                    Just i | isNothing parent -> Map.insert i sctx live.rootCtxs
                    _ -> live.rootCtxs
                -- every region's context is kept (past its exit, bounded) for LinkRegion
                regionCtxs'' = insertLru (mid, path) sctx regionCtxs'
            pure live {openSpans = Map.insert key sp live.openSpans, rootCtxs = roots', regionCtxs = regionCtxs''}
        Exited (MomentCtx mid path _ _ _ tid) exitSigs -> liftIO do
            let key = (tid, mid, path)
            onSpan live key \sp -> do
                OT.addAttributes sp (HM.fromList (concatMap (renderSignal render) exitSigs))
                OT.setStatus sp OT.Ok
                OT.endSpan sp Nothing
            pure (close key live)
        Failed (MomentCtx mid path _ _ _ tid) failSigs ex -> liftIO do
            let key = (tid, mid, path)
            onSpan live key \sp -> do
                OT.addAttributes sp (HM.fromList (concatMap (renderSignal render) failSigs))
                OT.recordException sp HM.empty Nothing ex
                OT.setStatus sp (OT.Error (Text.pack (show ex)))
                OT.endSpan sp Nothing
            pure (close key live)
        Measured (MomentCtx mid path _ _ _ tid) reading -> liftIO do
            onSpan live (tid, mid, path) \sp ->
                OT.addEvent
                    sp
                    OT.NewEvent
                        { OT.newEventName = "measurement"
                        , OT.newEventAttributes = HM.fromList (renderMeasurement render reading)
                        , OT.newEventTimestamp = Nothing
                        }
            pure live
    -- teardown (the failure path included): end any span a short-circuit left open, so the run still
    -- flushes well-formed spans.
    stop live = liftIO (forM_ (Map.elems live.openSpans) \sp -> OT.endSpan sp Nothing)

    onSpan live key act = maybe (pure ()) act (Map.lookup key live.openSpans)
    close key live = live {openSpans = Map.delete key live.openSpans}

    -- resolve each link target to a span context: LinkTrace to its trace's root (rootCtxs), LinkRegion
    -- to the exact region's own span (regionCtxs, refreshing recency); unresolved targets are dropped.
    resolveLinks rootCtxs = go []
      where
        go acc lru [] = (reverse acc, lru)
        go acc lru (LinkTrace i : rest) = go (maybe acc (: acc) (Map.lookup i rootCtxs)) lru rest
        go acc lru (LinkRegion m p : rest) = case lookupLru (m, p) lru of
            (Just c, lru') -> go (c : acc) lru' rest
            (Nothing, lru') -> go acc lru' rest


-- How many distinct region coordinates the exporter keeps span contexts for, to resolve region-
-- granular links after the region has exited. Sized for "live fork-site parents", which is small.
regionCtxBound :: Int
regionCtxBound = 4096


-- The enclosing region's path: this region's path with its own (innermost) label dropped.
parentPath :: Path r -> Path r
parentPath [] = []
parentPath [_] = []
parentPath (r : rs) = r : parentPath rs
