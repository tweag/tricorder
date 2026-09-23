module Tricorder.Session.Config (Config (..), CommandConfig (..)) where

import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Data.Aeson (FromJSON (..), ToJSON (..))
import Data.Default (Default (..))

import Tricorder.Session.Hooks (Hooks)
import Tricorder.Session.Stage (Stage)

import Tricorder.Session.Stage qualified as Stage


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


data Config = Config
    { build :: CommandConfig 'Stage.Build
    , test :: CommandConfig 'Stage.Test
    , eval :: CommandConfig 'Stage.Eval
    , watchDirs :: [FilePath]
    , watchExclusionPatterns :: [Text]
    , replBuildDir :: FilePath
    , testTimeout :: Int
    , generateWithHpack :: Bool
    , testMemoryLimit :: Maybe Text
    , hooks :: Maybe Hooks
    , idleTimeoutSeconds :: Int
    , command :: Maybe Text
    -- ^ DEPRECATED: use 'build'.'commandTemplate' instead.
    -- TODO: Remove at or after version 0.8.0.0.
    , targets :: [Text]
    -- ^ DEPRECATED: use 'build'.'targets' instead.
    -- TODO: Remove at or after version 0.8.0.0.
    , testTargets :: Maybe [Text]
    -- ^ DEPRECATED: use 'test'.'targets' instead.
    -- TODO: Remove at or after version 0.8.0.0.
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via WithDefaults (QuietSnake Config)


instance Default Config where
    def =
        Config
            { build = def
            , test = def
            , eval = def
            , watchDirs = []
            , watchExclusionPatterns = []
            , replBuildDir = "dist-newstyle/tricorder"
            , testTimeout = 10
            , generateWithHpack = True
            , testMemoryLimit = Nothing
            , hooks = Nothing
            , idleTimeoutSeconds = 300
            , command = Nothing
            , targets = []
            , testTargets = Nothing
            }
