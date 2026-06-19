-- | Tricorder's observation 'Plan' and its OpenTelemetry wiring, built on "Atelier.Observe".
--
-- This is the application half of the tracing stack: it names tricorder's own observe vocabulary
-- (the trace identity 'Trace', the region label 'Region', the signal 'Signal'), assembles a
-- 'tricorderPlan' that instruments tricorder's effects, supplies a 'render' mapping that vocabulary
-- into the OpenTelemetry span model, and offers 'withObserve' — the additive entry point that wraps
-- the daemon program with the concurrent discharge and an OTLP exporter.
--
-- It runs /alongside/ the legacy @Atelier.Effects.Monitoring.Tracing@ wiring (the validation oracle),
-- gated on its own @observability.observe@ config: the instrumentation lives entirely here, so the
-- business code stays oblivious.
--
-- Deliberately scoped for the first increment. Instrumented: the GHCi session lifetime
-- ('GhciSession'), each test-suite run and its outcome ('TestRunner'), the source\/cabal change
-- events that trigger builds (as event-derived trace roots), and forked-thread causality (the core
-- 'concForkLinks'). Deferred: listener→publisher links (needs per-delivery pub\/sub taps), component
-- lifecycle spans, and per-reload compile spans (the reload is a closure in 'Controls', not a tappable
-- operation).
module Tricorder.Observe
    ( -- * Vocabulary
      Trace (..)
    , Region (..)
    , Signal (..)

      -- * Plan & exporter mapping
    , tricorderPlan
    , render

      -- * Config & wiring
    , ObserveConfig (..)
    , withObserve
    ) where

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Publishing (Pub (..))
import Atelier.Observe (Plan, Tap, entering, leaving, observeConc, tap, tracedBy, watch)
import Atelier.Observe.Core (concForkLinks)
import Atelier.Observe.OpenTelemetry (Render (..), exporting)
import Atelier.Observe.OpenTelemetry.Provider (TracerHandles (..), withTracer)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import Effectful (IOE)
import Effectful.Concurrent (Concurrent)

import OpenTelemetry.Trace.Core qualified as OT

import Tricorder.BuildState
    ( CabalChangeDetected (..)
    , SourceChangeDetected (..)
    )
import Tricorder.BuildState.Test (Suite (..), SuiteCompletion (..), SuiteError (..))
import Tricorder.Effects.GhciSession (GhciSession (..))
import Tricorder.Effects.TestRunner (TestRunner (..))
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Command (..), renderTestTarget)


-- | The trace identity (@i@): what groups regions into one trace and what a cross-trace link names.
-- A 'FileTrace' is event-derived — a file-change event's path — so the publish of that event becomes
-- the root of a trace a future listener link can resolve to (root-granularity pub\/sub linking).
newtype Trace = FileTrace Text
    deriving stock (Eq, Ord, Show)


-- | The region label (@r@): the unit of work a span covers.
data Region
    = -- | a GHCi session's whole lifetime
      Session
    | -- | a test-suite run, by target
      TestSuite Text
    | -- | a test-runner control operation (interrupt\/reset\/poll), by name
      TestControl Text
    | -- | a published file-change event
      FileChange
    deriving stock (Eq, Ord, Show)


-- | The signal lane (@e@): a single span attribute as a key\/value pair, rendered straight through.
data Signal = Attr Text Text
    deriving stock (Eq, Show)


-- | The observation 'Plan' for the tricorder daemon: the core fork-linking interpose merged with
-- application taps over tricorder's own effects. Merge-only ('<>'); each 'tap' instruments one
-- effect, 'concForkLinks' reroots forked threads to their own traces linked back to the fork site.
tricorderPlan
    :: ( Conc :> es
       , GhciSession :> es
       , Pub CabalChangeDetected :> es
       , Pub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => Plan es Trace Region Signal ()
tricorderPlan =
    concForkLinks
        <> tap sessionTap
        <> tap testTap
        <> tap sourceChangeTap
        <> tap cabalChangeTap


-- The GHCi session: one region spanning the session's life, tagged with the build command and root.
sessionTap :: Tap GhciSession Trace Region Signal
sessionTap =
    watch (\(WithGhci {}) -> Session)
        & entering
            ( \(WithGhci (Command cmd) (ProjectRoot root) _) ->
                [Attr "ghci.command" cmd, Attr "ghci.project_root" (toText root)]
            )


-- The test runner: 'RunTestSuite' is a region per target carrying its outcome on exit; the control
-- operations get small marker regions (they fire at most once per build cycle).
testTap :: Tap TestRunner Trace Region Signal
testTap =
    watch
        ( \case
            RunTestSuite target -> TestSuite (renderTestTarget target)
            InterruptCurrent -> TestControl "interrupt"
            ResetAbort -> TestControl "reset_abort"
            IsAborted -> TestControl "is_aborted"
        )
        & entering (\case RunTestSuite target -> [Attr "test.target" (renderTestTarget target)]; _ -> [])
        & leaving
            ( \op result -> case op of
                RunTestSuite target -> Attr "test.target" (renderTestTarget target) : suiteOutcome result
                _ -> []
            )


-- Attributes derived from a finished suite run. The suite's target now lives on the operation (it is
-- the 'Suites' map key upstream, no longer a record field), so the caller adds it; here we render
-- only the outcome.
suiteOutcome :: Suite -> [Signal]
suiteOutcome = \case
    SuiteCompleted c -> [Attr "test.passed" (show c.passed)]
    SuiteErrored e -> [Attr "test.errored" e.message]
    SuiteRunning _ -> []


-- A source-file change: a region rooted in the changed file's trace (event-derived identity), so the
-- publish becomes that trace's root span for a later listener link to resolve against.
sourceChangeTap :: Tap (Pub SourceChangeDetected) Trace Region Signal
sourceChangeTap =
    watch (\(Publish (SourceChangeDetected {})) -> FileChange)
        & tracedBy (\(Publish (SourceChangeDetected p _)) -> Just (FileTrace (toText p)))
        & entering
            ( \(Publish (SourceChangeDetected p ev)) ->
                [Attr "change.kind" "source", Attr "file.path" (toText p), Attr "file.event" (show ev)]
            )


-- A cabal-file change: the restart trigger, instrumented the same way as a source change.
cabalChangeTap :: Tap (Pub CabalChangeDetected) Trace Region Signal
cabalChangeTap =
    watch (\(Publish (CabalChangeDetected {})) -> FileChange)
        & tracedBy (\(Publish (CabalChangeDetected p _)) -> Just (FileTrace (toText p)))
        & entering
            ( \(Publish (CabalChangeDetected p ev)) ->
                [Attr "change.kind" "cabal", Attr "file.path" (toText p), Attr "file.event" (show ev)]
            )


-- | How tricorder's observe vocabulary maps onto the OpenTelemetry span model: the innermost region
-- names the span, each 'Signal' is one attribute, and the trace identity contributes a correlation
-- attribute. There is no sampler lane (@s ~ ()@), so measurements render to nothing.
render :: Render Trace Region Signal ()
render =
    Render
        { renderName = maybe "root" regionName . viaNonEmpty last
        , renderKind = maybe OT.Internal regionKind . viaNonEmpty last
        , renderSignal = \(Attr k v) -> [(k, OT.toAttribute v)]
        , renderMeasurement = const []
        , renderTraceId = \(FileTrace p) -> [("file.path", OT.toAttribute p)]
        }


regionName :: Region -> Text
regionName = \case
    Session -> "ghci.session"
    TestSuite t -> "test." <> t
    TestControl c -> "test.control." <> c
    FileChange -> "file.change"


-- A published file-change event roots a trace a later listener links back to, so it is a 'Producer';
-- the rest are ordinary in-process work.
regionKind :: Region -> OT.SpanKind
regionKind = \case
    FileChange -> OT.Producer
    _ -> OT.Internal


-- | Configuration for the observe tracing path, read from the @observability.observe@ config section.
-- Mirrors the legacy 'Atelier.Effects.Monitoring.Tracing.TracingConfig' so the two stacks can be
-- pointed at the same collector for the validation diff.
data ObserveConfig = ObserveConfig
    { enabled :: Bool
    -- ^ enable the observe tracing path
    , serviceName :: Text
    -- ^ service name reported to the collector
    , otlpEndpoint :: Text
    -- ^ OTLP endpoint, e.g. @"http://localhost:4318"@
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via QuietSnake ObserveConfig
    deriving (FromJSON) via WithDefaults (QuietSnake ObserveConfig)


instance Default ObserveConfig where
    def =
        ObserveConfig
            { enabled = False
            , serviceName = "tricorder"
            , otlpEndpoint = "http://localhost:4318"
            }


-- | Wrap the daemon program with the observe tracing path, additively. When disabled the program runs
-- untouched; when enabled it is discharged with the concurrent streaming 'observeConc' over
-- 'tricorderPlan', exporting spans live through a bracketed OTLP tracer ('withTracer' flushes on the
-- way out, the exception path included). The program's result is returned unchanged.
--
-- Install it /inside/ all the interpreters of the effects 'tricorderPlan' taps (so those effects are
-- still in the row), which in the daemon means wrapping @runSystem@ directly.
withObserve
    :: ( Conc :> es
       , Concurrent :> es
       , GhciSession :> es
       , IOE :> es
       , Pub CabalChangeDetected :> es
       , Pub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => ObserveConfig
    -> Eff es a
    -> Eff es a
withObserve cfg program
    | not cfg.enabled = program
    | otherwise =
        withTracer cfg.serviceName cfg.otlpEndpoint \handles ->
            fst <$> observeConc (exporting handles.tracer render) tricorderPlan program
