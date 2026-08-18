-- | STM variant of 'Atelier.Types.Semaphore'.
module Atelier.Types.Semaphore.STM
    ( Semaphore
    , new
    , newSet
    , wait
    , signal
    , unset
    , set
    , peek
    , withSemaphore
    )
where

import Effectful.Concurrent.STM
    ( Concurrent
    , STM
    , TMVar
    , atomically
    , isEmptyTMVar
    , newEmptyTMVar
    , newTMVar
    , putTMVar
    , takeTMVar
    , tryPutTMVar
    , tryTakeTMVar
    )
import Effectful.Exception (bracket_)


-- | A flag for threads to either wait to be set, or signal to other processes
-- to continue. A synchronization primitive.
--
-- Using 'wait' on an unset semaphore blocks.
-- Using 'signal' on a set semaphore blocks.
-- All other operations do not block.
--
-- Using 'wait' on a semaphore makes it unset once the wait resolves.
-- Using 'signal' on a semaphore makes it set once the signal resolves.
newtype Semaphore = Semaphore (TMVar ())


-- | Creates a new, unset semaphore. Waiting on this semaphore immediately will
-- block.
new :: STM Semaphore
new = Semaphore <$> newEmptyTMVar


-- | Creates a new, set semaphore. Signalling on this semaphore immediately
-- will block.
newSet :: STM Semaphore
newSet = Semaphore <$> newTMVar ()


-- | Wait for a semaphore to be set. Blocks and waits for the semaphore to be
-- set if it is not already set.
wait :: Semaphore -> STM ()
wait (Semaphore ref) = takeTMVar ref


-- | Ensures a semaphore is unset. Returns @True@ if the semaphore was set.
unset :: Semaphore -> STM Bool
unset (Semaphore ref) = isJust <$> tryTakeTMVar ref


-- | Set a semaphore. Blocks and waits if the semaphore is already set.
signal :: Semaphore -> STM ()
signal (Semaphore ref) = putTMVar ref ()


-- | Ensures a semaphore is set. Returns @True@ if the semaphore was not
-- already set.
set :: Semaphore -> STM Bool
set (Semaphore ref) = tryPutTMVar ref ()


-- | Check if a semaphore is set, without changing its state. Returns @True@ if
-- the semaphore is set, @False@ otherwise.
peek :: Semaphore -> STM Bool
peek (Semaphore ref) = not <$> isEmptyTMVar ref


-- | Waits for exclusive access to the semaphore before running a computation,
-- ensuring it is set before starting, and that it is signalled afterwards.
-- If another thread signals or sets the semaphore in the meantime, the caller
-- will _not_ be blocked when attempting to signal the semaphore afterwards.
withSemaphore :: (Concurrent :> es) => Semaphore -> Eff es a -> Eff es a
withSemaphore ref = bracket_ (atomically $ wait ref) (atomically $ set ref)
