module Tricorder.Build.Id (Id (..)) where

import Data.Aeson (FromJSON, ToJSON)


newtype Id = Id {getId :: Int}
    deriving stock (Eq, Show)
    deriving (FromJSON, Num, ToJSON) via Int
