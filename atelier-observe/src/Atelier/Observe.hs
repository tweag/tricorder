-- | Side-channel observation of an oblivious Effectful program. The library separates instrumenting
-- a program from summarizing the run, in three stages:
--
--   * __Produce__ — a 'Plan' instruments an oblivious program: 'Tap's interpose on its effects to
--     emit signals (the @e@ lane) on each region boundary, 'Sampler's bracket each region to read a
--     resource (the @s@ lane). This is the only part that can't be a consumer: a consumer is a
--     fold, with no handle on the program, so it can't bracket the body to read a clock.
--   * __Stream__ — discharging the plan turns the run into a 'Moment' stream
--     ('Entered'\/'Exited'\/'Failed'\/'Measured'), the one artifact at the center.
--   * __Fold__ — a 'Consumer' is a left fold over that stream into a harvest; what the harvest /is/
--     is entirely the consumer's business. This module supplies the generic builders ('foldMoments',
--     'eachMoment', 'teeC'); "Atelier.Observe.Aggregate" supplies a 'collecting' consumer for the
--     hierarchical case (a 'Region' trie of two-laned 'Report's). That summary is a /policy/, kept
--     out of the core: a flat event log, an order-sensitive causal check, or an OpenTelemetry
--     exporter wants nothing to do with it, and pulls in none of it.
--
-- The core keeps two write-isolated signal lanes, a @'Tap'@ '<>' that merges instrumentation without
-- nesting the region, and an exception-safe discharge that captures an operation's input on entry so
-- it survives a throw. A __'Plan'__ is program-side instrumentation; a __'Consumer'__ is a left fold
-- over the 'Moment' stream; __'observe'__ threads one consumer over a plan, returning @(a, harvest)@
-- beside the program's untouched result.
module Atelier.Observe
    ( -- * Instrumenting an effect
      Tap (..)
    , watch
    , tracedBy
    , linkedTo
    , entering
    , leaving
    , failing
    , nesting
    , rerooting
    , OverActions
    , Observes
    , Observing

      -- * Scope cursor & rerooting
    , Obs
    , Observed
    , currentScope
    , rerootLinked

      -- * The plan
    , Plan
    , tap
    , interposing
    , sampling

      -- * Consumers
    , Consumer
    , consumer
    , foldMoments
    , eachMoment
    , teeC

      -- * Measurements
    , Sampler (..)
    , gauge

      -- * Moments
    , Moment (..)
    , MomentCtx (..)
    , Link (..)
    , Path

      -- * Discharge
    , observe
    , observeConc
    , observeInto
    , silent
    ) where

import Control.Foldl (FoldM (..))
import Data.IORef (atomicModifyIORef', newIORef)
import Effectful (Dispatch (Dynamic), DispatchOf, Effect, IOE, Subset, UnliftStrategy, inject, raise)
import Effectful.Concurrent (Concurrent, forkIO, myThreadId)
import Effectful.Concurrent.Chan (Chan, newChan, readChan, writeChan)
import Effectful.Concurrent.MVar (MVar, newEmptyMVar, putMVar, readMVar)
import Effectful.Dispatch.Dynamic (LocalEnv, interpose, interpret, localLend, localSeqUnlift, passthrough)
import Effectful.Exception (bracket, catch, onException, throwIO)
import Effectful.Reader.Static (Reader, ask, local, runReader)
import Effectful.State.Static.Local (State, get, modify, put, runState)
import Effectful.TH (makeEffect)
import GHC.Clock (getMonotonicTimeNSec)
import GHC.Conc.Sync (fromThreadId)
import Prelude hiding (seq, trace)

import Control.Foldl qualified as L


-- | The ambient region path: the stack of enclosing 'Scope' labels, outermost first. A plain list,
-- so consumers can pattern-match it, key a map on it, and write it as a literal. The discharge
-- accumulates it as an @'Endo' [r]@ difference list (O(1) to extend per nesting level), materializing
-- to this @[r]@ once per 'Moment'.
type Path r = [r]


-- | A cross-link target, surfaced on 'Entered' for an exporter to resolve to a span and emit a
-- link. Two granularities, composing freely:
--
--   * 'LinkTrace' names a whole /trace/ by its identity @i@ — resolved to that trace's __root__
--     span (root-granularity). The everyday pub/sub case: a listener links to the publisher's
--     trace by an event-derived id. Set on a 'Tap' with 'linkedTo'.
--   * 'LinkRegion' names one __exact region__ by its @(identity, path)@ coordinate — resolved to
--     that region's own span (region-granularity). The 'Conc' fork case: a forked child links back
--     to the precise spawn site, not merely its enclosing trace. Produced by 'rerootLinked' (the
--     reroot primitive behind the 'rerooting' tap), which reads the coordinate from 'currentScope'.
data Link i r
    = LinkTrace i
    | LinkRegion (Maybe i) (Path r)
    deriving stock (Eq, Show)


-- The one internal observation effect. A 'Scope' carries its link targets and entry signals up
-- front, a function from a thrown exception to its failure signals, and a body that yields its exit
-- signals alongside the result (so the discharge can attach them to 'Exited'); a 'Trace' sets the
-- ambient identity. A 'Tap' is the only producer, a discharge the only consumer (internal).
data Obs i r e :: Effect where
    Scope :: r -> [Link i r] -> [e] -> (SomeException -> [e]) -> m (a, [e]) -> Obs i r e m a
    Trace :: i -> m a -> Obs i r e m a
    -- Read the caller's scope cursor — the ambient trace identity and region path active right
    -- here — answered by a discharge from its two Readers. The seam an instrumentation-layer
    -- wrapper uses to capture where work was spawned, for linking the spawned action back to it.
    CurrentScope :: Obs i r e m (Maybe i, Path r)
    -- Run an action as a fresh trace root — ambient identity reset to 'Nothing', region path reset
    -- to empty — whose first region additionally links to the given targets. The seam 'rerootLinked'
    -- uses so spawned work starts its own trace (no nesting under, and no unbounded growth of, the
    -- spawner's) yet still links back to the spawn site.
    Reroot :: [Link i r] -> m a -> Obs i r e m a


makeEffect ''Obs


-- The effect row an instrumented program runs in: the internal 'Obs' over the program's own
-- effects @es@ (internal).
type Observing es i r e = Obs i r e : es


-- | What 'tap' asks of each oblivious effect @eff@ it bundles: that @eff@ is a dynamically
-- dispatched effect reachable through the instrumented row. Give an instrumenting wrapper one
-- 'Observes' per effect it taps, e.g. @('Observes' es Foo i r e, 'Observes' es Bar i r e) =>
-- 'Plan' es i r e s@ — the row stays unnamed.
type Observes es eff i r e = (DispatchOf eff ~ Dynamic, eff :> Observing es i r e)


-- | The constraint that the row @es@ is the instrumented row of an observed run — it carries the
-- internal observation effect. An instrumentation-layer helper that reads or restructures the
-- ambient scope ('currentScope', and 'rerootLinked' built on it) asks for this; @es@
-- stays otherwise unconstrained. Only code in the instrumented layer (taps and interposes installed
-- by a 'Plan', not the oblivious base interpreters beneath it) satisfies it.
type Observed es i r e = Obs i r e :> es


-- | Everything done to one oblivious effect @eff@, as a single descriptor:
--
--   * 'region' — which region label each operation files under (the 'Scope'), or 'Nothing' to open
--     no region around the operation itself (the higher-order case, where the regions are around the
--     /carried/ actions instead — see 'wrapping');
--   * 'under' — the optional trace each operation runs under ('Nothing' inherits the ambient
--     trace; 'Just' names one, e.g. a request id carried in the operation);
--   * 'linking' — the trace identities this operation's region links to, surfaced on 'Entered' for
--     an exporter to emit cross-trace links ('[]' links to none);
--   * 'onEnter' — signals from the operation's input, fired into 'Entered' before the work;
--   * 'onLeave' — signals from input and result, fired into 'Exited' after the work;
--   * 'onError' — signals from input and the thrown exception, fired into 'Failed' when the work
--     throws ('onLeave' never runs on that path — there is no result to derive it from).
--
-- Build the first-order cases with 'watch' and the 'entering'\/'leaving'\/'tracedBy'\/'linkedTo'
-- setters (or record updates); build the higher-order cases — instrumenting an operation's /carried/
-- actions rather than the operation itself — with 'nesting' and 'rerooting'. 'tap' applies it all in
-- one interpose, fixing the nesting trace ⊃ region ⊃ signals.
data Tap eff i r e = Tap
    { region :: forall localEs b. eff (Eff localEs) b -> Maybe r
    , under :: forall localEs b. eff (Eff localEs) b -> Maybe i
    , linking :: forall localEs b. eff (Eff localEs) b -> [i]
    , onEnter :: forall localEs b. eff (Eff localEs) b -> [e]
    , onLeave :: forall localEs b. eff (Eff localEs) b -> b -> [e]
    , onError :: forall localEs b. eff (Eff localEs) b -> SomeException -> [e]
    , wrapping :: Wrapping eff i r e
    }


-- | The per-effect half of a higher-order 'Tap': thread the framework-supplied @wrap@ through each
-- /action/ an operation carries, leaving the operations it can't (or shouldn't) instrument
-- untouched. For @'Atelier.Effects.Conc.Conc'@ this is @\\wrap -> \\case Fork a -> Fork (wrap a); …;
-- o -> o@. It is the __only__ effect-specific knowledge a higher-order tap needs — the wrapper
-- itself (open a region, reroot) is built once by 'instrument', so the parametric @wrap@ cannot read
-- a carried action's result (its type is hidden); derive result signals from the /operation/ via the
-- first-order facet instead. A callback-shaped operation threads the wrap under its lambda:
-- @\\wrap -> \\case WithConn p f -> WithConn p (\\h -> wrap (f h))@.
type OverActions eff =
    forall localEs b. (forall x. Eff localEs x -> Eff localEs x) -> eff (Eff localEs) b -> eff (Eff localEs) b


-- The higher-order facet of a 'Tap': whether, and how, to wrap the actions an operation carries.
-- 'NoWrap' is the first-order case (the op's own run is the only work site). 'Reroot' runs each
-- carried action as a fresh trace linked back to the fork site ('rerootLinked'); 'Nest' runs each as a
-- region nested under the current scope, labelled from the operation. Both carry the
-- 'UnliftStrategy' for crossing into the carried action's row (e.g. @concStrat@ for forks).
data Wrapping eff i r e
    = NoWrap
    | WrapReroot UnliftStrategy (OverActions eff)
    | WrapNest UnliftStrategy (forall localEs b. eff (Eff localEs) b -> r) (OverActions eff)


-- | Merge two taps on the /same/ effect into one. The left tap's 'region' and 'under' classify the
-- operation — they are assumed to agree, since both instrument the same seam — and the three signal
-- functions concatenate, so every layer's 'onEnter'\/'onLeave'\/'onError' fires.
--
-- This is how you observe one region several ways /without nesting it/: @'tap' (seam '<>' checkA
-- '<>' checkB)@ installs a __single__ interpose, so the operation opens __one__ 'Scope' carrying
-- all the signals. Contrast @'tap' seam '<>' 'tap' checkA@, which installs two interposes — the
-- second 'passthrough's through the first, so the region nests inside itself. The 'Tap' @'<>'@
-- means \"more observations on the same region\"; the 'Plan' @'<>'@ means \"observe another
-- effect\".
--
-- There is no 'Monoid': a tap must always name a 'region', and @r@ has no identity.
instance Semigroup (Tap eff i r e) where
    t1 <> t2 =
        Tap
            { region = region t1
            , under = under t1
            , linking = \op -> linking t1 op <> linking t2 op
            , onEnter = \op -> onEnter t1 op <> onEnter t2 op
            , onLeave = \op b -> onLeave t1 op b <> onLeave t2 op b
            , onError = \op e -> onError t1 op e <> onError t2 op e
            , -- the first wrapping wins: merging is for layering signals on a first-order region,
              -- where both sides are 'NoWrap'; a higher-order facet is not something one '<>'s onto.
              wrapping = case wrapping t1 of NoWrap -> wrapping t2; w -> w
            }


-- | A 'Tap' that only files each operation under a region — no trace, no signals. The defaulting
-- constructor: layer on the parts you want with 'entering'\/'leaving'\/'tracedBy' (or record
-- updates), e.g. @watch (\\case Lower _ -> LowerOp) & leaving (\\(Lower _) (IR t) -> [Golden "ir" t])@.
watch :: (forall localEs b. eff (Eff localEs) b -> r) -> Tap eff i r e
watch label =
    Tap
        { region = \op -> Just (label op)
        , under = \_ -> Nothing
        , linking = \_ -> []
        , onEnter = \_ -> []
        , onLeave = \_ _ -> []
        , onError = \_ _ -> []
        , wrapping = NoWrap
        }


-- | Set the trace each operation runs under: @'watch' label & 'tracedBy' (\\op -> …)@. The setter
-- form of the 'under' field, for building a 'Tap' left-to-right without brace syntax.
tracedBy :: (forall localEs b. eff (Eff localEs) b -> Maybe i) -> Tap eff i r e -> Tap eff i r e
tracedBy f t = t {under = f}


-- | Set the trace identities each operation's region links to: @'watch' label & 'linkedTo' (\\op -> …)@.
-- The setter form of the 'linking' field. An exporter that maps regions to spans (e.g. OpenTelemetry)
-- may emit a cross-trace link to each named trace; consumers that ignore links are unaffected.
linkedTo :: (forall localEs b. eff (Eff localEs) b -> [i]) -> Tap eff i r e -> Tap eff i r e
linkedTo f t = t {linking = f}


-- | Set the entry signals derived from an operation's input: @'watch' label & 'entering' (\\op -> …)@.
-- The setter form of the 'onEnter' field.
entering :: (forall localEs b. eff (Eff localEs) b -> [e]) -> Tap eff i r e -> Tap eff i r e
entering f t = t {onEnter = f}


-- | Set the exit signals derived from an operation's input and result:
-- @'watch' label & 'leaving' (\\op result -> …)@. The setter form of the 'onLeave' field — the
-- everyday case, since most signals are result-derived.
leaving :: (forall localEs b. eff (Eff localEs) b -> b -> [e]) -> Tap eff i r e -> Tap eff i r e
leaving f t = t {onLeave = f}


-- | Set the failure signals derived from an operation's input and the exception it threw:
-- @'watch' label & 'failing' (\\op e -> …)@. The setter form of the 'onError' field.
failing :: (forall localEs b. eff (Eff localEs) b -> SomeException -> [e]) -> Tap eff i r e -> Tap eff i r e
failing f t = t {onError = f}


-- A higher-order 'Tap' opens no region around the operation itself — its regions sit on the carried
-- actions — so every first-order projection defaults to empty; only the 'wrapping' facet is set.
higherOrder :: Wrapping eff i r e -> Tap eff i r e
higherOrder w =
    Tap
        { region = \_ -> Nothing
        , under = \_ -> Nothing
        , linking = \_ -> []
        , onEnter = \_ -> []
        , onLeave = \_ _ -> []
        , onError = \_ _ -> []
        , wrapping = w
        }


-- | A higher-order 'Tap' that runs each action an operation carries as a region __nested__ under the
-- scope active where the operation ran, labelled by the operation. The bracket\/scope case: an
-- @X -> m a -> Eff m a@ operation (e.g. a timeout, a namespaced log block) whose body should become
-- a child region in the same trace. The 'OverActions' mapping says where the actions are; the
-- 'UnliftStrategy' crosses into their row (@SeqUnlift@ for the usual inline body). Contrast
-- 'rerooting', which starts the action's region in a fresh trace.
nesting
    :: UnliftStrategy
    -> (forall localEs b. eff (Eff localEs) b -> r)
    -> OverActions eff
    -> Tap eff i r e
nesting strat label overActions = higherOrder (WrapNest strat label overActions)


-- | A higher-order 'Tap' that runs each action an operation carries as a __fresh trace root__ that
-- links back to the scope active where the operation ran (via 'rerootLinked'). The spawn\/detached
-- case: a forked thread (@'Atelier.Effects.Conc.Conc'@), a daemon body, an event delivery — work
-- that should start its own trace rather than nest under (and grow) the spawner's, yet still link to
-- the exact spawn site. The 'OverActions' mapping says where the actions are; the 'UnliftStrategy'
-- crosses into their row (@concStrat@ for forks, so the captured handler survives the new thread).
-- Contrast 'nesting', which keeps the action's region in the current trace.
rerooting :: UnliftStrategy -> OverActions eff -> Tap eff i r e
rerooting strat overActions = higherOrder (WrapReroot strat overActions)


-- Apply a 'Tap' to an oblivious program: interpose on each operation of @eff@, open its region
-- with the entry signals, run it, and hand back the result paired with the exit signals — the
-- result itself unchanged (internal; 'tap' is the only caller).
instrument
    :: forall eff i r e es a
     . (DispatchOf eff ~ Dynamic, eff :> Observing es i r e)
    => Tap eff i r e
    -> Eff (Observing es i r e) a
    -> Eff (Observing es i r e) a
instrument t = interpose \(env :: LocalEnv localEs (Observing es i r e)) (op :: eff (Eff localEs) b) ->
    let
        -- the op-level region (first-order facet): present for 'watch'-built taps, absent ('Nothing')
        -- for higher-order taps, whose regions sit on the carried actions instead. The body yields
        -- @(result, exit signals)@; with no region we just run it and drop the (empty) signals.
        -- A 'Tap' links at root-granularity: each named trace identity becomes a 'LinkTrace' target.
        withRegion body = case region t op of
            Nothing -> fst <$> body
            Just r -> scope r (map LinkTrace (linking t op)) (onEnter t op) (onError t op) body
        withTrace observed = case under t op of
            Nothing -> observed
            Just i -> trace i observed
        leaveWith res = (res, onLeave t op res)
        -- The env-bridge for every higher-order tap, written __once__: lend the discharge's 'Obs'
        -- handler into the carried action's row (so its rerooted\/nested 'Scope' is handled there),
        -- apply the given Obs-level wrap, rewrite the operation's carried actions with it, then
        -- re-dispatch the rewritten operation. The two policies differ only in @obsWrap@.
        runWrapped
            :: UnliftStrategy
            -> OverActions eff
            -> (forall x. Eff (Obs i r e : localEs) x -> Eff (Obs i r e : localEs) x)
            -> Eff (Observing es i r e) (b, [e])
        runWrapped strat overActions obsWrap =
            localLend @'[Obs i r e] env strat \lend ->
                let wrap :: forall x. Eff localEs x -> Eff localEs x
                    wrap a = lend (obsWrap (raise @(Obs i r e) a))
                in  leaveWith <$> passthrough env (overActions wrap op)
    in
        withTrace . withRegion $ case wrapping t of
            NoWrap -> leaveWith <$> passthrough env op
            -- reroot each carried action as a fresh trace linked back to the scope here…
            WrapReroot strat overActions -> runWrapped strat overActions rerootLinked
            -- …or nest each as a region under the current scope, labelled from the operation.
            WrapNest strat label overActions ->
                runWrapped strat overActions \m -> scope (label op) [] [] (const []) ((,[]) <$> m)


-- A program transformer that installs some taps; composes by function composition (internal).
newtype Instrument es = Instrument (forall a. Eff es a -> Eff es a)


instance Semigroup (Instrument es) where
    Instrument f <> Instrument g = Instrument (f . g)


instance Monoid (Instrument es) where
    mempty = Instrument id


-- | The program-side configuration of a run: the taps to install and the 'Sampler' to bracket
-- each region. Assemble with 'tap' and 'sampling', merge with @'<>'@; 'mempty' instruments
-- nothing. It carries no observers and no harvest type — what to do with the 'Moment's a run
-- produces is a 'Consumer', chosen at the discharge.
data Plan es i r e s = Plan (Instrument (Observing es i r e)) (Sampler es s)


instance Semigroup (Plan es i r e s) where
    Plan t1 s1 <> Plan t2 s2 = Plan (t1 <> t2) (s1 <> s2)


instance Monoid (Plan es i r e s) where
    mempty = Plan mempty mempty


-- | A 'Plan' that installs one 'Tap' and nothing else. Merge several with @'<>'@ to observe
-- several effects of one program.
tap
    :: (Observes es eff i r e)
    => Tap eff i r e
    -> Plan es i r e s
tap t = Plan (Instrument (instrument t)) mempty


-- | A 'Plan' that installs a raw instrumentation-layer transformer — an 'interpose' that
-- /restructures/ an effect's operations rather than merely observing them the way a 'tap' does. The
-- escape hatch for restructurings the higher-order taps ('nesting'\/'rerooting') don't express:
-- those wrap the actions an operation /carries/, whereas this can replace an operation wholesale
-- (run a different action in its place). The transformer runs in the observed row 'Observing', so it
-- may use 'currentScope'\/'rerootLinked' and re-dispatch the effect it wraps. Merges with @'<>'@ like
-- any 'Plan'; the transformers compose by function composition.
interposing :: (forall x. Eff (Observing es i r e) x -> Eff (Observing es i r e) x) -> Plan es i r e s
interposing f = Plan (Instrument f) mempty


-- | A 'Plan' that adds a 'Sampler' and nothing else: the resource it folds surfaces as a
-- 'Measured' 'Moment' that a 'Consumer' may handle.
sampling :: Sampler es s -> Plan es i r e s
sampling s = Plan mempty s


-- | What to do with a run's 'Moment' stream: a monadic left fold over the moments in the base row
-- @es@. It is exactly a @'FoldM' ('Eff' es)@, so the structure comes for free — it is an
-- 'Applicative' (combine consumers with 'teeC' \/ 'liftA2', fan out in one pass), a 'Functor' (map
-- the harvest), and a 'Profunctor' (adapt the moment stream with @premap@\/@prefilter@ from
-- "Control.Foldl"). Build the common ones with 'foldMoments' and 'eachMoment'; combine with 'teeC';
-- or use 'consumer' for a bespoke fold. For the hierarchical region rollup, "Atelier.Observe.Aggregate"
-- supplies a 'collecting' consumer built on these same combinators.
--
-- A 'Consumer' is /only/ a fold: it has no handle on the program's continuation or result, so it
-- cannot change what the program computes — it can only accumulate. Its @start@\/@stop@ are
-- bracketed by 'observe', so @stop@ runs (fed the partial accumulator) even when the program
-- throws — the hook for an exporter to flush and release on the failure path.
type Consumer es i r e s h = FoldM (Eff es) (Moment i r e s) h


-- | Build a 'Consumer' from a left fold: @start@ seeds the accumulator (or acquires a resource),
-- @step@ folds each 'Moment' into it (effectfully if it needs the base row), and @stop@ extracts
-- the harvest (or flushes). The accumulator is existential, so it is private to the consumer.
-- (foldl's 'FoldM' takes its fields @step@-first; this keeps the natural start\/step\/stop order.)
consumer
    :: Eff es x
    -> (x -> Moment i r e s -> Eff es x)
    -> (x -> Eff es h)
    -> Consumer es i r e s h
consumer start step stop = FoldM step start stop


-- | A consumer that folds the stream into a monoid by mapping each 'Moment' to a contribution
-- and @'<>'@-ing them in program order. Pure — no effects, so it runs under @runPureEff@. The
-- everyday case: an event log (@'foldMoments' (\\m -> [tag m])@), an aggregate, or the trie
-- consumer in "Atelier.Observe.Aggregate".
foldMoments :: (Monoid w) => (Moment i r e s -> w) -> Consumer es i r e s w
foldMoments f = L.generalize (L.foldMap f id)


-- | A consumer that runs an effect for each 'Moment' and accumulates nothing (harvest @()@).
-- The effect runs in the base row @es@, so this is where an OTel\/analytics sink lives — supply
-- what it needs with a constraint, e.g. @('IOE' ':>' es) => …@ to export. The body's result is
-- unchanged.
eachMoment :: (Moment i r e s -> Eff es ()) -> Consumer es i r e s ()
eachMoment = L.mapM_


-- | Run two consumers in a single pass and pair their harvests — the fan-out combinator, which is
-- just the 'Applicative' product of the two folds. One instrumented run can feed a 'collecting'
-- harvest /and/ an 'eachMoment' exporter at once: @'observe' (harvest \`teeC\` exporter) plan
-- prog@. (Fan out N consumers with 'liftA2'\/'sequenceA' directly.)
teeC :: Consumer es i r e s h1 -> Consumer es i r e s h2 -> Consumer es i r e s (h1, h2)
teeC = liftA2 (,)


-- | Measures a resource (wall-clock, allocation, …) spent in a region. A discharge brackets
-- each region with the sampler and hands it a @record@ callback that files a measurement
-- against the current region, surfacing as a 'Measured' 'Moment'. Polymorphic over the stack it
-- runs on, so one sampler serves every discharge. Compose with @<>@ (nest) and @mempty@.
newtype Sampler es s
    = Sampler (forall esX x. (Subset es esX) => (s -> Eff esX ()) -> Eff esX x -> Eff esX x)


instance Semigroup (Sampler es s) where
    Sampler s1 <> Sampler s2 = Sampler \record act -> s1 record (s2 record act)


instance Monoid (Sampler es s) where
    mempty = Sampler \_ act -> act


-- | Build a 'Sampler' from a gauge: read @probe@ before and after the region and record what the
-- two readings contribute. Bracketed, so a region that throws still reports its measurement.
--
-- The bracket spans the region's /whole body/, nested regions included, so a gauge reading is
-- __inclusive__: a region's measurement covers everything that ran inside it. Aggregate the
-- measurement lane with @rollUp@ (which preserves these inclusive readings), not @cumulative@
-- (which would sum each nested region into its ancestors a second time) — both in "Atelier.Observe.Aggregate".
gauge :: Eff es p -> (p -> p -> s) -> Sampler es s
gauge probe delta = Sampler \record act ->
    bracket (inject probe) (\before -> inject probe >>= record . delta before) (\_ -> act)


-- | The ambient coordinate of a 'Moment', plus the metadata captured at the instant it fired. It
-- factors out the @(mid, path)@ every 'Moment' used to carry — 'mid' the ambient trace identity
-- ('Nothing' outside any trace), 'path' the region 'Path' — and adds three fire-time captures:
-- 'at' (a timestamp), 'seq' (a monotonic counter that recovers program order after a concurrent
-- discharge reorders the stream), and 'tid' (an identifier of the emitting thread, @0@ when
-- single-threaded). Capture is pluggable: the pure discharges ('observe'\/'observeInto') stamp a
-- deterministic logical clock (@at == seq@, @tid == 0@), while the concurrent 'observeConc' stamps
-- a wall clock with a shared sequence and the real thread id. The three captured fields are opaque
-- to the core — only an exporter interprets them (e.g. as span timestamps).
data MomentCtx i r = MomentCtx
    { mid :: Maybe i
    , path :: Path r
    , at :: Word64
    , seq :: Word64
    , tid :: Word64
    }


-- | A single moment in a region's life, as the discharge reaches it. Each carries its 'MomentCtx'
-- — the ambient trace identity, region 'Path', and fire-time captures: 'Entered' opens a region
-- with the trace identities it links to (the @[i]@ link lane) and its entry signals (the @e@ lane),
-- 'Exited' closes it with its exit signals, 'Failed' closes
-- it /abnormally/ with the thrown exception and its failure signals (in place of 'Exited' when the
-- operation throws), 'Measured' carries a 'Sampler' reading (the @s@ lane). The two signal lanes
-- never cross. Maps onto OpenTelemetry as span-start \/ span-end \/ span-end-with-error-status \/
-- span-metric, with signals as the spans' start\/end attributes.
data Moment i r e s
    = Entered (MomentCtx i r) [Link i r] [e]
    | Exited (MomentCtx i r) [e]
    | Failed (MomentCtx i r) [e] SomeException
    | Measured (MomentCtx i r) s


-- The shared discharge core, used by all three discharges: install nothing itself, just interpret
-- the 'Obs' 'Moment' stream under the three scope 'Reader's, emitting each 'Moment' through @fire@.
-- @fire@ is the /only/ thing the discharges differ in — it stamps the 'MomentCtx' clock (logical or
-- wall) and routes the 'Moment' (a private 'State' fold, the caller's monoid, or a 'Chan'); the
-- caller wraps this in the 'Reader's' run and whatever sink state @fire@ uses. @sample@ is the
-- 'Sampler', already at this row. The per-region semantics live here, once:
--
-- __Exception-safe.__ A 'Scope' fires 'Entered' (with the entry signals) before its body runs, so an
-- operation's input survives a throw; then 'Exited' with the body's exit signals (and 'Measured' for
-- each 'Sampler' reading), or — if the body throws — 'Failed' with the 'onError' signals in place of
-- 'Exited' (no result, so 'onLeave' cannot run), re-raising. A 'Trace' sets the ambient identity, a
-- 'Reroot' starts a fresh trace root, 'CurrentScope' reads the cursor.
interpretObs
    :: forall i r e s esX a
     . (Reader (Endo (Path r)) :> esX, Reader (Maybe i) :> esX, Reader [Link i r] :> esX)
    => (forall x. (s -> Eff esX ()) -> Eff esX x -> Eff esX x)
    -> (Maybe i -> Path r -> (MomentCtx i r -> Moment i r e s) -> Eff esX ())
    -> Eff (Obs i r e : esX) a
    -> Eff esX a
interpretObs sample fire =
    interpret \env -> \case
        Scope r links entrySigs onErr act -> do
            ambient <- ask
            -- the ancestor path as a difference list; extending it for the body and materializing
            -- this region's full path are both cheap
            prefix <- ask
            pending <- ask
            let full = appEndo prefix [r]
                body = localSeqUnlift env \unlift -> enterRegion r (unlift act)
            fire ambient full \ctx -> Entered ctx (pending <> links) entrySigs
            (result, exitSigs) <-
                sample (\res -> fire ambient full \ctx -> Measured ctx res) body
                    `catch` \(e :: SomeException) -> fire ambient full (\ctx -> Failed ctx (onErr e) e) >> throwIO e
            fire ambient full \ctx -> Exited ctx exitSigs
            pure result
        CurrentScope -> do
            ambient <- ask
            prefix <- ask
            pure (ambient, appEndo prefix [])
        Trace i act ->
            localSeqUnlift env \unlift -> local (const (Just i)) (unlift act)
        Reroot newLinks act ->
            localSeqUnlift env \unlift -> rerooted newLinks (unlift act)


-- | The discharge: install the 'Plan's taps, run the program, and fold the 'Moment' stream
-- through the 'Consumer'. The 'Moment' stream comes from 'interpretObs'; here @fire@ folds each
-- 'Moment' inline through the consumer's @step@, with a discharge-private 'State' holding the
-- accumulator paired with a logical-clock counter (so @at@\/@seq@ stay deterministic). The
-- accumulator is seeded by @start@ before the run and read into @stop@ after. Each 'Moment' carries
-- the trace identity active when its region opened.
--
-- __Exception-safe.__ The per-region 'Failed' path is in 'interpretObs'; on top of it the whole run
-- is wrapped in 'onException' so that, if the program throws, @stop@ still runs, fed the partial
-- accumulator recovered from the (exception-surviving) discharge 'State'; on that path @stop@\'s
-- harvest is discarded and the original exception re-propagates. @(a, h)@ is returned only when the
-- program completes normally.
observe
    :: Consumer es i r e s h
    -> Plan es i r e s
    -> Eff es a
    -> Eff es (a, h)
observe (FoldM step start stop) (Plan (Instrument install) (Sampler sample)) program = do
    x0 <- start
    (a, (xFinal, _)) <-
        runReader (mempty :: Endo (Path r))
            . runReader (Nothing :: Maybe i)
            . runReader ([] :: [Link i r])
            . runState (x0, 0 :: Word64)
            $ ( interpretObs
                    sample
                    ( \ambient full mk -> do
                        (acc, n) <- get
                        acc' <- inject (step acc (mk (logical ambient full n)))
                        put (acc', n + 1)
                    )
                    . inject
                    . install
                    . inject
                    $ program
              )
                -- Failure path: flush the partial accumulator through @stop@, then re-raise.
                `onException` (get >>= inject . stop . fst)
    h <- stop xFinal
    pure (a, h)


-- The deterministic logical-clock stamp the pure discharges ('observe'\/'observeInto') file each
-- moment under: the timestamp and sequence both take the fire counter, on the single (zero) thread.
logical :: Maybe i -> Path r -> Word64 -> MomentCtx i r
logical ambient full n = MomentCtx {mid = ambient, path = full, at = n, seq = n, tid = 0}


-- Within a region's body, shared by every discharge: extend the ambient path with this region's
-- label, and clear any pending fork-links so they attach only to the rerooted action's /outermost/
-- regions, never to ones nested below them.
enterRegion
    :: forall r i es a
     . (Reader (Endo (Path r)) :> es, Reader [Link i r] :> es)
    => r
    -> Eff es a
    -> Eff es a
enterRegion r = local (<> Endo (r :)) . local (const ([] :: [Link i r]))


-- Run an action as a fresh trace root, shared by every discharge: ambient identity reset to
-- 'Nothing' and region path reset to empty (so its regions start a new trace), with the given links
-- pending for its outermost region(s).
rerooted
    :: forall i r es a
     . (Reader (Endo (Path r)) :> es, Reader (Maybe i) :> es, Reader [Link i r] :> es)
    => [Link i r]
    -> Eff es a
    -> Eff es a
rerooted newLinks =
    local (const (Nothing :: Maybe i))
        . local (const (mempty :: Endo (Path r)))
        . local (const newLinks)


-- | Run an action so it starts its /own/ trace yet links back to the scope active where it was
-- spawned — the reroot primitive behind the 'rerooting' tap. It reads the current scope cursor with
-- 'currentScope', then reruns the action rerooted under it: the action's regions form a fresh trace
-- — no nesting under the spawner's, so a long-running spawn loop never grows one ever-larger trace —
-- whose outermost region carries a 'LinkRegion' back to the exact spawn site.
--
-- The canonical use is 'Atelier.Effects.Conc.Conc' fork-linking (see "Atelier.Observe.Core"), but it
-- suits any detached work that should be its own trace — a daemon body, a per-event handler delivery
-- — not just threads. Transport is free: the cursor rides the shared effect environment into the
-- action, so nothing need cross the boundary by hand. Like 'currentScope', it runs only in the
-- instrumented layer (the 'Observed' constraint).
rerootLinked :: (Observed es i r e) => Eff es a -> Eff es a
rerootLinked act = do
    (ambient, here) <- currentScope
    reroot [LinkRegion ambient here] act


-- | The concurrent streaming discharge: like 'observe', but the observed program may /fork/, and
-- every moment — whichever thread fires it — is enqueued to a single 'Chan' that one drain thread
-- folds through the 'Consumer'. This is what 'observe' cannot do: 'observe' folds inline through a
-- 'State' that @ki@\/'Atelier.Effects.Conc.Conc' clones per fork, so a moment fired in a forked
-- thread updates a throwaway copy and is lost; here the accumulator lives solely in the drain
-- thread and producers only enqueue, so a forking program's moments all land. The drain owns the
-- fold, so an arbitrary effectful @step@ stays lock-free.
--
-- Each moment is stamped in the firing thread with a monotonic wall clock ('at', from
-- 'getMonotonicTimeNSec'), a process-shared monotonic 'seq' (recovering program order after the
-- 'Chan' interleaves arrivals from several threads), and the firing thread's id ('tid') — the
-- fields 'observe' fills with a logical clock. An exporter reads 'at' to place a span at its real
-- fire time rather than at fold time.
--
-- __Exception-safe.__ However the program ends, a @Nothing@ sentinel is enqueued and the drain is
-- joined, so @stop@ runs (the hook to flush\/release) on a clean exit and on a throw alike. On a
-- clean exit a drain-thread error (from @step@\/@stop@) is re-raised; @(a, h)@ is returned only when
-- the program /and/ the drain both complete normally. On the throwing path the program's original
-- exception re-propagates and the harvest is discarded, matching 'observe'.
observeConc
    :: forall i r e s h es a
     . (Concurrent :> es, IOE :> es)
    => Consumer es i r e s h
    -> Plan es i r e s
    -> Eff es a
    -> Eff es (a, h)
observeConc (FoldM step start stop) (Plan (Instrument install) (Sampler sample)) program = do
    x0 <- start
    chan <- newChan :: Eff es (Chan (Maybe (Moment i r e s)))
    seqRef <- liftIO (newIORef (0 :: Word64))
    result <- newEmptyMVar :: Eff es (MVar (Either SomeException h))
    -- the lone drain: fold arrivals into the accumulator until the sentinel, then flush through stop
    let drain acc =
            readChan chan >>= \case
                Nothing -> stop acc
                Just m -> step acc m >>= drain
    _ <-
        forkIO
            ( (drain x0 >>= putMVar result . Right)
                `catch` \(ex :: SomeException) -> putMVar result (Left ex)
            )
    -- enqueue the sentinel and block on the drain's verdict — run once per exit path (the failure
    -- path through 'onException', the clean path after)
    let flushAndJoin = writeChan chan Nothing >> readMVar result
    a <-
        ( runReader (mempty :: Endo (Path r))
            . runReader (Nothing :: Maybe i)
            . runReader ([] :: [Link i r])
            $ ( interpretObs
                    sample
                    -- the capture happens in the firing thread, before the enqueue: wall clock,
                    -- process-shared sequence, real thread id
                    ( \ambient full mk -> do
                        n <- liftIO (atomicModifyIORef' seqRef \k -> (k + 1, k))
                        t <- liftIO getMonotonicTimeNSec
                        th <- fromThreadId <$> myThreadId
                        writeChan chan (Just (mk MomentCtx {mid = ambient, path = full, at = t, seq = n, tid = th}))
                    )
                    . inject
                    . install
                    . inject
                    $ program
              )
        )
            `onException` void flushAndJoin
    outcome <- flushAndJoin
    case outcome of
        Right h -> pure (a, h)
        Left ex -> throwIO ex


-- | A discharge whose harvest survives a short-circuit. Like 'observe' it installs the 'Plan's
-- taps and folds the 'Moment' stream, but it folds each moment into a monoid held in a 'State' the
-- /caller/ runs, and returns only the program's result. The caller reads the harvest from that
-- 'State' after the run.
--
-- That is the whole point. 'observe' keeps its accumulator private and returns @(a, h)@ only on the
-- normal path — if the program short-circuits, the harvest is gone. Here the accumulator lives in
-- @es@, so when an interpreter composed /outside/ this call but /inside/ the 'State' converts a
-- failure to a value — @'Effectful.Error.Static.runError'@ turning a short-circuit into a 'Left' —
-- the harvest accumulated up to the failure is intact, the failing region's 'Measured' and 'Failed'
-- moments included. Run the 'State' /outside/ the error handler (so the unwinding stops at the
-- handler, not the state) and read it however the program ended:
--
-- @
-- (resultOrErr, harvest) <-
--     'runState' mempty . runError . \<base interpreters\>
--         $ 'observeInto' contribute plan program
-- @
--
-- Pair it with a monoidal fold — @collectMoment@ from "Atelier.Observe.Aggregate" for a trie harvest, or any
-- @'Moment' -> w@ (as 'foldMoments' takes). For the all-in-one @(result, harvest)@ of a run that
-- completes normally, use 'observe'.
observeInto
    :: forall i r e s w es a
     . (Monoid w, State w :> es)
    => (Moment i r e s -> w)
    -> Plan es i r e s
    -> Eff es a
    -> Eff es a
observeInto contribute (Plan (Instrument install) (Sampler sample)) program =
    runReader (mempty :: Endo (Path r))
        . runReader (Nothing :: Maybe i)
        . runReader ([] :: [Link i r])
        $ ( interpretObs
                sample
                -- 'observeInto' feeds order-insensitive monoidal folds that read only @(mid, path)@,
                -- so it stamps a constant logical zero rather than thread a counter (which would
                -- collide with the caller's @State w@). A discharge that needs real timing/order is
                -- 'observe' or 'observeConc'.
                (\ambient full mk -> modify (<> contribute (mk (logical ambient full 0))))
                . inject
                . install
                . inject
                $ program
          )


-- | Production discharge: install the 'Plan's taps, then run — regions run, signals vanish,
-- nothing is sampled or forced, trace identities are discarded. One 'interpret' runs each
-- 'Scope'\/'Trace' body, dropping the entry signals, the yielded exit signals, and the unused
-- failure-signal function without forcing any of them.
silent :: Plan es i r e s -> Eff es a -> Eff es a
silent (Plan (Instrument install) _) =
    interpret
        ( \env -> \case
            Scope _ _ _ _ act -> localSeqUnlift env \unlift -> fst <$> unlift act
            CurrentScope -> pure (Nothing, [])
            Reroot _ act -> localSeqUnlift env \unlift -> unlift act
            Trace _ act -> localSeqUnlift env \unlift -> unlift act
        )
        . install
        . inject
