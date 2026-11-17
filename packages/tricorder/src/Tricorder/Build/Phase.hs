module Tricorder.Build.Phase (Phase (..)) where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generically (..))

import Tricorder.Build.PostBuild (PostBuild)
import Tricorder.Build.Progress (Progress)
import Tricorder.Build.Result (Result)
import Tricorder.Session.TestTarget (TestTarget)


data Phase
    = Starting
    | Building [TestTarget] Progress
    | Failed Text
    | PostBuilding Result PostBuild
    | Finished Result PostBuild
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically Phase
