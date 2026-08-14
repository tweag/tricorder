-- | Tracing effect for distributed tracing with OpenTelemetry.
--
-- Provides operations for creating spans, adding attributes, and propagating trace context.
--
-- == Basic Usage
--
-- @
-- myHandler :: (Tracing :> es) => Eff es ()
-- myHandler = do
--     withSpan "api.create_user" $ do
--         addAttribute "user.id" "123"
--         -- ... do work ...
--         setStatus Ok
-- @
module Atelier.Effects.Monitoring.Tracing
    ( -- * Effect
      Tracing (..)

      -- * Span Operations
    , withSpan
    , withSpanLinked
    , withLinkPropagation
    , addAttribute
    , addEvent
    , setStatus
    , getSpanContext
    , OT.ToAttribute (..)
    , Attr (..)
    , ToAttributeShow (..)

      -- * Interpreters
    , runTracing
    , runTracingFromConfig
    , runTracingNoOp

      -- * Configuration
    , TracingConfig (..)

      -- * Re-exports
    , SpanStatus (..)
    , SpanContext
    ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import Effectful (Effect, IOE, Limit (..), Persistence (..), UnliftStrategy (..))
import Effectful.Dispatch.Dynamic (interposeWith, interpret, interpretWith, localSeqUnlift, localUnlift)
import Effectful.Exception (bracket, onException)
import Effectful.Reader.Static (Reader, ask)
import Effectful.TH (makeEffect)

import Data.HashMap.Strict qualified as HashMap
import OpenTelemetry.Context qualified as Context
import OpenTelemetry.Context.ThreadLocal qualified as ThreadLocal
import OpenTelemetry.Trace qualified as OT
import OpenTelemetry.Trace.Core qualified as OT

import Atelier.Effects.Timeout (Timeout, timeout)
import Atelier.Time (Second)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))

import Atelier.Effects.Monitoring.Tracing.Provider qualified as Provider


-- | Tracing configuration for OpenTelemetry
data TracingConfig = TracingConfig
    { enabled :: Bool
    -- ^ Enable tracing
    , serviceName :: Text
    -- ^ Service name for traces
    , otlpEndpoint :: Text
    -- ^ OTLP endpoint (e.g., "http://localhost:4318")
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via QuietSnake TracingConfig
    deriving (FromJSON) via WithDefaults (QuietSnake TracingConfig)


instance Default TracingConfig where
    def =
        TracingConfig
            { enabled = False
            , serviceName = "hoard"
            , otlpEndpoint = "http://localhost:4318"
            }


-- | Span status for indicating success or failure
data SpanStatus
    = -- | The operation completed successfully.
      Ok
    | -- | The operation failed, with an explanatory message.
      Error Text
    deriving stock (Eq, Show)


-- | Opaque span context for correlating traces with metrics
type SpanContext = OT.SpanContext


-- | Tracing effect for distributed tracing
data Tracing :: Effect where
    -- | Execute an action within a named span (bracket-style, automatic cleanup)
    WithSpan :: Text -> m a -> Tracing m a
    -- | Execute an action within a named span with links to other span contexts
    WithSpanLinked :: Text -> [SpanContext] -> m a -> Tracing m a
    -- | Add an attribute to the current span
    AddAttribute :: (OT.ToAttribute attr) => Text -> attr -> Tracing m ()
    -- | Add an event to the current span
    AddEvent :: (OT.ToAttribute attr) => Text -> [(Text, attr)] -> Tracing m ()
    -- | Set the status of the current span
    SetStatus :: SpanStatus -> Tracing m ()
    -- | Get the current span context (for exemplars)
    GetSpanContext :: Tracing m (Maybe SpanContext)
    -- | Get the current OpenTelemetry context (internal use)
    GetCurrentContext :: Tracing m Context.Context


-- | Useful to create a heterogeneous list of attribute values. These two are equivalent:
--
-- @
-- addEvent "foo" [OT.toAttribute 1, OT.toAttribute "foo"]
-- addEvent "foo" [Attr 1, Attr "foo"]
-- @
data Attr where
    Attr :: (OT.ToAttribute a) => a -> Attr


instance OT.ToAttribute Attr where
    toAttribute (Attr a) = OT.toAttribute a


-- | Wrapper that turns any 'Show'able value into an OpenTelemetry attribute via
-- its 'Show' instance. Derive an attribute instance @via 'ToAttributeShow' T@,
-- or wrap a value directly.
newtype ToAttributeShow a = ToAttributeShow
    { getToAttributeShow :: a
    }


instance (Show a) => OT.ToPrimitiveAttribute (ToAttributeShow a) where
    toPrimitiveAttribute = OT.TextAttribute . show . getToAttributeShow


instance (Show a) => OT.ToAttribute (ToAttributeShow a)


makeEffect ''Tracing


-- | Run an action with automatic span link propagation for fire-and-forget forks.
--
-- Any span created with no current parent (i.e., a root span) will automatically
-- receive a link to @parentCtx@. Nested spans inside those are unaffected — they
-- already have a parent and follow normal child semantics.
--
-- This avoids the trace growth problem caused by parent-child propagation in
-- long-running loops: each loop iteration's work becomes its own trace, linked
-- back to the originating span rather than piling spans onto a single trace.
withLinkPropagation :: (Tracing :> es) => Maybe SpanContext -> Eff es a -> Eff es a
withLinkPropagation Nothing action = action
withLinkPropagation (Just parentSpanCtx) action =
    interposeWith action $ \env -> \case
        WithSpan name m -> do
            currentCtx <- getCurrentContext
            localUnlift env (ConcUnlift Persistent Unlimited) $ \unlift ->
                case Context.lookupSpan currentCtx of
                    Nothing -> withSpanLinked name [parentSpanCtx] (unlift m)
                    Just _ -> withSpan name (unlift m)
        WithSpanLinked name ctxs m ->
            localUnlift env (ConcUnlift Persistent Unlimited) $ \unlift ->
                withSpanLinked name ctxs (unlift m)
        AddAttribute key val -> addAttribute key val
        AddEvent name attrs -> addEvent name attrs
        SetStatus status -> setStatus status
        GetSpanContext -> getSpanContext
        GetCurrentContext -> getCurrentContext


-- | Run the Tracing effect with OpenTelemetry
--
-- Initializes the tracer provider and manages span lifecycle.
runTracing
    :: (IOE :> es, Timeout :> es)
    => Bool
    -- ^ Tracing enabled flag
    -> Text
    -- ^ Service name
    -> Text
    -- ^ OTLP endpoint
    -> Eff (Tracing : es) a
    -> Eff es a
runTracing enabled serviceName otlpEndpoint action
    | not enabled = runTracingNoOp action
    | otherwise =
        bracket
            (liftIO $ Provider.initTracingState serviceName otlpEndpoint)
            (\tracingState -> void $ timeout (3 :: Second) $ liftIO $ Provider.shutdownTracingState tracingState)
            $ \tracingState -> interpretWith action $ \env -> \case
                WithSpan spanName innerAction -> localSeqUnlift env $ \unlift -> do
                    currentCtx <- liftIO ThreadLocal.getContext
                    newSpan <- liftIO $ OT.createSpan tracingState.tracer currentCtx spanName OT.defaultSpanArguments
                    let newCtx = Context.insertSpan newSpan currentCtx
                    oldCtx <- liftIO $ ThreadLocal.attachContext newCtx
                    innerResult <-
                        unlift innerAction `onException` do
                            liftIO $ OT.setStatus newSpan (OT.Error "Exception occurred")
                    -- Restore the old context
                    liftIO $ void $ case oldCtx of
                        Just ctx -> ThreadLocal.attachContext ctx
                        Nothing -> ThreadLocal.detachContext
                    liftIO $ OT.endSpan newSpan Nothing
                    pure innerResult
                WithSpanLinked spanName linkedContexts innerAction -> localSeqUnlift env $ \unlift -> do
                    currentCtx <- liftIO ThreadLocal.getContext
                    let spanArgs =
                            OT.defaultSpanArguments
                                { OT.links = map (\ctx -> OT.NewLink ctx mempty) linkedContexts
                                }
                    newSpan <- liftIO $ OT.createSpan tracingState.tracer currentCtx spanName spanArgs
                    let newCtx = Context.insertSpan newSpan currentCtx
                    oldCtx <- liftIO $ ThreadLocal.attachContext newCtx
                    innerResult <-
                        unlift innerAction `onException` do
                            liftIO $ OT.setStatus newSpan (OT.Error "Exception occurred")

                    -- Restore the old context
                    liftIO $ void $ case oldCtx of
                        Just ctx -> ThreadLocal.attachContext ctx
                        Nothing -> ThreadLocal.detachContext
                    liftIO $ OT.endSpan newSpan Nothing
                    pure innerResult
                AddAttribute key value -> do
                    currentCtx <- liftIO ThreadLocal.getContext
                    case Context.lookupSpan currentCtx of
                        Just currentSpan ->
                            liftIO $ OT.addAttribute currentSpan key (OT.toAttribute value)
                        Nothing ->
                            -- No active span, ignore
                            pure ()
                AddEvent eventName attributes -> do
                    currentCtx <- liftIO ThreadLocal.getContext
                    case Context.lookupSpan currentCtx of
                        Just currentSpan -> do
                            let attrMap = HashMap.fromList $ map (\(k, v) -> (k, OT.toAttribute v)) attributes
                            let event = OT.NewEvent eventName attrMap Nothing
                            liftIO $ OT.addEvent currentSpan event
                        Nothing ->
                            -- No active span, ignore
                            pure ()
                SetStatus status -> do
                    currentCtx <- liftIO ThreadLocal.getContext
                    case Context.lookupSpan currentCtx of
                        Just currentSpan ->
                            liftIO $ case status of
                                Ok -> OT.setStatus currentSpan OT.Ok
                                Error msg -> OT.setStatus currentSpan (OT.Error msg)
                        Nothing ->
                            -- No active span, ignore
                            pure ()
                GetSpanContext -> do
                    currentCtx <- liftIO ThreadLocal.getContext
                    case Context.lookupSpan currentCtx of
                        Just currentSpan -> do
                            spanCtx <- liftIO $ OT.getSpanContext currentSpan
                            pure $ Just spanCtx
                        Nothing -> pure Nothing
                GetCurrentContext -> liftIO ThreadLocal.getContext


-- | Run the Tracing effect with config from Reader
--
-- Convenience wrapper that reads TracingConfig from the Reader effect.
runTracingFromConfig
    :: (IOE :> es, Reader TracingConfig :> es, Timeout :> es)
    => Eff (Tracing : es) a
    -> Eff es a
runTracingFromConfig action = do
    TracingConfig {enabled, serviceName, otlpEndpoint} <- ask
    runTracing enabled serviceName otlpEndpoint action


-- | No-op interpreter that discards all tracing operations
runTracingNoOp :: Eff (Tracing : es) a -> Eff es a
runTracingNoOp = interpret $ \env -> \case
    WithSpan _ act -> localSeqUnlift env $ \unlift -> unlift act
    WithSpanLinked _ _ act -> localSeqUnlift env $ \unlift -> unlift act
    AddAttribute _ _ -> pure ()
    AddEvent _ _ -> pure ()
    SetStatus _ -> pure ()
    GetSpanContext -> pure Nothing
    GetCurrentContext -> pure Context.empty
