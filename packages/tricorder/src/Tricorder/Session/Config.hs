module Tricorder.Session.Config (Config (..)) where

import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Data.Aeson (FromJSON (..))
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
