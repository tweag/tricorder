module Tricorder.Session.GenerateWithHpack (GenerateWithHpack (..)) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))


newtype GenerateWithHpack = GenerateWithHpack {getGenerateWithHpack :: Bool}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Bool


instance Default GenerateWithHpack where
    def = GenerateWithHpack True
