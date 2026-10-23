-- | An effect for bounding a computation by a wall-clock deadline.
module Atelier.Effects.Timeout
    ( Timeout
    , with
    , with_
    , run
    )
where

import Effectful
    ( Dispatch (..)
    , DispatchOf
    , Effect
    , IOE
    , Limit (..)
    , Persistence (..)
    )
import Effectful.Dispatch.Static
    ( SideEffects (..)
    , StaticRep
    , concUnliftIO
    , evalStaticRep
    , getStaticRep
    , unsafeEff
    )

import System.Timeout qualified as IO

import Atelier.Time (TimeUnit (..))


-- | Effect for bounding a computation by a wall-clock deadline.
data Timeout :: Effect


type instance DispatchOf Timeout = Static 'WithSideEffects


data instance StaticRep Timeout = Timeout


-- | Run an action, returning 'Just' its result if it completes within the
-- duration, or 'Nothing' if the deadline passes first.
--
-- 'timeout' runs an action, returning 'Nothing' if it does not finish within
-- the given 'TimeUnit' duration; 'timeout_' is the variant that discards the
-- result. When the deadline passes the action is cancelled with an asynchronous
-- exception.
--
-- @
-- result <- Timeout.with (5 :: Second) fetchRemote
-- case result of
--     Just value -> use value
--     Nothing    -> logWarn \"fetch timed out\"
-- @
with :: (TimeUnit t, Timeout :> es) => t -> Eff es a -> Eff es (Maybe a)
with delay action = do
    Timeout <- getStaticRep
    unsafeEff \env -> do
        concUnliftIO env Persistent (Limited 1) \unlift ->
            IO.timeout (fromIntegral $ toMicroseconds delay) $ unlift action


-- | Like 'timeout', but for times where you do not need the result. If you
-- need to distinguish whether the action ran to completion, or whether it
-- timed out, you should use 'timeout'.
with_ :: (TimeUnit t, Timeout :> es) => t -> Eff es a -> Eff es ()
with_ t m = const () <$> with t m


-- | Interpret 'Timeout' using 'System.Timeout.timeout'.
run :: (HasCallStack, IOE :> es) => Eff (Timeout : es) a -> Eff es a
run = evalStaticRep Timeout
