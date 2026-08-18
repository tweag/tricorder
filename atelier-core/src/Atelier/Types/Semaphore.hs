-- | If you need a semaphore that works in 'STM', use
-- 'Atelier.Types.Semaphore.STM'.
module Atelier.Types.Semaphore
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

import Effectful.Concurrent.STM (Concurrent, atomically)

import Atelier.Types.Semaphore.STM (Semaphore, withSemaphore)

import Atelier.Types.Semaphore.STM qualified as STM


-- | Creates a new, unset semaphore. Waiting on this semaphore immediately will
-- block.
new :: (Concurrent :> es) => Eff es Semaphore
new = atomically STM.new


-- | Creates a new, set semaphore. Signalling on this semaphore immediately
-- will block.
newSet :: (Concurrent :> es) => Eff es Semaphore
newSet = atomically STM.newSet


-- | Wait for a semaphore to be set. Blocks and waits for the semaphore to be
-- set if it is not already set.
wait :: (Concurrent :> es) => Semaphore -> Eff es ()
wait = atomically . STM.wait


-- | Ensures a semaphore is unset. Returns @True@ if the semaphore was set.
unset :: (Concurrent :> es) => Semaphore -> Eff es Bool
unset = atomically . STM.unset


-- | Set a semaphore. Blocks and waits if the semaphore is already set.
signal :: (Concurrent :> es) => Semaphore -> Eff es ()
signal = atomically . STM.signal


-- | Ensures a semaphore is set. Returns @True@ if the semaphore was not
-- already set.
set :: (Concurrent :> es) => Semaphore -> Eff es Bool
set = atomically . STM.set


-- | Check if a semaphore is set, without changing its state. Returns @True@ if
-- the semaphore is set, @False@ otherwise.
peek :: (Concurrent :> es) => Semaphore -> Eff es Bool
peek = atomically . STM.peek
