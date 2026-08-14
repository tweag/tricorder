-- | Metrics effect for Prometheus metrics collection.
--
-- Provides operations for tracking application metrics.
--
-- == Basic Usage
--
-- @
-- myComponent :: (Metrics :> es) => Eff es ()
-- myComponent = do
--     gaugeSet "hoard_connected_peers" 5.0
--     counterInc "hoard_blocks_received_total"
-- @
--
-- == Available Metric Types
--
-- * Gauges: Point-in-time values that can go up or down
-- * Counters: Monotonically increasing values
-- * Histograms: Distributions with buckets for measuring durations
module Atelier.Effects.Monitoring.Metrics
    ( -- * Effect
      Metrics

      -- * Gauge Operations
    , gaugeSet
    , gaugeInc
    , gaugeDec

      -- * Counter Operations
    , counterInc
    , counterAdd

      -- * Histogram Operations
    , histogramObserve
    , withHistogramTiming

      -- * Export Operations
    , exportMetrics

      -- * Interpreters
    , runMetrics
    , runMetricsNoOp
    ) where

import Data.Time.Clock (diffUTCTime)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret, interpretWith, localSeqUnlift)
import Effectful.TH (makeEffect)

import Prometheus qualified as Prom
import Prometheus.Metric.GHC qualified as GHC

import Atelier.Effects.Clock (Clock, currentTime)
import Atelier.Effects.Monitoring.Tracing (Tracing, withSpan)

import Atelier.Effects.Monitoring.Metrics.Registry qualified as Registry


-- | Metrics effect for tracking application metrics
data Metrics :: Effect where
    -- | Set a named gauge to a specific value.
    GaugeSet :: Text -> Double -> Metrics m ()
    -- | Increment a named gauge by 1.
    GaugeInc :: Text -> Metrics m ()
    -- | Decrement a named gauge by 1.
    GaugeDec :: Text -> Metrics m ()
    -- | Increment a named counter by 1.
    CounterInc :: Text -> Metrics m ()
    -- | Add a value to a named counter.
    CounterAdd :: Text -> Double -> Metrics m ()
    -- | Observe a value in a named histogram.
    HistogramObserve :: Text -> Double -> Metrics m ()
    -- | Time an action and record its duration to a histogram metric
    WithHistogramTiming :: Text -> m a -> Metrics m a
    -- | Export all collected metrics in Prometheus text format.
    ExportMetrics :: Metrics m Text


makeEffect ''Metrics


-- | Run the Metrics effect with prometheus-client
--
-- Initializes the metric registry and registers GHC metrics automatically.
runMetrics
    :: forall es a
     . (Clock :> es, IOE :> es, Tracing :> es)
    => Eff (Metrics : es) a
    -> Eff es a
runMetrics action = do
    -- Initialize metrics registry and register GHC metrics

    handles <- withSpan "metrics.setup" do
        void $ liftIO $ Prom.register GHC.ghcMetrics
        liftIO Registry.initMetricHandles

    interpretWith action \env -> \case
        GaugeSet name value -> withSpan "metrics.gauge_set" $ liftIO $ Registry.setGauge handles name value
        GaugeInc name -> withSpan "metrics.gauge_inc" $ liftIO $ Registry.incGauge handles name
        GaugeDec name -> withSpan "metrics.gauge_dec" $ liftIO $ Registry.decGauge handles name
        CounterInc name -> withSpan "metrics.counter_inc" $ liftIO $ Registry.incCounter handles name
        CounterAdd name value -> withSpan "metrics.counter_add" $ liftIO $ Registry.addCounter handles name value
        HistogramObserve name value -> withSpan "metrics.histogram_observe" $ liftIO $ Registry.observeHistogram handles name value
        WithHistogramTiming metricName eff -> do
            start <- currentTime
            result <- localSeqUnlift env \unlift -> unlift eff
            end <- currentTime
            let duration = realToFrac $ diffUTCTime end start
            withSpan "metrics.with_histogram_timing.histogram_observe"
                $ liftIO
                $ Registry.observeHistogram handles metricName duration
            pure result
        ExportMetrics -> withSpan "metrics.export_metrics" $ liftIO $ decodeUtf8 <$> Prom.exportMetricsAsText


-- | No-op interpreter that discards all metrics operations
runMetricsNoOp :: Eff (Metrics : es) a -> Eff es a
runMetricsNoOp = interpret \env -> \case
    GaugeSet _ _ -> pure ()
    GaugeInc _ -> pure ()
    GaugeDec _ -> pure ()
    CounterInc _ -> pure ()
    CounterAdd _ _ -> pure ()
    HistogramObserve _ _ -> pure ()
    WithHistogramTiming _ eff -> localSeqUnlift env \unlift -> unlift eff
    ExportMetrics -> pure ""
