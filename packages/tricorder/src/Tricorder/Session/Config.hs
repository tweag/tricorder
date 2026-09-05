module Tricorder.Session.Config (Config (..)) where

import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Data.Aeson (FromJSON (..))
import Data.Default (Default (..))

import Tricorder.Session.Hooks (Hooks)


data Config = Config
    { command :: Maybe Text
    , targets :: [Text]
    , watchDirs :: [FilePath]
    , watchExclusionPatterns :: [Text]
    , testTargets :: Maybe [Text]
    , replBuildDir :: FilePath
    , testTimeout :: Int
    , generateWithHpack :: Bool
    , testMemoryLimit :: Maybe Text
    , hooks :: Maybe Hooks
    , idleTimeoutSeconds :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via WithDefaults (QuietSnake Config)


instance Default Config where
    def =
        Config
            { command = Nothing
            , targets = []
            , watchDirs = []
            , watchExclusionPatterns = []
            , testTargets = Nothing
            , replBuildDir = "dist-newstyle/tricorder"
            , testTimeout = 10
            , generateWithHpack = True
            , testMemoryLimit = Nothing
            , hooks = Nothing
            , idleTimeoutSeconds = 300
            }
