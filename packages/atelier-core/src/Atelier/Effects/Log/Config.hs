module Atelier.Effects.Log.Config
    ( Config (..)
    )
where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))

import Atelier.Effects.Log.Severity (Severity)
import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Atelier.Types.JSON.WithDefaults (WithDefaults (..))


-- | Logging configuration.
data Config = Config
    { minimumSeverity :: Severity
    -- ^ Messages below this severity are discarded.
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via QuietSnake Config
    deriving (FromJSON) via WithDefaults (QuietSnake Config)


instance Default Config where
    def =
        Config
            { minimumSeverity = minBound
            }
