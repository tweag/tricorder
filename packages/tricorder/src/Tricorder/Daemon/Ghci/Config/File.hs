module Tricorder.Daemon.Ghci.Config.File
    ( File (..)
    , toConfig
    )
where

import Atelier.Time (AsRawUnit (..), Millisecond)
import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults
    ( WithDefaults (..)
    )
import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))

import Atelier.Time qualified as Time

import Tricorder.Daemon.Ghci.Config
    ( Config (..)
    )


data File = File
    { startupTimeoutMs :: Maybe (AsRawUnit Millisecond)
    -- ^ How long to wait for the GHCi version banner on startup.
    , shutdownTimeoutMs :: Maybe (AsRawUnit Millisecond)
    -- ^ How long to wait for the process to exit gracefully before force-killing.
    , extraSetupCommands :: Maybe [Text]
    -- ^ Additional GHCi commands to send after the fixed setup block.
    -- Use this to inject session-wide options such as @:set -XOverloadedStrings@.
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via QuietSnake File
    deriving (FromJSON) via WithDefaults (QuietSnake File)


instance Default File where
    def = File Nothing Nothing Nothing


toConfig :: File -> Config
toConfig file =
    Config
        { startupTimeout = maybe cfg.startupTimeout (Time.convertUnit . getAsRawUnit) file.startupTimeoutMs
        , shutdownTimeout = maybe cfg.shutdownTimeout (Time.convertUnit . getAsRawUnit) file.shutdownTimeoutMs
        , extraSetupCommands = fromMaybe cfg.extraSetupCommands file.extraSetupCommands
        }
  where
    cfg = def :: Config
