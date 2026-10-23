module Tricorder.Session.Config (Config (..)) where

import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Atelier.Types.JSON.Renamed (Renamed)
import Atelier.Types.JSON.WithDefaults (WithDefaults (..))
import Data.Aeson (FromJSON (..), ToJSON)
import Data.Default (Default (..))

import Tricorder.Session.CommandConfig (CommandConfig)
import Tricorder.Session.Hooks (Hooks)
import Tricorder.Session.Stage.Test.Config (TestConfig)

import Tricorder.Session.Stage qualified as Stage


data Config = Config
    { build :: CommandConfig 'Stage.Build
    , test :: TestConfig
    , eval :: CommandConfig 'Stage.Eval
    , watchDirs :: [FilePath]
    , watchExclusionPatterns :: [Text]
    , replBuildDir :: FilePath
    , testTimeout :: Maybe (Renamed "test_timeout" "test.timeout_ms")
    , testMemoryLimit :: Maybe (Renamed "test_memory_limit" "test.memory_limit")
    , generateWithHpack :: Bool
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
    deriving (ToJSON) via QuietSnake Config
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
            , testTimeout = Nothing
            , testMemoryLimit = Nothing
            , generateWithHpack = True
            , hooks = Nothing
            , idleTimeoutSeconds = 300
            , command = Nothing
            , targets = []
            , testTargets = Nothing
            }
