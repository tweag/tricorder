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
    , BuildProgress (..)
    , BuildResult (..)
    , PostBuild (..)
    , TestPhase (..)
    , EvalPhase (..)
    , EvalRun (..)
    , EvalState (..)
    , TestRun (..)
    , TestRunError (..)
    , TestRunCompletion (..)
    , TestCase (..)
    , TestCaseOutcome (..)
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
import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), withObject, withText, (.:))
import Data.Time (UTCTime)
import Effectful.Reader.Static (Reader, ask)
import GHC.Generics (Generically (..))
import System.FilePath (makeRelative)

import Data.Aeson.KeyMap qualified as KM

import Tricorder.Effects.SessionStore (SessionStore)
import Tricorder.Runtime (LogPath (..), ProjectRoot (..), SocketPath (..))
import Tricorder.Session (Session (..), Target, WatchDirs (..))

import Tricorder.Effects.SessionStore qualified as SessionStore
import Tricorder.Observability qualified as Observability


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
    deriving anyclass (FromJSON, ToJSON)


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


data TestCaseOutcome
    = TestCasePassed
    | TestCaseFailed Text
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data TestCase = TestCase
    { description :: Text
    , outcome :: TestCaseOutcome
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data TestRunError = TestRunError
    { target :: Text
    , message :: Text
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data TestRunCompletion = TestRunCompletion
    { target :: Text
    , passed :: Bool
    , output :: Text
    , testCases :: [TestCase]
    , duration :: Maybe Millisecond
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data TestRun
    = TestRunning Text (Maybe BuildProgress)
    | TestRunErrored TestRunError
    | TestRunCompleted TestRunCompletion
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data BuildResult = BuildResult
    { completedAt :: UTCTime
    , duration :: Millisecond
    , moduleCount :: Int
    , diagnostics :: [Diagnostic]
    , testRuns :: [TestRun]
    , evalRuns :: [EvalRun]
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data EvalState
    = -- | The eval comment has yet to complete evaluation.
      EvalPending
    | -- | Combined stdout+stderr from GHCi, or an error message.
      EvalCompleted Text
    deriving stock (Eq, Generic, Show)


instance ToJSON EvalState where
    toJSON = \case
        EvalPending ->
            toJSON
                $ KM.fromList
                    [ ("state", String "pending")
                    ]
        EvalCompleted output ->
            toJSON
                $ KM.fromList
                    [ ("state", String "completed")
                    , ("output", String output)
                    ]


instance FromJSON EvalState where
    parseJSON = withObject "EvalState" \o -> do
        state :: Text <- o .: "state"
        case state of
            "pending" -> pure $ EvalPending
            "completed" -> do
                output <- o .: "output"
                pure $ EvalCompleted output
            _ -> fail "invalid 'state' property"


data EvalRun = EvalRun
    { file :: FilePath
    -- ^ Source file path, relative to the project root.
    , line :: Int
    -- ^ 1-based line number of the eval comment.
    , expression :: Text
    -- ^ The expression that was evaluated.
    , state :: EvalState
    -- ^ The current state of this particular eval comment run.
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically EvalRun


data BuildProgress = BuildProgress
    { compiled :: Int
    , total :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data BuildPhase
    = Building (Maybe BuildProgress)
    | Restarting
    | BuildComplete PostBuild
    | BuildFailed Text
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data PostBuild = PostBuild
    { testPhase :: TestPhase
    , evalPhase :: EvalPhase
    , result :: BuildResult
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically PostBuild


data TestPhase = Testing | DoneTesting
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically TestPhase


data EvalPhase = EvaluatingComments | DoneEvaluatingComments
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically EvalPhase


data BuildState = BuildState
    { buildId :: BuildId
    , phase :: BuildPhase
    , daemonInfo :: DaemonInfo
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


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
    deriving anyclass (FromJSON, ToJSON)


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
stateLabel (BuildComplete (PostBuild Testing _ _)) = "testing"
stateLabel (BuildComplete (PostBuild _ EvaluatingComments _)) = "evaluating comments"
stateLabel (BuildComplete (PostBuild _ _ result))
    | any (\m -> m.severity == SError) result.diagnostics = "error"
    | any (\m -> m.severity == SWarning) result.diagnostics = "warning"
    | otherwise = "ok"
stateLabel (BuildFailed _) = "error"


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
