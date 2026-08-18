-- | A clock effect for reading the current time and time zone.
--
-- Putting wall-clock reads behind an effect keeps time-dependent code testable:
-- 'runClock' uses the system clock, while 'runClockConst', 'runClockState' and
-- 'runClockList' supply deterministic times for tests.
module Atelier.Effects.Clock
    ( Clock
    , UTCTime
    , TimeZone
    , currentTime
    , currentTimeZone
    , runClock
    , runClockConst
    , runClockState
    , runClockList
    )
where

import Data.Time (UTCTime, getCurrentTime)
import Data.Time.LocalTime (TimeZone, getCurrentTimeZone, utc)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_, reinterpret)
import Effectful.State.Static.Shared (State, evalState, get, put)
import Effectful.TH (makeEffect)


-- | Effect for reading the current time and time zone.
data Clock :: Effect where
    -- | The current wall-clock time, in UTC.
    CurrentTime :: Clock m UTCTime
    -- | The system's current time zone.
    CurrentTimeZone :: Clock m TimeZone


makeEffect ''Clock


-- | Interpret 'Clock' against the real system clock.
runClock :: (IOE :> es) => Eff (Clock : es) a -> Eff es a
runClock = interpret_ $ \case
    CurrentTime -> liftIO getCurrentTime
    CurrentTimeZone -> liftIO getCurrentTimeZone


-- | Interpret 'Clock' so 'currentTime' always returns a fixed time. The time
-- zone is reported as 'utc'.
runClockConst :: UTCTime -> Eff (Clock : es) a -> Eff es a
runClockConst time = interpret_ $ \case
    CurrentTime -> pure time
    CurrentTimeZone -> pure utc


-- | Interpret 'Clock' so 'currentTime' reads from a mutable 'State' cell,
-- letting a test advance \"now\" explicitly. The time zone is reported as 'utc'.
runClockState :: (State UTCTime :> es) => Eff (Clock : es) a -> Eff es a
runClockState = interpret_ $ \case
    CurrentTime -> get
    CurrentTimeZone -> pure utc


-- | Scripted interpreter for testing: returns times from a pre-loaded list in
-- order. Each 'currentTime' call pops the next item. Crashes if the list is
-- exhausted.
runClockList :: [UTCTime] -> Eff (Clock : es) a -> Eff es a
runClockList times = reinterpret (evalState times) $ \_ -> \case
    CurrentTime ->
        get >>= \case
            [] -> error "runClockList: no more times in queue"
            t : ts -> put ts >> pure t
    CurrentTimeZone -> pure utc
