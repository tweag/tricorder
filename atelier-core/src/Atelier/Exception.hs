{-# OPTIONS_GHC -Wno-redundant-constraints #-}

-- | Helpers for telling synchronous exceptions apart from asynchronous ones.
--
-- Synchronous exceptions are genuine failures worth catching, logging, or
-- retrying; asynchronous ones (thread cancellation, @SIGINT@) usually signal an
-- intentional shutdown and should be allowed to propagate. The @*SyncIO@
-- helpers catch only the former and re-throw the latter.
module Atelier.Exception
    ( isGracefulShutdown
    , trySyncIO
    , catchSyncIO
    , isSyncException
    )
where

import Effectful.Exception (SomeAsyncException, isSyncException)

import Control.Exception qualified as E


-- | Determine if an exception represents a graceful shutdown (any async exception).
--
-- Async exceptions indicate intentional cancellation (e.g., Ki's ScopeClosing,
-- or UserInterrupt from SIGINT), as opposed to real errors that warrant logging
-- or retry logic.
isGracefulShutdown :: SomeException -> Bool
isGracefulShutdown = isJust . fromException @SomeAsyncException


-- | Like `Control.Exception.try`, but will only catch synchronous exceptions.
trySyncIO :: IO a -> IO (Either SomeException a)
trySyncIO f = withFrozenCallStack catchSyncIO (fmap Right f) (pure . Left)


-- | Like @Control.Exception.catch@, but only synchronous exceptions reach the
-- handler; asynchronous exceptions are re-thrown unchanged.
catchSyncIO :: (HasCallStack) => IO a -> (SomeException -> IO a) -> IO a
catchSyncIO f g =
    f `E.catch` \e ->
        if isSyncException e then
            g e
        else
            E.throwIO e
