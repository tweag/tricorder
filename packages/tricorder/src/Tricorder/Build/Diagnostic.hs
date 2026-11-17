module Tricorder.Build.Diagnostic (Diagnostic (..)) where

import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON, ToJSON)

import Tricorder.Build.DiagnosticLocation (DiagnosticLocation)
import Tricorder.Build.Severity (Severity)


data Diagnostic = Diagnostic
    { severity :: Severity
    , file :: DiagnosticLocation
    , line :: Int
    , col :: Int
    , endLine :: Int
    , endCol :: Int
    , title :: Text
    , text :: Text
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake Diagnostic
