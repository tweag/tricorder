-- | The proof-of-API for "Atelier.Observe.OpenTelemetry": instrument small oblivious effectful
-- programs, discharge them through the 'exporting' consumer into an in-memory OpenTelemetry
-- provider, and assert on the spans that come out — their nesting, attributes, status, links, and
-- events. The in-memory provider is a hand-rolled 'SpanProcessor' that records each finished
-- 'ImmutableSpan' into an 'IORef' as it ends (synchronously, inside 'endSpan'), so no flush is
-- needed.
module Unit.OpenTelemetrySpec (spec_OpenTelemetry) where

import Atelier.Observe
    ( Observed
    , Sampler
    , Tap
    , gauge
    , interposing
    , leaving
    , linkedTo
    , observe
    , rerootLinked
    , sampling
    , tap
    , tracedBy
    , watch
    )
import Control.Concurrent.Async (async)
import Data.IORef (IORef, modifyIORef', newIORef, readIORef)
import Effectful (Dispatch (Dynamic), DispatchOf, Effect, IOE, runEff)
import Effectful.Dispatch.Dynamic (interpose, interpret, send)
import OpenTelemetry.Attributes (emptyAttributes, lookupAttribute)
import OpenTelemetry.Processor.Span (ShutdownResult (..), SpanProcessor (..))
import OpenTelemetry.Trace.Core (Event (..), ImmutableSpan (..), Link (..), SpanContext (..))
import OpenTelemetry.Util (appendOnlyBoundedCollectionValues)
import Test.Hspec (Spec, describe, expectationFailure, it, shouldBe, shouldMatchList)

import Control.Exception qualified as E
import OpenTelemetry.Trace.Core qualified as OT

import Atelier.Observe.OpenTelemetry (Render (..), exporting)


-- An in-memory provider: a 'SpanProcessor' that appends each ended span to an 'IORef'.
newInMemory :: IO (OT.Tracer, IORef [ImmutableSpan])
newInMemory = do
    recorded <- newIORef []
    let processor =
            SpanProcessor
                { spanProcessorOnStart = \_ _ -> pure ()
                , spanProcessorOnEnd = \spanRef -> readIORef spanRef >>= \s -> modifyIORef' recorded (s :)
                , spanProcessorShutdown = async (pure ShutdownSuccess)
                , spanProcessorForceFlush = pure ()
                }
    provider <- OT.createTracerProvider [processor] OT.emptyTracerProviderOptions
    let tracer = OT.makeTracer provider (OT.InstrumentationLibrary "atelier-observe-otel-test" "" "" emptyAttributes) OT.tracerOptions
    pure (tracer, recorded)


-- How the test's lanes render: each span is named by its leaf region; each signal is a (key, value)
-- text attribute; the trace identity is attached for correlation; measurements carry no attributes.
render :: Render Int Text (Text, Text) ()
render =
    Render
        { renderName = leafName
        , renderKind = const OT.Internal
        , renderSignal = \(k, v) -> [(k, OT.toAttribute v)]
        , renderMeasurement = const []
        , renderTraceId = \i -> [("trace.id", OT.toAttribute i)]
        }


-- the innermost region label of a path (the conventional OpenTelemetry span name)
leafName :: [Text] -> Text
leafName path = case reverse path of
    leaf : _ -> leaf
    [] -> "root"


-- A nesting fixture: 'Outer'\'s interpreter performs 'Inner', so the inner region descends inside
-- the outer one — a real run that yields a depth-2 path.
data Outer :: Effect where
    Outer :: Outer m ()


type instance DispatchOf Outer = Dynamic


data Inner :: Effect where
    Inner :: Inner m ()


type instance DispatchOf Inner = Dynamic


runInner :: Eff (Inner : es) a -> Eff es a
runInner = interpret \_ -> \case
    Inner -> pure ()


runOuter :: (Inner :> es) => Eff (Outer : es) a -> Eff es a
runOuter = interpret \_ -> \case
    Outer -> send Inner


-- A request worker carrying a trace id and a list of trace ids to link to.
data Req :: Effect where
    Req :: Int -> [Int] -> Req m ()


type instance DispatchOf Req = Dynamic


runReq :: Eff (Req : es) a -> Eff es a
runReq = interpret \_ -> \case
    Req _ _ -> pure ()


-- A worker whose operation throws.
data Boom :: Effect where
    Boom :: Boom m ()


type instance DispatchOf Boom = Dynamic


runBoom :: (IOE :> es) => Eff (Boom : es) a -> Eff es a
runBoom = interpret \_ -> \case
    Boom -> liftIO (E.throwIO (E.ErrorCall "kaboom"))


outerTap :: Tap Outer Int Text (Text, Text)
outerTap = watch (const "outer")


innerTap :: Tap Inner Int Text (Text, Text)
innerTap = watch (const "inner") & leaving (\_ _ -> [("phase", "inner")])


-- An instrumentation-layer interpose standing in for the Conc fork-linking interpose: it intercepts
-- 'Outer' and, in place of its body, spawns the inner work through 'rerootLinked' — which reroots that
-- work into its own trace, linked back to the exact region active at the spawn site (the enclosing
-- "outer" region). The spawned @send Inner@ is a fresh, directly-run action (not a 'passthrough' of
-- the intercepted op), so 'reroot'\'s scope resets reach the inner region — the same shape a real
-- forked child has.
spawnInner :: (Inner :> es, Observed es Int Text (Text, Text), Outer :> es) => Eff es x -> Eff es x
spawnInner = interpose \_ op -> case op of
    Outer -> rerootLinked (send Inner)


reqTap :: Tap Req Int Text (Text, Text)
reqTap =
    watch (const "req")
        & tracedBy (\case Req rid _ -> Just rid)
        & linkedTo (\case Req _ links -> links)


boomTap :: Tap Boom Int Text (Text, Text)
boomTap = watch (const "boom")


-- A sampler that fires one measurement per region.
tickSampler :: Sampler es ()
tickSampler = gauge (pure ()) (\_ _ -> ())


-- read the events / links of a recorded span as plain lists
eventsOf :: ImmutableSpan -> [Event]
eventsOf s = toList (appendOnlyBoundedCollectionValues s.spanEvents)


linksOf :: ImmutableSpan -> [Link]
linksOf s = toList (appendOnlyBoundedCollectionValues s.spanLinks)


spec_OpenTelemetry :: Spec
spec_OpenTelemetry = describe "Atelier.Observe.OpenTelemetry" do
    it "emits nested spans with parent/child, attributes, Ok status, and a measurement event" do
        (tracer, recorded) <- newInMemory
        (_, ()) <-
            runEff . runInner . runOuter
                $ observe (exporting tracer render) (tap outerTap <> tap innerTap <> sampling tickSampler) (send Outer)
        spans <- readIORef recorded
        outer <- spanNamed spans "outer"
        inner <- spanNamed spans "inner"
        -- both closed cleanly
        outer.spanStatus `shouldBe` OT.Ok
        inner.spanStatus `shouldBe` OT.Ok
        -- one trace, with outer the root and inner its child
        inner.spanContext.traceId `shouldBe` outer.spanContext.traceId
        isNothing outer.spanParent `shouldBe` True
        isJust inner.spanParent `shouldBe` True
        -- the inner region's leave-signal landed as a span attribute
        lookupAttribute (spanAttributes inner) "phase" `shouldBe` Just (OT.toAttribute ("inner" :: Text))
        -- the sampler reading became a measurement event on the inner span
        map (.eventName) (eventsOf inner) `shouldBe` ["measurement"]

    it "marks a failing region's span with Error status" do
        (tracer, recorded) <- newInMemory
        _ <-
            E.try (runEff . runBoom $ observe (exporting tracer render) (tap boomTap) (send Boom))
                :: IO (Either E.SomeException ((), ()))
        spans <- readIORef recorded
        boom <- spanNamed spans "boom"
        case boom.spanStatus of
            OT.Error _ -> pure ()
            other -> expectationFailure ("expected Error status, got " <> show other)

    it "emits a cross-trace link from a linkedTo Tap to the linked trace's root span" do
        (tracer, recorded) <- newInMemory
        -- request 1 runs first (its root span context is captured), then request 2 links back to it
        (_, ()) <-
            runEff . runReq
                $ observe (exporting tracer render) (tap reqTap) (send (Req 1 []) >> send (Req 2 [1]))
        spans <- readIORef recorded
        let reqs = filter (\s -> s.spanName == "req") spans
        length reqs `shouldBe` 2
        linked <- orFail "no linked span" (find (not . null . linksOf) reqs)
        root1 <- orFail "no root span" (find (null . linksOf) reqs)
        map (\l -> l.frozenLinkContext.traceId) (linksOf linked) `shouldBe` [root1.spanContext.traceId]

    it "emits a region-granular fork link: a rerootLinked child is a fresh trace linked to its exact parent region" do
        (tracer, recorded) <- newInMemory
        -- the "outer" region forks "inner": spawnInner reroots inner into its own trace, linked back.
        -- Order matters: outerTap sits inside spawnInner (opens "outer", then passes out to the
        -- spawn), while innerTap sits outside it (so spawnInner's @send Inner@ reaches the tap).
        let plan = tap innerTap <> interposing spawnInner <> tap outerTap
        (_, ()) <-
            runEff . runInner . runOuter
                $ observe (exporting tracer render) plan (send Outer)
        spans <- readIORef recorded
        parent <- spanNamed spans "outer"
        child <- spanNamed spans "inner"
        -- the parent region is a normal root span carrying no links…
        isNothing parent.spanParent `shouldBe` True
        null (linksOf parent) `shouldBe` True
        -- …while the forked child is its OWN root — not nested under the parent (a non-rerooted child
        -- would have @isJust spanParent@) — yet carries exactly one link: the region-granular link
        -- back to the parent's span, resolved from regionCtxs. (The in-memory provider stamps all
        -- spans with a zero trace id, so trace distinctness itself is asserted at the Moment level in
        -- atelier-observe's ObserveFrameworkSpec.)
        isNothing child.spanParent `shouldBe` True
        length (linksOf child) `shouldBe` 1

    it "sets each span's kind from renderKind" do
        (tracer, recorded) <- newInMemory
        -- render everything as a Producer; the default render leaves spans Internal
        let producing = render {renderKind = const OT.Producer}
        (_, ()) <-
            runEff . runInner . runOuter
                $ observe (exporting tracer producing) (tap outerTap <> tap innerTap) (send Outer)
        spans <- readIORef recorded
        -- SpanKind has no Eq instance, so compare by its Show rendering
        (map (show . (.spanKind)) spans :: [String]) `shouldMatchList` map show [OT.Producer, OT.Producer]
  where
    spanNamed spans name = orFail ("no span named " <> show name) (find (\s -> s.spanName == name) spans)
    orFail msg = maybe (fail msg) pure
