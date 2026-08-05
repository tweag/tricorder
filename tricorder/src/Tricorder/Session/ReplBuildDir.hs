module Tricorder.Session.ReplBuildDir (ReplBuildDir (..)) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))


newtype ReplBuildDir = ReplBuildDir {getReplBuildDir :: FilePath}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via FilePath


instance Default ReplBuildDir where
    def = ReplBuildDir "/tmp"
