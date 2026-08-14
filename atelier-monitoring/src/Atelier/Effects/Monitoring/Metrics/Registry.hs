-- | Metric registry for managing Prometheus metrics.
--
-- The actual implementation of the `runMetrics` handler.
module Atelier.Effects.Monitoring.Metrics.Registry
    ( MetricHandles
    , initMetricHandles
    , setGauge
    , incGauge
    , decGauge
    , incCounter
    , addCounter
    , observeHistogram
    ) where

import Data.IORef (IORef, atomicModifyIORef', newIORef, readIORef)

import Data.Map.Strict qualified as Map
import Prometheus qualified as Prom


-- | Mutable handles to the registered Prometheus metrics, keyed by name and
-- created on first use.
data MetricHandles = MetricHandles
    { gauges :: IORef (Map Text Prom.Gauge)
    , counters :: IORef (Map Text Prom.Counter)
    , histograms :: IORef (Map Text Prom.Histogram)
    }


-- | Initialize empty metric handles
initMetricHandles :: IO MetricHandles
initMetricHandles = do
    MetricHandles
        <$> newIORef mempty
        <*> newIORef mempty
        <*> newIORef mempty


-- | Set a gauge to a specific value
setGauge :: MetricHandles -> Text -> Double -> IO ()
setGauge handles name value = do
    g <- getOrCreateGauge handles name
    Prom.setGauge g value


-- | Increment a gauge by 1
incGauge :: MetricHandles -> Text -> IO ()
incGauge handles name = do
    g <- getOrCreateGauge handles name
    Prom.incGauge g


-- | Decrement a gauge by 1
decGauge :: MetricHandles -> Text -> IO ()
decGauge handles name = do
    g <- getOrCreateGauge handles name
    Prom.decGauge g


-- | Increment a counter by 1
incCounter :: MetricHandles -> Text -> IO ()
incCounter handles name = do
    c <- getOrCreateCounter handles name
    Prom.incCounter c


-- | Add a value to a counter
addCounter :: MetricHandles -> Text -> Double -> IO ()
addCounter handles name value = do
    c <- getOrCreateCounter handles name
    void $ Prom.addCounter c value


-- | Observe a value in a histogram
observeHistogram :: MetricHandles -> Text -> Double -> IO ()
observeHistogram handles name value = do
    h <- getOrCreateHistogram handles name
    Prom.observe h value


-- | Get or create a gauge metric
getOrCreateGauge :: MetricHandles -> Text -> IO Prom.Gauge
getOrCreateGauge handles name = do
    gaugeMap <- readIORef handles.gauges
    case Map.lookup name gaugeMap of
        Just g -> pure g
        Nothing -> do
            g <- Prom.register $ Prom.gauge (Prom.Info name "")
            atomicModifyIORef' handles.gauges $ \m ->
                (Map.insert name g m, ())
            pure g


-- | Get or create a counter metric
getOrCreateCounter :: MetricHandles -> Text -> IO Prom.Counter
getOrCreateCounter handles name = do
    counterMap <- readIORef handles.counters
    case Map.lookup name counterMap of
        Just c -> pure c
        Nothing -> do
            c <- Prom.register $ Prom.counter (Prom.Info name "")
            atomicModifyIORef' handles.counters $ \m ->
                (Map.insert name c m, ())
            pure c


-- | Get or create a histogram metric
getOrCreateHistogram :: MetricHandles -> Text -> IO Prom.Histogram
getOrCreateHistogram handles name = do
    histogramMap <- readIORef handles.histograms
    case Map.lookup name histogramMap of
        Just h -> pure h
        Nothing -> do
            -- Default buckets for duration metrics: 1ms, 10ms, 100ms, 1s, 10s
            let buckets = [0.001, 0.01, 0.1, 1.0, 10.0]
            h <- Prom.register $ Prom.histogram (Prom.Info name "") buckets
            atomicModifyIORef' handles.histograms $ \m ->
                (Map.insert name h m, ())
            pure h
