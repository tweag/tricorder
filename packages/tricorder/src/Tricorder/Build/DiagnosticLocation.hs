module Tricorder.Build.DiagnosticLocation (DiagnosticLocation (..), map) where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generically (..))
import Prelude hiding (map)

import Atelier.FileSystem.Path qualified as Path


data DiagnosticLocation
    = Locationless
    | Location Path.Any
    deriving stock (Eq, Generic, Ord, Show)
    deriving (FromJSON, ToJSON) via Generically DiagnosticLocation


instance ToText DiagnosticLocation where
    toText = \case
        Locationless -> "<no location info>"
        Location path -> toText path


map :: (Path.Any -> Path.Any) -> DiagnosticLocation -> DiagnosticLocation
map _ Locationless = Locationless
map f (Location path) = Location $ f path
