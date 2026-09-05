module Tricorder.Session.TestTimeout (TestTimeout (..)) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))


newtype TestTimeout = TestTimeout {getTestTimeout :: Int}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Int


instance Default TestTimeout where
    def = TestTimeout 10
