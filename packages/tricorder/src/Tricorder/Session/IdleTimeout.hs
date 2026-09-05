module Tricorder.Session.IdleTimeout (IdleTimeout (..)) where

import Atelier.Time (AsRawUnit (..), Second)
import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))


newtype IdleTimeout = IdleTimeout {getIdleTimeout :: Second}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via AsRawUnit Second


instance Default IdleTimeout where
    def = IdleTimeout 300
