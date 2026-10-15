module Tricorder.Daemon.Ghci.InterruptDecision
    ( InterruptDecision (..)
    , decide
    )
where

import Tricorder.Daemon.Ghci.Session.State qualified as Session (State)
import Tricorder.Daemon.Ghci.Session.State qualified as Session.State


-- | The outcome of consulting the 'SessionState' when an interrupt arrives.
--
-- 'NoOpIdle' means the GHCi session is at the prompt — sending SIGINT and a
-- sync marker would dirty the buffers and desync the next 'execGhci'.
-- 'SendInterruptFor n' means a command was in flight (state 'Busy n') and
-- the caller should SIGINT the process group and re-write @markerFor n@ (that
-- command's own marker) to unblock the in-progress 'drainUntil'.
data InterruptDecision
    = NoOpIdle
    | SendInterruptFor Int
    deriving stock (Eq, Show)


-- | Pure state machine for 'interruptGhci'. Returns the new 'SessionState'
-- to install along with the 'InterruptDecision' the caller should act on.
decide :: Session.State -> (Session.State, InterruptDecision)
decide s@(Session.State.Idle _) = (s, NoOpIdle)
decide (Session.State.Busy n) = (Session.State.Idle (n + 1), SendInterruptFor n)
