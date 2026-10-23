module Atelier.Effects.Delay
    ( Delay
    , wait
    , every
    , runIO
    , runNoOp
    )
where

import Data.Time.Units (TimeUnit, toMicroseconds)
import Effectful (Effect)
import Effectful.Concurrent (Concurrent, threadDelay)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)


-- | Effect for suspending execution for a given duration.
data Delay :: Effect where
    -- | Halt the thread and wait for the passed duration before continuing.
    Wait :: (TimeUnit t) => t -> Delay m ()


makeEffect ''Delay


-- | Runs an action repeatedly, waiting the given duration in between each
-- execution, starting immediately.
every :: (Delay :> es, TimeUnit t) => t -> Eff es () -> Eff es Void
every delay action = forever do
    action
    wait delay


-- | Interpret 'Delay' using real thread delays.
runIO :: (Concurrent :> es) => Eff (Delay : es) a -> Eff es a
runIO = interpret_ \(Wait delay) ->
    threadDelay $ fromIntegral (toMicroseconds delay)


-- | Delay interpreter that makes every 'wait' return immediately.
runNoOp :: Eff (Delay : es) a -> Eff es a
runNoOp = interpret_ \(Wait _) -> pure ()
