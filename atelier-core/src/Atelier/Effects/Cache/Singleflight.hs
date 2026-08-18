-- | A singleflight cache effect: deduplicate concurrent computations of the
-- same key.
--
-- When several threads request the same key at once, the first runs the
-- computation while the rest wait and share its result — so an expensive lookup
-- happens once per key per in-flight window. Results (and exceptions) can also
-- be seeded with 'updateCache' or invalidated with 'removeFromCache'.
module Atelier.Effects.Cache.Singleflight
    ( Singleflight (..)
    , withCache
    , updateCache
    , removeFromCache
    , runSingleflight
    )
where

import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (TMVar)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift)
import Effectful.Exception (throwIO, trySync)
import Effectful.TH (makeEffect)
import StmContainers.Map (Map)
import Prelude hiding (Map)

import Effectful.Concurrent.STM qualified as STM
import StmContainers.Map qualified as Map


-- | Singleflight cache effect for deduplicating concurrent computations
--
-- When multiple concurrent operations request the same key:
-- - The first request executes the computation
-- - Subsequent requests wait for and share the result
-- - After completion, all requests receive the same result
data Singleflight key value :: Effect where
    -- | Execute a computation with singleflight semantics
    -- If another computation for the same key is in-flight, wait for its result
    WithCache :: (Hashable key) => key -> m value -> Singleflight key value m value
    -- | Pre-populate the cache with known values
    -- Useful when values are already available to avoid redundant computation
    UpdateCache :: [(key, value)] -> Singleflight key value m ()
    -- | Remove keys from the cache so future requests recompute from source
    RemoveFromCache :: [key] -> Singleflight key value m ()


makeEffect ''Singleflight


type InFlightMap key value = Map key (TMVar (Either SomeException value))


-- | Run the Singleflight effect with an in-memory cache
runSingleflight
    :: forall key value es a
     . (Concurrent :> es, Hashable key)
    => Eff (Singleflight key value : es) a
    -> Eff es a
runSingleflight action = do
    -- Initialize the cache
    cache :: InFlightMap key value <- STM.atomically Map.new

    -- Run with the cache in Reader context, interpreting Singleflight operations
    interpretWith action $ \env -> \case
        WithCache key computation -> localSeqUnlift env $ \unlift -> do
            -- Singleflight pattern: check if computation is already in-flight.
            -- Also attempt a non-blocking read of any existing result in the same transaction.
            (mvar, isFirst, mResult) <- STM.atomically $ do
                existing <- Map.lookup key cache
                case existing of
                    Just tmvar -> do
                        mResult <- STM.tryReadTMVar tmvar
                        pure (tmvar, False, mResult)
                    Nothing -> do
                        -- Create new empty TMVar and insert into cache
                        tmvar <- STM.newEmptyTMVar
                        Map.insert tmvar key cache
                        pure (tmvar, True, Nothing)

            case (isFirst, mResult) of
                (_, Just (Right value)) -> do
                    pure value
                (_, Just (Left exception)) -> do
                    throwIO exception
                (True, Nothing) -> do
                    result <- unlift $ trySync computation

                    -- Try to fill the TMVar with result (success or failure) for waiters
                    -- Use tryPutTMVar in case updateCache already filled it
                    filled <- STM.atomically $ STM.tryPutTMVar mvar result

                    if filled then do
                        -- We successfully filled the TMVar with our result
                        -- If it was an exception, remove from cache so future requests can retry
                        case result of
                            Left _exception -> do
                                STM.atomically $ Map.delete key cache
                            Right _ -> pure ()

                        -- Return the result or re-throw the exception
                        case result of
                            Left exception -> throwIO exception
                            Right value -> pure value
                    else do
                        -- updateCache filled it before us - read and use that value
                        finalResult <- STM.atomically $ STM.readTMVar mvar
                        case finalResult of
                            Left exception -> throwIO exception
                            Right value -> pure value
                (False, Nothing) -> do
                    result <-
                        STM.atomically
                            $ STM.readTMVar mvar
                    case result of
                        Left exception -> throwIO exception
                        Right value -> pure value
        UpdateCache entries -> do
            STM.atomically $ do
                forM_ entries $ \(key, value) -> do
                    existing <- Map.lookup key cache
                    case existing of
                        Just existingTMVar -> do
                            -- In-flight computation exists: update its result
                            -- Try to take whatever value is there (or Nothing if empty)
                            _ <- STM.tryTakeTMVar existingTMVar
                            -- Put the correct value (wrapped in Right for success)
                            STM.putTMVar existingTMVar (Right value)
                        Nothing -> do
                            -- No in-flight computation: create fresh TMVar with value
                            tmvar <- STM.newTMVar (Right value)
                            Map.insert tmvar key cache
        RemoveFromCache keys -> do
            STM.atomically $ forM_ keys $ \key -> Map.delete key cache
