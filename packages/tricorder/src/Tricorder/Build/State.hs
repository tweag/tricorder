module Tricorder.Build.State (State (..)) where

import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON, ToJSON)

import Tricorder.Build.Id (Id)
import Tricorder.Build.Phase (Phase)


data State = State
    { phase :: Phase
    , buildId :: Id
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake State
