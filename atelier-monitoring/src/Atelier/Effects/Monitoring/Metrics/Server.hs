-- | Effect for running the Prometheus metrics HTTP server.
--
-- Wraps a Warp server that exposes the current metrics registry over HTTP, so
-- callers start it through the effect system rather than raw 'IO'.
module Atelier.Effects.Monitoring.Metrics.Server
    ( -- * Effect
      MetricsServer

      -- * Operations
    , runMetricsServer

      -- * Interpreters
    , runMetricsServerIO
    ) where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)
import Network.HTTP.Types (status200)
import Network.Wai (Application, responseLBS)

import Network.Wai.Handler.Warp qualified as Warp
import Prometheus qualified as Prom


-- | Running the Prometheus metrics HTTP server.
data MetricsServer :: Effect where
    -- | Start an HTTP server that exposes Prometheus metrics at any path on the
    -- given port. Blocks until the server stops, which normally only happens on
    -- error; intended to be run in a background thread.
    RunMetricsServer :: Int -> MetricsServer m ()


makeEffect ''MetricsServer


-- | Interpret 'MetricsServer' by running a real Warp HTTP server.
runMetricsServerIO :: (IOE :> es) => Eff (MetricsServer : es) a -> Eff es a
runMetricsServerIO = interpret_ \case
    RunMetricsServer port -> liftIO $ Warp.run port metricsApp


metricsApp :: Application
metricsApp _req respond = do
    payload <- Prom.exportMetricsAsText
    respond
        $ responseLBS
            status200
            [("Content-Type", "text/plain; version=0.0.4; charset=utf-8")]
            payload
