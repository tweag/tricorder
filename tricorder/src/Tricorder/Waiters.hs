module Tricorder.Waiters
    ( Waiters (..)
    , with
    , without
    , wait
    , run
    )
where

import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically, modifyTVar', newTVarIO, readTVar, retry)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift)
import Effectful.Exception (bracket_)
import Effectful.TH (makeEffect)


data Waiters :: Effect where
    -- | Perform an action, signalling that there is a waiter inhabiting the
    -- action.
    With :: m a -> Waiters m a
    -- | Perform an action only if there are no waiters.
    Without :: m a -> Waiters m ()
    -- | Wait for there to be no waiters, then perform the passed action.
    Wait :: m a -> Waiters m a


makeEffect ''Waiters


run :: (Concurrent :> es) => Eff (Waiters : es) a -> Eff es a
run act = do
    waiters <- newTVarIO (0 :: Int)
    interpretWith act \env -> \case
        With m -> localSeqUnlift env \unlift -> do
            bracket_
                (atomically $ modifyTVar' waiters (+ 1))
                (atomically $ modifyTVar' waiters (max 0 . subtract 1))
                $ unlift m
        Without m -> localSeqUnlift env \unlift -> do
            noWaiters <- atomically do
                n <- readTVar waiters
                pure (n <= 0)
            when noWaiters do
                void $ unlift m
        Wait m -> localSeqUnlift env \unlift -> do
            atomically do
                n <- readTVar waiters
                when (n > 0) retry
            unlift m
