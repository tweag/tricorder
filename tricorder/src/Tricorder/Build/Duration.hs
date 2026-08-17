module Tricorder.Build.Duration (Duration (..)) where

import Atelier.Time (AsRawUnit (..), Millisecond)
import Data.Aeson (FromJSON, ToJSON)


newtype Duration = Duration {getDuration :: Millisecond}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via AsRawUnit Millisecond
