module Unit.Atelier.Effects.Conc.TracedSpec (spec_ConcTraced) where

import Control.Concurrent (newEmptyMVar, putMVar, takeMVar, threadDelay)
import Data.IORef (IORef, modifyIORef', newIORef, readIORef)
import Effectful (IOE, runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Dispatch.Dynamic (interpret, localUnlift)
import OpenTelemetry.Common (TraceFlags (..))
import OpenTelemetry.Internal.Trace.Id (SpanId (..), TraceId (..))
import OpenTelemetry.Trace.TraceState (TraceState (..))
import Test.Hspec (Spec, describe, it, shouldReturn, shouldSatisfy)

import OpenTelemetry.Context qualified as Context
import OpenTelemetry.Context.ThreadLocal qualified as ThreadLocal
import OpenTelemetry.Trace.Core qualified as OT

import Atelier.Effects.Conc.Traced (await, concStrat, fork, fork_, runConc)
import Atelier.Effects.Monitoring.Tracing (SpanContext, Tracing (..), withLinkPropagation, withSpan)


spec_ConcTraced :: Spec
spec_ConcTraced = do
    describe "withLinkPropagation" $ do
        it "passes through when no parent context" $ do
            ops <- newIORef []
            runEff . runTracingCapture ops
                $ withLinkPropagation Nothing
                $ withSpan "foo"
                $ pure ()
            readIORef ops `shouldReturn` [PlainSpan "foo"]

        it "converts root span to linked span when parent context given" $ do
            ops <- newIORef []
            runEff . runTracingCapture ops
                $ withLinkPropagation (Just fakeSpanCtx)
                $ withSpan "foo"
                $ pure ()
            readIORef ops `shouldReturn` [LinkedSpan "foo"]

        it "does not convert nested spans (they already have a parent)" $ do
            ops <- newIORef []
            runEff . runTracingCapture ops
                $ withSpan "outer"
                $ withLinkPropagation (Just fakeSpanCtx)
                $ withSpan "inner"
                $ pure ()
            readIORef ops `shouldReturn` [PlainSpan "outer", PlainSpan "inner"]

    describe "withConcTracingLinks" $ do
        it "does not link when forking outside any span" $ do
            ops <- newIORef []
            runEff . runConcurrent . runTracingCapture ops . runConc $ do
                t <- fork $ withSpan "child" $ pure ()
                await t
            readIORef ops `shouldReturn` [PlainSpan "child"]

        it "links forked thread's root span to the parent span" $ do
            ops <- newIORef []
            runEff . runConcurrent . runTracingCapture ops . runConc $ do
                withSpan "parent" $ do
                    t <- fork $ withSpan "child" $ pure ()
                    await t
            readIORef ops `shouldReturn` [PlainSpan "parent", LinkedSpan "child"]

        it "links fork_ thread's root span to the parent span" $ do
            ops <- newIORef []
            spanRecorded <- newEmptyMVar
            runEff . runConcurrent . runTracingCapture ops . runConc $ do
                withSpan "parent" $ do
                    fork_ $ do
                        withSpan "bg" $ pure ()
                        liftIO $ putMVar spanRecorded ()
                        liftIO $ forever $ threadDelay maxBound
                    liftIO $ takeMVar spanRecorded
            readIORef ops >>= (`shouldSatisfy` elem (LinkedSpan "bg"))


--------------------------------------------------------------------------------
-- Test Infrastructure
--------------------------------------------------------------------------------

data SpanOp
    = PlainSpan Text
    | LinkedSpan Text
    deriving stock (Eq, Show)


-- | A fake but valid span context for testing.
fakeSpanCtx :: SpanContext
fakeSpanCtx =
    OT.SpanContext
        (TraceFlags 0x01)
        False
        (TraceId "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\1")
        (SpanId "\0\0\0\0\0\0\0\1")
        (TraceState [])


-- | Test interpreter that records 'PlainSpan' vs 'LinkedSpan' operations.
--
-- Uses real thread-local storage for context tracking so that forked threads
-- correctly start with an empty context (as they would in production), allowing
-- 'withLinkPropagation' to distinguish root spans from nested ones.
runTracingCapture
    :: (IOE :> es)
    => IORef [SpanOp]
    -> Eff (Tracing : es) a
    -> Eff es a
runTracingCapture log = interpret $ \env -> \case
    WithSpan name act -> do
        liftIO $ modifyIORef' log (<> [PlainSpan name])
        currentCtx <- liftIO ThreadLocal.getContext
        let newCtx = Context.insertSpan (OT.wrapSpanContext fakeSpanCtx) currentCtx
        oldCtx <- liftIO $ ThreadLocal.attachContext newCtx
        result <- localUnlift env concStrat $ \unlift -> unlift act
        liftIO $ void $ case oldCtx of
            Just ctx -> ThreadLocal.attachContext ctx
            Nothing -> ThreadLocal.detachContext
        pure result
    WithSpanLinked name _ act -> do
        liftIO $ modifyIORef' log (<> [LinkedSpan name])
        localUnlift env concStrat $ \unlift -> unlift act
    GetSpanContext -> do
        ctx <- liftIO ThreadLocal.getContext
        liftIO $ traverse OT.getSpanContext (Context.lookupSpan ctx)
    GetCurrentContext ->
        liftIO ThreadLocal.getContext
    AddAttribute _ _ -> pure ()
    AddEvent _ _ -> pure ()
    SetStatus _ -> pure ()
