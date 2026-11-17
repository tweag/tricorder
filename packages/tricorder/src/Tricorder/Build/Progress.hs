module Tricorder.Build.Progress (Progress (..)) where

import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON, ToJSON)


data Progress = Progress
    { compiled :: Int
    , total :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake Progress
