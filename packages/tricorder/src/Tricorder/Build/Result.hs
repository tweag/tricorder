module Tricorder.Build.Result (Result (..)) where

import Atelier.Effects.Clock (UTCTime)
import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON, ToJSON)

import Tricorder.Build.Diagnostic (Diagnostic)
import Tricorder.Build.Duration (Duration)


data Result = Result
    { completedAt :: UTCTime
    , duration :: Duration
    , moduleCount :: Int
    , diagnostics :: [Diagnostic]
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake Result
