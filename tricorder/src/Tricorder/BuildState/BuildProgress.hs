module Tricorder.BuildState.BuildProgress (BuildProgress (..)) where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generically (..))


data BuildProgress = BuildProgress
    { compiled :: Int
    , total :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildProgress
