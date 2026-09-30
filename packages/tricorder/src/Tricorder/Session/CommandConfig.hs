module Tricorder.Session.CommandConfig (CommandConfig (..)) where

import Atelier.Types.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))

import Tricorder.Session.Stage (Stage)


-- | Configuration shared by the @build@, @test@, and @eval@ sections: an
-- optional command template (falls back to Tricorder's automatically
-- resolved command per detected REPL kind when unset), an optional explicit
-- target list, and extra CLI arguments appended to that automatically
-- resolved command.
data CommandConfig (stage :: Stage) = CommandConfig
    { commandTemplate :: Maybe Text
    -- ^ User-provided template string to use for the shell command for the
    -- given stage. Takes priority over 'extraAutoArguments'. The exact
    -- template variable name depends on the stage the 'CommandConfig' is for.
    , targets :: Maybe [Text]
    -- ^ List of targets to run the stage against.
    , extraAutoArguments :: [Text]
    -- ^ Arguments to pass to the Tricorder-detected command for the given
    -- stage. Mutually exclusive with 'commandTemplate'. If both
    -- 'commandTemplate' and 'extraAutoArguments' are set, a warning is logged.
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake (CommandConfig stage)


instance Default (CommandConfig stage) where
    def =
        CommandConfig
            { commandTemplate = Nothing
            , targets = Nothing
            , extraAutoArguments = []
            }
