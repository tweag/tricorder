-- | Shared wire-protocol vocabulary for the build system.
--
-- Every type here is serialised (most via 'FromJSON' / 'ToJSON') and crosses
-- module boundaries between the daemon, the socket layer, the CLI, the UI,
-- and external clients. Components' /internal/ caches and bookkeeping (e.g.
-- the Builder's per-cycle module map and diagnostic accumulator) do not
-- belong here — they live next to the component that owns them.
module Tricorder.BuildState
    ( BuildId (..)
    , BuildState (..)
    , BuildPhase (..)
    , PostBuild (..)
    , BuildResult (..)
    , DaemonInfo (..)
    , loadDaemonInfo
    , runDaemonInfo
    , Diagnostic (..)
    , Severity (..)
    , ChangeKind (..)
    , initialBuildState
    , stateLabel
    , CabalChangeDetected (..)
    , SourceChangeDetected (..)
    ) where

import Atelier.Effects.FileWatcher (FileEvent)
import Atelier.Effects.Input (Input, runInputEff)
import Atelier.Time (Millisecond)
import Data.Aeson (FromJSON (..), ToJSON (..), withText)
import Data.Time (UTCTime)
import Effectful.Reader.Static (Reader, ask)
import GHC.Generics (Generically (..))
import System.FilePath (makeRelative)

import Tricorder.BuildState.BuildProgress (BuildProgress)
import Tricorder.Effects.SessionStore (SessionStore)
import Tricorder.Runtime (LogPath (..), ProjectRoot (..), SocketPath (..))
import Tricorder.Session (Session (..), Target, WatchDirs (..))

import Tricorder.BuildState.Test qualified as Test
import Tricorder.BuildState.Test qualified as Tests
import Tricorder.Effects.SessionStore qualified as SessionStore
import Tricorder.Observability qualified as Observability


data BuildState = BuildState
    { buildId :: BuildId
    , phase :: BuildPhase
    , daemonInfo :: DaemonInfo
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildState


newtype BuildId = BuildId Int
    deriving stock (Eq, Show)
    deriving newtype (FromJSON, ToJSON)
    deriving (Num) via Int


data DaemonInfo = DaemonInfo
    { targets :: [Target]
    , watchDirs :: [FilePath]
    , sockPath :: FilePath
    , logFile :: FilePath
    , metricsPort :: Maybe Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically DaemonInfo


loadDaemonInfo
    :: ( Reader LogPath :> es
       , Reader Observability.Config :> es
       , Reader ProjectRoot :> es
       , Reader SocketPath :> es
       , SessionStore :> es
       )
    => Eff es DaemonInfo
loadDaemonInfo = do
    session <- SessionStore.get
    obsCfg <- ask @Observability.Config
    ProjectRoot projectRoot <- ask
    SocketPath sockPath <- ask
    LogPath logFile <- ask
    pure
        $ DaemonInfo
            { targets = session.targets
            , watchDirs = map (makeRelative projectRoot) session.watchDirs.getWatchDirs
            , sockPath
            , logFile
            , metricsPort = if obsCfg.metrics.enabled then Just obsCfg.metrics.port else Nothing
            }


runDaemonInfo
    :: ( Reader LogPath :> es
       , Reader Observability.Config :> es
       , Reader ProjectRoot :> es
       , Reader SocketPath :> es
       , SessionStore :> es
       )
    => Eff (Input DaemonInfo : es) a -> Eff es a
runDaemonInfo = runInputEff loadDaemonInfo


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


stateLabel :: BuildPhase -> Text
stateLabel (Building _) = "building"
stateLabel Restarting = "restarting"
stateLabel (BuildFailed _) = "error"
stateLabel (BuildComplete result postBuild)
    | any (\m -> m.severity == SError) result.diagnostics = "error"
    | any (\m -> m.severity == SWarning) result.diagnostics = "warning"
    | Tests.anyRunningTests postBuild.testSuites = "testing"
    | otherwise = "ok"


-- | Classifies what kind of file change triggered a dirty signal.
-- 'CabalChange' takes priority over 'SourceChange': if both fire before the
-- next build starts, the session will be fully restarted rather than reloaded.
data ChangeKind = SourceChange | CabalChange deriving stock (Eq, Ord, Show)


data CabalChangeDetected = CabalChangeDetected FilePath FileEvent
    deriving stock (Eq, Show)
data SourceChangeDetected = SourceChangeDetected FilePath FileEvent
    deriving stock (Eq, Show)


initialBuildState :: DaemonInfo -> BuildState
initialBuildState di =
    BuildState
        { buildId = BuildId 0
        , phase = Building Nothing
        , daemonInfo = di
        }
