module Atelier.Types.JsonReadShow
    {-# DEPRECATED "Use Atelier.Types.JSON.ReadShow instead" #-}
    (JsonReadShow (..))
where

import Data.Aeson (FromJSON, ToJSON)

import Atelier.Types.JSON.ReadShow (ReadShow (..))


newtype JsonReadShow a = JsonReadShow {getJsonReadShow :: a}
    deriving (FromJSON, ToJSON) via ReadShow a
