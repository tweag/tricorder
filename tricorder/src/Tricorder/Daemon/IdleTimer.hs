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
import Atelier.Time (Second)
import Data.Time (diffUTCTime)
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
-- @idle_timeout_seconds@ (read from 'Session', re-read on every check so
-- config reloads apply live) elapses with no open connections. A timeout of
-- zero or less disables shutdown.
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
        Delay.wait (2 :: Second)
        idleTimeout <- input
        case idleTimeout of
            IdleTimeout secs | secs <= 0 -> pure ()
            IdleTimeout secs -> do
                now <- currentTime
                shouldExit <- atomically do
                    connections <- readTVar activeActions
                    idleSince <- readTVar lastActivity
                    pure $ connections <= 0 && diffUTCTime now idleSince >= fromIntegral secs
                when shouldExit do
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
