module Tricorder.Daemon.IdleTimer
    ( IdleTimer
    , withActivity
    , quitOnTimeout
    )
where

import Atelier.Effects.Clock (Clock, currentTime)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Exit (Exit, exitSuccess)
import Atelier.Effects.Input (Input, input)
import Atelier.Effects.Log (Log)
import Atelier.Time (Second, nominalDiffTime)
import Data.Time (NominalDiffTime, diffUTCTime)
import Effectful (Effect, Limit (..), Persistence (..), UnliftStrategy (..))
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically, modifyTVar', newTVarIO, readTVar, writeTVar)
import Effectful.Dispatch.Dynamic (interpretWith, localUnlift)
import Effectful.Exception (finally)
import Effectful.TH (makeEffect)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.Log qualified as Log

import Tricorder.Session.IdleTimeout (IdleTimeout (..))


-- | Performs an interpreter-specific action after a certain amount of time has
-- passed without activity.
data IdleTimer :: Effect where
    WithActivity :: m a -> IdleTimer m a


makeEffect ''IdleTimer


-- | Run the idle timer, shutting the process down once
-- @idle_timeout_seconds@ elapses with no open connections. A timeout of zero
-- or less disables shutdown.
--
-- The timeout is read from 'Session' on every check rather than captured once,
-- so config reloads apply to a daemon that is already idle — within
-- 'maxCheckInterval', which bounds how long the check sleeps. Shutdown itself
-- still happens at the deadline, not at a check boundary: the last sleep is
-- trimmed to the exact time remaining.
quitOnTimeout
    :: ( Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Delay :> es
       , Exit :> es
       , Input IdleTimeout :> es
       , Log :> es
       )
    => Eff (IdleTimer : es) a -> Eff es a
quitOnTimeout act = do
    startedAt <- currentTime
    lastActivity <- newTVarIO startedAt
    activeActions <- newTVarIO (0 :: Int)

    Conc.fork_ $ Log.withNamespace "IdleTimer" $ forever do
        idleTimeout <- input
        case idleTimeout of
            -- Disabled, but keep checking so re-enabling it via a config
            -- reload is still picked up.
            IdleTimeout secs | secs <= 0 -> Delay.wait maxCheckInterval
            IdleTimeout secs -> do
                now <- currentTime
                (connections, idleSince) <- atomically do
                    (,) <$> readTVar activeActions <*> readTVar lastActivity
                let remaining = fromIntegral secs - diffUTCTime now idleSince
                if connections > 0 || remaining > 0
                    then Delay.wait $ nextCheck connections remaining
                    else do
                        Log.info
                            $ "Idle for "
                                <> show secs
                                <> " with no active connections, shutting down."
                        exitSuccess

    interpretWith act \env -> \case
        WithActivity action -> do
            start <- currentTime
            atomically do
                modifyTVar' activeActions (+ 1)
                writeTVar lastActivity start
            localUnlift env (ConcUnlift Persistent Unlimited) \unlift -> do
                unlift action `finally` do
                    end <- currentTime
                    atomically do
                        modifyTVar' activeActions (max 0 . subtract 1)
                        writeTVar lastActivity end


-- | Longest the idle check will sleep between polls.
--
-- Checking in bounded chunks rather than one sleep until the deadline keeps
-- live config reloads responsive: a changed @idle_timeout_seconds@ (including
-- re-enabling a disabled one) is picked up within this interval. It is kept
-- generous because wake-ups are not free — each one ends the RTS idle period
-- and re-arms idle GC, costing a major collection.
maxCheckInterval :: Second
maxCheckInterval = 60


-- | How long to sleep before the next idle check.
--
-- With connections open the timeout cannot fire, so there is nothing to wait
-- for but a config change. Otherwise sleep until the deadline, capped at
-- 'maxCheckInterval' and floored at one second so a sub-second remainder
-- cannot spin the loop.
nextCheck :: Int -> NominalDiffTime -> Second
nextCheck connections remaining
    | connections > 0 = maxCheckInterval
    | otherwise = max 1 . min maxCheckInterval $ nominalDiffTime remaining
