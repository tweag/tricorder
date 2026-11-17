module Tricorder.Build.Progress (Progress (..)) where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generically (..))


data Progress = Progress
    { compiled :: Int
    , total :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically Progress
