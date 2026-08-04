-- | Shared wire-protocol vocabulary for the build system.
--
-- Every type here is serialised (most via 'FromJSON' / 'ToJSON') and crosses
-- module boundaries between the daemon, the socket layer, the CLI, the UI,
-- and external clients. Components' /internal/ caches and bookkeeping (e.g.
-- the Builder's per-cycle module map and diagnostic accumulator) do not
-- belong here — they live next to the component that owns them.
module Tricorder.BuildState
    ( BuildId (..)
    -- , BuildState (..)
    , BuildPhase (..)
    , BuildResult (..)
    , PostBuild (..)
    , Diagnostic (..)
    , Severity (..)
    , ChangeKind (..)
    , CabalChangeDetected (..)
    , SourceChangeDetected (..)
    ) where

import Atelier.Effects.FileWatcher (FileEvent)
import Atelier.Time (Millisecond)
import Data.Aeson (FromJSON (..), ToJSON (..), withText)
import Data.Time (UTCTime)
import GHC.Generics (Generically (..))

import Tricorder.BuildState.BuildProgress (BuildProgress)

import Tricorder.BuildState.EvalComments qualified as Eval
import Tricorder.BuildState.Test qualified as Test


newtype BuildId = BuildId {getBuildId :: Int}
    deriving stock (Eq, Show)
    deriving newtype (FromJSON, ToJSON)
    deriving (Num) via Int


data BuildPhase
    = Restarting
    | Building (Maybe BuildProgress)
    | BuildFailed Text
    | BuildComplete BuildResult PostBuild
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildPhase


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


-- | Classifies what kind of file change triggered a dirty signal.
-- 'CabalChange' takes priority over 'SourceChange': if both fire before the
-- next build starts, the session will be fully restarted rather than reloaded.
data ChangeKind = SourceChange | CabalChange deriving stock (Eq, Ord, Show)


data CabalChangeDetected = CabalChangeDetected FilePath FileEvent
    deriving stock (Eq, Show)
data SourceChangeDetected = SourceChangeDetected FilePath FileEvent
    deriving stock (Eq, Show)
