-- | A singleflight cache effect: deduplicate concurrent computations of the
-- same key.
--
-- When several threads request the same key at once, the first runs the
-- computation while the rest wait and share its result — so an expensive lookup
-- happens once per key per in-flight window. Results (and exceptions) can also
-- be seeded with 'updateCache' or invalidated with 'removeFromCache'. Each
-- operation is traced (see "Atelier.Effects.Monitoring.Tracing").
module Atelier.Effects.Cache.Singleflight.Traced
    ( Singleflight
    , withCache
    , updateCache
    , removeFromCache
    , runSingleflight
    )
where

import Atelier.Effects.Cache.Singleflight
    ( Singleflight (..)
    , removeFromCache
    , updateCache
    , withCache
    )
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (TMVar)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift)
import Effectful.Exception (throwIO, trySync)
import StmContainers.Map (Map)
import Prelude hiding (Map)

import Effectful.Concurrent.STM qualified as STM
import StmContainers.Map qualified as Map

import Atelier.Effects.Monitoring.Tracing (Tracing, addAttribute, withSpan)


type InFlightMap key value = Map key (TMVar (Either SomeException value))


-- | Run the Singleflight effect with an in-memory cache
runSingleflight
    :: forall key value es a
     . (Concurrent :> es, Hashable key, Tracing :> es)
    => Eff (Singleflight key value : es) a
    -> Eff es a
runSingleflight action = do
    -- Initialize the cache
    cache :: InFlightMap key value <- STM.atomically Map.new

    -- Run with the cache in Reader context, interpreting Singleflight operations
    interpretWith action $ \env -> \case
        WithCache key computation -> localSeqUnlift env $ \unlift -> withSpan "singleflight.with_cache" do
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
                    addAttribute @Text "singleflight.outcome" "hit"
                    pure value
                (_, Just (Left exception)) -> do
                    addAttribute @Text "singleflight.outcome" "hit"
                    throwIO exception
                (True, Nothing) -> do
                    addAttribute @Text "singleflight.outcome" "compute"
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
                    addAttribute @Text "singleflight.outcome" "wait"
                    result <-
                        withSpan "singleflight.wait"
                            $ STM.atomically
                            $ STM.readTMVar mvar
                    case result of
                        Left exception -> throwIO exception
                        Right value -> pure value
        UpdateCache entries -> withSpan "singleflight.update_cache" do
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
        RemoveFromCache keys -> withSpan "singleflight.remove_from_cache" do
            STM.atomically $ forM_ keys $ \key -> Map.delete key cache
