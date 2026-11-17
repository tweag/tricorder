module Tricorder.Build.Diagnostic (Diagnostic (..)) where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generically (..))

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
    deriving (FromJSON, ToJSON) via Generically Diagnostic
