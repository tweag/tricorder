-- | Database access effects for Hasql connection pools.
--
-- 'DBRead' runs read-only statements against a reader pool; 'DBWrite' runs
-- transactions against a writer pool. Both record OpenTelemetry spans, and
-- 'DBRead' additionally emits Prometheus metrics (named via
-- 'DBReadMetricNames'). Failures surface through the @Error Text@ effect.
-- 'runDB' installs both effects over a shared 'DBPools'.
module Atelier.Effects.DB
    ( DBRead
    , DBWrite
    , runQuery
    , runTransaction
    , runDBRead
    , runDBWrite
    , runDB
    , DBReadMetricNames (..)
    )
where

import Atelier.Effects.Monitoring.Metrics (Metrics, counterInc, withHistogramTiming)
import Atelier.Effects.Monitoring.Tracing
    ( SpanStatus (..)
    , Tracing
    , addAttribute
    , setStatus
    , withSpan
    )
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpretWith_)
import Effectful.Error.Static (Error, throwError)
import Effectful.Reader.Static (Reader, asks)
import Effectful.TH
import Hasql.Statement (Statement)
import Hasql.Transaction.Sessions (IsolationLevel (ReadCommitted), Mode (Write), transaction)

import Hasql.Pool qualified as Pool
import Hasql.Session qualified as Session
import Hasql.Transaction qualified as Transaction

import Atelier.Effects.DB.Config (DBPools)

import Atelier.Effects.DB.Config qualified as DB


-- | Names of the Prometheus metrics recorded for database read operations.
data DBReadMetricNames = DBReadMetricNames
    { queries :: Text
    -- ^ Counter incremented once per query.
    , errors :: Text
    -- ^ Counter incremented when a query fails.
    , duration :: Text
    -- ^ Histogram recording query duration.
    }


-- | Effect for read-only database queries.
data DBRead :: Effect where
    -- | Run a named read-only statement and return its result.
    RunQuery :: Text -> Statement () b -> DBRead m b


-- | Effect for write database transactions.
data DBWrite :: Effect where
    -- | Run a named transaction and return its result.
    RunTransaction :: Text -> Transaction.Transaction a -> DBWrite m a


makeEffect ''DBRead
makeEffect ''DBWrite


-- | Interpret 'DBRead' against the reader pool, tracing each query and
-- recording the given metrics.
runDBRead
    :: (Error Text :> es, IOE :> es, Metrics :> es, Reader DBPools :> es, Tracing :> es)
    => DBReadMetricNames
    -> Eff (DBRead : es) a
    -> Eff es a
runDBRead metricNames eff = do
    pool <- asks DB.readerPool
    interpretWith_ eff \case
        RunQuery queryName stmt -> withSpan queryName do
            addAttribute @Text "db.operation" "read"
            counterInc metricNames.queries
            withHistogramTiming metricNames.duration $ do
                result <- liftIO $ Pool.use pool (Session.statement () stmt)
                case result of
                    Left err -> do
                        counterInc metricNames.errors
                        setStatus $ Error $ "Query failed: " <> show err
                        throwError $ "Query failed: " <> queryName <> " - " <> show err
                    Right value -> do
                        setStatus Ok
                        pure value


-- | Interpret 'DBWrite' against the writer pool, tracing each transaction.
runDBWrite
    :: (Error Text :> es, IOE :> es, Reader DBPools :> es, Tracing :> es)
    => Eff (DBWrite : es) a
    -> Eff es a
runDBWrite eff = do
    pool <- asks DB.writerPool
    interpretWith_ eff \case
        RunTransaction txName tx -> withSpan txName do
            result <- liftIO $ Pool.use pool (transaction ReadCommitted Write tx)
            case result of
                Left err -> do
                    setStatus $ Error $ "Transaction failed: " <> show err
                    throwError $ "Transaction failed: " <> txName <> " - " <> show err
                Right value -> do
                    setStatus Ok
                    pure value


-- | Run both DBRead and DBWrite effects with a shared connection pool
runDB
    :: (Error Text :> es, IOE :> es, Metrics :> es, Reader DBPools :> es, Tracing :> es)
    => DBReadMetricNames
    -> Eff (DBRead : DBWrite : es) a
    -> Eff es a
runDB metricNames = runDBWrite . runDBRead metricNames
