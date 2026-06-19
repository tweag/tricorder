-- | A thin, self-contained wrapper around the hs-opentelemetry SDK for standing up a
-- 'OT.TracerProvider' and a 'OT.Tracer' to feed the exporter in "Atelier.Observe.OpenTelemetry".
--
-- The exporter 'Atelier.Observe.OpenTelemetry.exporting' consumer only needs a 'OT.Tracer', so this
-- module is optional: point the consumer at any provider you like (an in-memory one for tests, a
-- shared application provider, …). This helper is the batteries-included path — an OTLP provider
-- configured by the standard @OTEL_*@ environment variables, with a bracketed flush on shutdown.
module Atelier.Observe.OpenTelemetry.Provider
    ( TracerHandles (..)
    , initTracer
    , shutdownTracer
    , withTracer
    ) where

import Effectful (IOE)
import Effectful.Exception (bracket)
import System.Environment (setEnv)

import OpenTelemetry.Attributes qualified as OT
import OpenTelemetry.Trace qualified as OT


-- | Handles to an initialised tracer provider and a 'OT.Tracer' derived from it. The provider is
-- flushed and shut down by 'shutdownTracer'.
data TracerHandles = TracerHandles
    { tracerProvider :: OT.TracerProvider
    , tracer :: OT.Tracer
    }


-- | Initialise an OTLP tracer provider from the standard environment. Sets @OTEL_SERVICE_NAME@ and
-- @OTEL_EXPORTER_OTLP_ENDPOINT@ from the given arguments, then defers to
-- 'OT.initializeGlobalTracerProvider' (which reads the @OTEL_*@ environment and wires up the OTLP
-- exporter and id generation), and derives a 'OT.Tracer' named after the service.
initTracer
    :: (IOE :> es)
    => Text
    -- ^ Service name
    -> Text
    -- ^ OTLP endpoint, e.g. @"http://localhost:4318"@
    -> Eff es TracerHandles
initTracer serviceName otlpEndpoint = liftIO do
    setEnv "OTEL_SERVICE_NAME" (toString serviceName)
    setEnv "OTEL_EXPORTER_OTLP_ENDPOINT" (toString otlpEndpoint)
    provider <- OT.initializeGlobalTracerProvider
    let library = OT.InstrumentationLibrary serviceName "" "" OT.emptyAttributes
        tracer' = OT.makeTracer provider library OT.tracerOptions
    pure TracerHandles {tracerProvider = provider, tracer = tracer'}


-- | Flush any pending spans and shut the provider down.
shutdownTracer :: (IOE :> es) => TracerHandles -> Eff es ()
shutdownTracer handles = liftIO (OT.shutdownTracerProvider handles.tracerProvider)


-- | Bracket a computation with an initialised tracer, shutting it down (and flushing) on the way
-- out — on the exception path too. The everyday entry point: @'withTracer' name endpoint \\handles ->
-- 'Atelier.Observe.observe' ('exporting' handles.'tracer' …) plan program@.
withTracer
    :: (IOE :> es)
    => Text
    -- ^ Service name
    -> Text
    -- ^ OTLP endpoint
    -> (TracerHandles -> Eff es a)
    -> Eff es a
withTracer serviceName otlpEndpoint = bracket (initTracer serviceName otlpEndpoint) shutdownTracer
