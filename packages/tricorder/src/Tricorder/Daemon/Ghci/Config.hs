module Tricorder.Daemon.Ghci.Config
    ( Config (..)
    , display
    )
where

import Atelier.Time (Second)
import Data.Default (Default (..))

import Data.Text qualified as T

import Tricorder.Session.Util (displayList, indent)


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
    deriving stock (Eq)


instance Default Config where
    def =
        Config
            { startupTimeout = 60
            , shutdownTimeout = 5
            , extraSetupCommands = []
            }


display :: Config -> Text
display config =
    T.intercalate
        "\n"
        [ "Startup timeout: " <> show config.startupTimeout
        , "Shutdown timeout: " <> show config.shutdownTimeout
        , "Extra setup commands:"
        , indent $ displayList id config.extraSetupCommands
        ]
