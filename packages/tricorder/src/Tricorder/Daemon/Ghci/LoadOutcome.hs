module Tricorder.Daemon.Ghci.LoadOutcome (LoadOutcome (..)) where


-- | The terminal summary GHCi emits to close a load: @Ok, N modules loaded.@
-- on success or @Failed, …@ on failure.
data LoadOutcome = LoadSucceeded | LoadFailed
    deriving stock (Eq, Show)
