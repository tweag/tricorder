{-# OPTIONS_GHC -Wno-redundant-constraints #-}

-- | A typed, unbounded channel effect backed by @unagi-chan@.
--
-- Exposes the split in\/out ends of a fast concurrent queue as an effect, plus a
-- batched read ('readChanBatched') for draining several items at once. The
-- 'InChan' and 'OutChan' types are re-exported so callers need not depend on
-- @unagi-chan@ directly.
--
-- @
-- -- write a few items (writeChan never blocks), then drain them in one batch:
-- pipeline :: (Chan :> es, Timeout :> es) => Eff es (NonEmpty Int)
-- pipeline = do
--     (inn, out) <- newChan
--     traverse_ (writeChan inn) [1 .. 10]
--     readChanBatched (50 :: Millisecond) 100 out   -- one blocking read, up to 100 items
--
-- -- dupChan gives a second, independent read end that sees later writes:
-- broadcast :: (Chan :> es) => Eff es (Int, Int)
-- broadcast = do
--     (inn, out1) <- newChan
--     out2 <- dupChan inn
--     writeChan inn 7
--     (,) <$> readChan out1 <*> readChan out2       -- (7, 7)
-- @
module Atelier.Effects.Chan
    ( -- * Effect
      Chan
    , newChan
    , readChan
    , writeChan
    , dupChan
    , runChan

      -- * Channel Types

      -- | Re-exported from the underlying channel implementation.
      -- Import these from this module rather than directly from Unagi
      -- to maintain abstraction boundaries.
    , InChan
    , OutChan
    , readChanBatched
    )
where

import Control.Concurrent.Chan.Unagi (InChan, OutChan)
import Data.Time.Units (TimeUnit, toMicroseconds)
import Effectful (Dispatch (..), DispatchOf, Effect, IOE)
import Effectful.Dispatch.Static (SideEffects (..), StaticRep, evalStaticRep, unsafeEff_)
import Effectful.State.Static.Shared (evalState, get, modify)
import Effectful.Timeout (Timeout, timeout)

import Control.Concurrent.Chan.Unagi qualified as Unagi


-- | Effect for creating and operating on bidirectional channels.
data Chan :: Effect


type instance DispatchOf Chan = Static WithSideEffects


data instance StaticRep Chan = Chan


-- | Run the 'Chan' effect, allowing channel operations to perform their IO.
runChan :: forall a es. (IOE :> es) => Eff (Chan : es) a -> Eff es a
runChan = evalStaticRep Chan


-- | Create a new channel, returning its write ('InChan') and read ('OutChan')
-- ends.
newChan :: forall a es. (Chan :> es) => Eff es (InChan a, OutChan a)
newChan =
    unsafeEff_ Unagi.newChan


-- | Read the next item from a channel, blocking until one is available.
readChan :: forall a es. (Chan :> es) => OutChan a -> Eff es a
readChan outChan =
    unsafeEff_ $ Unagi.readChan outChan


-- | Write an item to a channel. Never blocks (the channel is unbounded).
writeChan :: forall a es. (Chan :> es) => InChan a -> a -> Eff es ()
writeChan inChan val =
    unsafeEff_ $ Unagi.writeChan inChan val


-- | Duplicate a channel, producing a new read end that observes every item
-- written after the duplication.
dupChan :: forall a es. (Chan :> es) => InChan a -> Eff es (OutChan a)
dupChan inChan =
    unsafeEff_ $ Unagi.dupChan inChan


-- | Read a batch of items from a channel.
--
-- Blocks until at least one item is available, then attempts to read
-- up to @batchSize@ items total within the given timeout. Always returns
-- at least one item.
readChanBatched
    :: forall t a es
     . ( Chan :> es
       , TimeUnit t
       , Timeout :> es
       )
    => t
    -- ^ Timeout for reading additional items after the first
    -> Int
    -- ^ Maximum number of items to read (batch size)
    -> OutChan a
    -- ^ Channel to read from
    -> Eff es (NonEmpty a)
    -- ^ Non-empty batch of items (at least one, up to batch size)
readChanBatched timeoutDuration batchSize outChan = do
    evalState @[a] [] $ do
        h <- readChan outChan -- blocking, get first item
        _ <- timeout (fromIntegral (toMicroseconds timeoutDuration))
            $ replicateM_ (batchSize - 1)
            $ do
                x <- readChan outChan
                modify (x :)
        rest <- get
        pure $ h :| reverse rest
