module Tricorder.Build
    ( BuildState (..)
    , BuildId (..)
    , BuildPhase (..)
    , BuildProgress (..)
    , BuildResult (..)
    , PostBuild (..)
    , Diagnostic (..)
    , Severity (..)
    ) where

import Atelier.Effects.Clock (UTCTime)
import Atelier.Time (Millisecond)
import Data.Aeson (FromJSON (..), ToJSON (..), withText)
import GHC.Generics (Generically (..))

import Tricorder.Daemon.DaemonInfo (DaemonInfo)
import Tricorder.Session (TestTarget)

import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Test qualified as Test


data BuildState = BuildState
    { daemonInfo :: DaemonInfo
    , phase :: BuildPhase
    , buildId :: BuildId
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildState


newtype BuildId = BuildId {getBuildId :: Int}
    deriving stock (Eq, Show)
    deriving (FromJSON, Num, ToJSON) via Int


data BuildPhase
    = Starting
    | Building [TestTarget] BuildProgress
    | Failed Text
    | PostBuilding BuildResult PostBuild
    | Finished BuildResult PostBuild
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildPhase


data BuildProgress = BuildProgress
    { compiled :: Int
    , total :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildProgress


data BuildResult = BuildResult
    { completedAt :: UTCTime
    , duration :: Millisecond
    , moduleCount :: Int
    , diagnostics :: [Diagnostic]
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildResult


data PostBuild = PostBuild
    { testSuites :: Test.Suites
    , evalComments :: Eval.Phase
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically PostBuild


data Diagnostic = Diagnostic
    { severity :: Severity
    , file :: FilePath
    , line :: Int
    , col :: Int
    , endLine :: Int
    , endCol :: Int
    , title :: Text
    , text :: Text
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically Diagnostic


data Severity = SError | SWarning
    deriving stock (Eq, Ord, Show)


instance FromJSON Severity where
    parseJSON = withText "Severity" \case
        "error" -> pure SError
        "warning" -> pure SWarning
        other -> fail $ "unknown severity: " <> toString other


instance ToJSON Severity where
    toJSON SError = "error"
    toJSON SWarning = "warning"
