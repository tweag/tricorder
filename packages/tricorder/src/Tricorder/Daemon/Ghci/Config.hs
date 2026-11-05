module Tricorder.Daemon.Ghci.Config
    ( Config (..)
    , display
    )
where

import Atelier.Time (AsRawUnit (..), Second)
import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Data.Aeson (ToJSON)
import Data.Default (Default (..))

import Data.Text qualified as T

import Tricorder.Session.Util (displayList, indent)


-- | Configuration for GHCi process management.
data Config = Config
    { startupTimeout :: AsRawUnit Second
    -- ^ How long to wait for the GHCi version banner on startup.
    , shutdownTimeout :: AsRawUnit Second
    -- ^ How long to wait for the process to exit gracefully before force-killing.
    , extraSetupCommands :: [Text]
    -- ^ Additional GHCi commands to send after the fixed setup block.
    -- Use this to inject session-wide options such as @:set -XOverloadedStrings@.
    }
    deriving stock (Eq, Generic)
    deriving (ToJSON) via QuietSnake Config


instance Default Config where
    def =
        Config
            { startupTimeout = AsRawUnit 60
            , shutdownTimeout = AsRawUnit 5
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
