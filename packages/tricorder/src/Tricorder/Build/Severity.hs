module Tricorder.Build.Severity (Severity (..)) where

import Data.Aeson (FromJSON (..), ToJSON (..), withText)


data Severity = Error | Warning
    deriving stock (Eq, Ord, Show)


instance FromJSON Severity where
    parseJSON = withText "Severity" \case
        "error" -> pure Error
        "warning" -> pure Warning
        other -> fail $ "unknown severity: " <> toString other


instance ToJSON Severity where
    toJSON Error = "error"
    toJSON Warning = "warning"
