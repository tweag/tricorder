module Tricorder.Daemon.BuildState (BuildState (..)) where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generically (..))

import Tricorder.BuildState (BuildId)
import Tricorder.Daemon.DaemonInfo (DaemonInfo)
import Tricorder.Daemon.Progress (Progress)


data BuildState = BuildState
    { daemonInfo :: DaemonInfo
    , progress :: Progress
    , buildId :: BuildId
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildState
