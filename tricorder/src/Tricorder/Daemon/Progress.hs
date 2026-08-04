module Tricorder.Daemon.Progress (Progress (..)) where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generically (..))

import Tricorder.BuildState (BuildResult (..), PostBuild)
import Tricorder.BuildState.BuildProgress (BuildProgress)
import Tricorder.Session (TestTargets)


data Progress
    = Starting
    | Building TestTargets BuildProgress
    | Failed Text
    | PostBuilding BuildResult PostBuild
    | Finished BuildResult PostBuild
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically Progress
