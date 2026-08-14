-- | Tracing provider for managing OpenTelemetry TracerProvider and span stack.
--
-- The actual implementation backing the `runTracing` handler.
module Atelier.Effects.Monitoring.Tracing.Provider
    ( TracingState (..)
    , initTracingState
    , shutdownTracingState
    ) where

import System.Environment (setEnv)

import OpenTelemetry.Attributes qualified as OT
import OpenTelemetry.Trace qualified as OT


-- | Handles to the initialised OpenTelemetry tracer provider and a tracer
-- derived from it.
data TracingState = TracingState
    { tracerProvider :: OT.TracerProvider
    -- ^ The global tracer provider; flushed and shut down on teardown.
    , tracer :: OT.Tracer
    -- ^ The tracer used to create spans.
    }


-- | Initialize tracing state using global tracer provider
--
-- This uses initializeGlobalTracerProvider which reads configuration from
-- environment variables (OTEL_SERVICE_NAME, OTEL_EXPORTER_OTLP_ENDPOINT)
-- and properly sets up ID generation.
initTracingState
    :: Text
    -- ^ Service name
    -> Text
    -- ^ OTLP endpoint (e.g., "http://localhost:4318")
    -> IO TracingState
initTracingState serviceName otlpEndpoint = do
    -- Set environment variables for OpenTelemetry SDK
    setEnv "OTEL_SERVICE_NAME" (toString serviceName)
    setEnv "OTEL_EXPORTER_OTLP_ENDPOINT" (toString otlpEndpoint)

    -- Initialize the global tracer provider
    -- This reads from environment variables and sets up proper ID generation
    provider <- OT.initializeGlobalTracerProvider

    -- Create instrumentation library
    let instrumentationLibrary =
            OT.InstrumentationLibrary
                serviceName -- Library name
                "" -- Version (empty for now)
                "" -- Schema URL (empty for now)
                OT.emptyAttributes -- Attributes

    -- Get a tracer from the provider
    let tracerInstance = OT.makeTracer provider instrumentationLibrary OT.tracerOptions

    pure
        TracingState
            { tracerProvider = provider
            , tracer = tracerInstance
            }


-- | Shutdown tracing state gracefully
--
-- Flushes any remaining spans and cleans up resources.
shutdownTracingState :: TracingState -> IO ()
shutdownTracingState tracingState = do
    -- Force shutdown of the tracer provider to flush spans
    OT.shutdownTracerProvider tracingState.tracerProvider
