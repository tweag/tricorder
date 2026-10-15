module Tricorder.Daemon.Ghci.Config (Config (..)) where

import Atelier.Time (Second)
import Data.Default (Default (..))


-- | Configuration for GHCi process management.
data Config = Config
    { startupTimeout :: Second
    -- ^ How long to wait for the GHCi version banner on startup.
    , shutdownTimeout :: Second
    -- ^ How long to wait for the process to exit gracefully before force-killing.
    , extraSetupCommands :: [Text]
    -- ^ Additional GHCi commands to send after the fixed setup block.
    -- Use this to inject session-wide options such as @:set -XOverloadedStrings@.
    }


instance Default Config where
    def =
        Config
            { startupTimeout = 60
            , shutdownTimeout = 5
            , extraSetupCommands = []
            }
