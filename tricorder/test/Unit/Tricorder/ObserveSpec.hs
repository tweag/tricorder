-- | End-to-end check of tricorder's observation 'Observe.tricorderPlan' and 'Observe.render':
-- drive an oblivious program through the real taps (a GHCi session that runs a test suite, plus a
-- source-change publish), discharge it through the OpenTelemetry 'exporting' consumer into an
-- in-memory provider, and assert on the spans that come out — their names, kinds, nesting, and
-- attributes. This is the unit half of the Phase 4 validation: it exercises the same plan the daemon
-- wires, so a regression in a tap or in the render mapping surfaces here rather than only against a
-- live collector.
module Unit.Tricorder.ObserveSpec (spec_Observe) where

import Atelier.Effects.Conc (runConc)
import Atelier.Effects.FileWatcher (FileEvent (..))
import Atelier.Effects.Publishing (Pub (..), publish)
import Atelier.Observe (observe)
import Atelier.Observe.OpenTelemetry (exporting)
import Control.Concurrent.Async (async)
import Data.IORef (IORef, modifyIORef', newIORef, readIORef)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Dispatch.Dynamic (interpret)
import OpenTelemetry.Attributes (emptyAttributes, lookupAttribute)
import OpenTelemetry.Processor.Span (ShutdownResult (..), SpanProcessor (..))
import OpenTelemetry.Trace.Core (ImmutableSpan (..), SpanContext (..))
import Test.Hspec (Spec, describe, it, shouldBe)

import Data.List qualified as List
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import OpenTelemetry.Trace.Core qualified as OT

import Tricorder.BuildState (CabalChangeDetected, SourceChangeDetected (..))
import Tricorder.BuildState.Test (Suite (..), SuiteCompletion (..))
import Tricorder.Effects.GhciSession (LoadResult (..), runGhciSessionScripted, withGhci)
import Tricorder.Effects.TestRunner (runTestRunnerScripted, runTestSuite)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Command (..), ComponentKind (..), Target (..), TestTarget (..))

import Tricorder.Observe qualified as Observe


spec_Observe :: Spec
spec_Observe = describe "Tricorder.Observe" do
    it "emits session, test, and file-change spans with the expected names, nesting, and attributes" do
        (tracer, recorded) <- newInMemory
        runObserved tracer
        spans <- readIORef recorded

        session <- spanNamed spans "ghci.session"
        test <- spanNamed spans "test.test:unit"
        fileChange <- spanNamed spans "file.change"

        -- the session is a trace root carrying the build command
        isNothing session.spanParent `shouldBe` True
        lookupAttribute session.spanAttributes "ghci.command"
            `shouldBe` Just (OT.toAttribute ("cabal repl" :: Text))

        -- the test suite runs inside the session, so its span nests under it, and its outcome lands
        -- as an exit attribute
        isJust test.spanParent `shouldBe` True
        test.spanContext.traceId `shouldBe` session.spanContext.traceId
        lookupAttribute test.spanAttributes "test.passed"
            `shouldBe` Just (OT.toAttribute ("True" :: Text))

        -- the source-change publish roots its own trace as a Producer (a later listener links back)
        showKind fileChange.spanKind `shouldBe` showKind OT.Producer
        lookupAttribute fileChange.spanAttributes "change.kind"
            `shouldBe` Just (OT.toAttribute ("source" :: Text))
        lookupAttribute fileChange.spanAttributes "file.path"
            `shouldBe` Just (OT.toAttribute ("src/Foo.hs" :: Text))
  where
    spanNamed spans name =
        maybe (fail ("no span named " <> toString name)) pure (List.find (\s -> s.spanName == name) spans)
    -- SpanKind has no Eq instance, so compare by its Show rendering
    showKind :: OT.SpanKind -> String
    showKind = show


-- Discharge the oblivious program — a source-change publish, then a GHCi session that runs one test
-- suite — through the whole observe stack into the in-memory tracer. The scripted GHCi/TestRunner
-- interpreters stand in for the real processes, and the two 'Pub' effects are dropped (the taps
-- still fire on the publish). None of the program mentions the taps, render, or exporter.
runObserved :: OT.Tracer -> IO ()
runObserved tracer =
    void
        $ runEff
            . runConcurrent
            . runConc
            . runPubIgnore @CabalChangeDetected
            . runPubIgnore @SourceChangeDetected
            . runTestRunnerScripted [Right testResult]
            . runGhciSessionScripted [Right loadResult]
        $ observe (exporting tracer Observe.render) Observe.tricorderPlan
        $ do
            publish (SourceChangeDetected "src/Foo.hs" Modified)
            withGhci (Command "cabal repl") (ProjectRoot "/proj") \_ _controls ->
                void (runTestSuite (TestTarget (Qualified Test "unit")))


-- A Pub interpreter that discards published events; the observe interpose still sees each publish.
runPubIgnore :: Eff (Pub event : es) a -> Eff es a
runPubIgnore = interpret \_ (Publish _) -> pure ()


loadResult :: LoadResult
loadResult =
    LoadResult
        { moduleCount = 0
        , compiledFiles = Set.empty
        , loadedModules = Map.empty
        , targetNames = []
        , diagnostics = []
        }


testResult :: Suite
testResult =
    SuiteCompleted
        SuiteCompletion
            { passed = True
            , output = ""
            , testCases = []
            , duration = Nothing
            }


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
    let tracer = OT.makeTracer provider (OT.InstrumentationLibrary "tricorder-observe-test" "" "" emptyAttributes) OT.tracerOptions
    pure (tracer, recorded)
