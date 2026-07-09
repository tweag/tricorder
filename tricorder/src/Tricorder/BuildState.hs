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
    , CyclePhase (..)
    , BuildOutput (..)
    , TestOutput (..)
    , BuildRecord (..)
    , emptyBuildRecord
    , CycleEvent (..)
    , step
    , kHistory
    , currentRecord
    , previousRecord
    , atBuild
    , overCurrentTests
    , overHistoryAt
    , ActiveBuild (..)
    , isSettled
    , isBuilding
    , testsSettled
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
import Data.Aeson (FromJSON (..), FromJSONKey, ToJSON (..), ToJSONKey, withText)
import Data.Time (UTCTime)
import Effectful.Reader.Static (Reader, ask)
import GHC.Generics (Generically (..))
import System.FilePath (makeRelative)

import Data.Map.Strict qualified as Map

import Tricorder.BuildState.BuildProgress (BuildProgress)
import Tricorder.Effects.SessionStore (SessionStore)
import Tricorder.Runtime (LogPath (..), ProjectRoot (..), SocketPath (..))
import Tricorder.Session (Session (..), Target, WatchDirs (..))

import Tricorder.BuildState.Test qualified as Test
import Tricorder.BuildState.Test qualified as Tests
import Tricorder.Effects.SessionStore qualified as SessionStore
import Tricorder.Observability qualified as Observability


-- | The daemon-wide build state.
--
-- Cycle/workflow state ('current', 'cycle') is contended and sequenced by one
-- writer (the reducer, driven via 'CycleEvent'). Producer outputs live in
-- 'history', a @buildId@-keyed accumulator bounded to the last 'kHistory'
-- builds. Each producer writes only @history[current].<its field>@.
data BuildState = BuildState
    { current :: BuildId
    -- ^ The in-flight / most recent build.
    , cycle :: CyclePhase
    -- ^ Phase of 'current' (contended, single sequencer).
    , history :: Map BuildId BuildRecord
    -- ^ Producer outputs, bounded to the last 'kHistory' builds.
    , daemonInfo :: DaemonInfo
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildState


newtype BuildId = BuildId Int
    deriving stock (Eq, Ord, Show)
    deriving newtype (FromJSON, FromJSONKey, ToJSON, ToJSONKey)
    deriving (Num) via Int


-- | The cycle state machine. Lifecycle status only — no producer output.
data CyclePhase
    = Restarting
    | Building (Maybe BuildProgress)
    | -- | The load ran to completion; see @history[current].build@.
      Settled
    | -- | GHCi produced no result at all (startup crash / reload threw).
      Failed Text
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically CyclePhase


-- | The build register: written by the compile step.
data BuildOutput
    = NotBuilt
    | Built BuildResult
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildOutput


-- | The test register: written by the test runner.
data TestOutput
    = TestsIdle
    | TestsRunning Test.Suites
    | TestsDone Test.Suites
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically TestOutput


-- | The per-build accumulator value. Single-writer registers, one per producer.
data BuildRecord = BuildRecord
    { build :: BuildOutput
    , tests :: TestOutput
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildRecord


emptyBuildRecord :: BuildRecord
emptyBuildRecord = BuildRecord {build = NotBuilt, tests = TestsIdle}


-- | Keep this many builds (current + previous). K=2.
kHistory :: Int
kHistory = 2


--------------------------------------------------------------------------------
-- Cycle event + reducer
--------------------------------------------------------------------------------

-- | Inputs to the cycle state machine. The reducer 'step' owns 'current',
-- 'cycle', and the build register. Test/eval producers do NOT emit these.
data CycleEvent
    = -- | Debounced source edit: begin a new build.
      SourceChanged
    | -- | .cabal/package.yaml edit: restart the session.
      CabalChanged
    | -- | A fresh GHCi session came up post-restart.
      SessionStarted
    | -- | @[N of M] Compiling …@ during a load.
      BuildProgressed BuildProgress
    | -- | Load completed and produced a result.
      BuildFinished BuildResult
    | -- | GHCi produced no result (startup crash / reload threw).
      BuildAborted Text
    deriving stock (Eq, Show)


-- | The cycle reducer. Owns 'current', 'cycle', and the build register.
-- Never touches tests/evals.
step :: BuildState -> CycleEvent -> BuildState
step s = \case
    -- A .cabal change wins over everything, including a build that finished a
    -- moment ago. This single clause is the entire Restarting-clobber fix.
    CabalChanged -> s {cycle = Restarting}
    -- New build cycle. Bump the id (per build, so register-tagging can tell
    -- cycles apart); previous builds stay in 'history' (retention), bounded.
    SessionStarted -> beginBuild s
    SourceChanged -> beginBuild s
    -- Progress only advances a live build; a late line never resurrects a
    -- Settled / Restarting / Failed cycle.
    BuildProgressed p -> case s.cycle of
        Building _ -> s {cycle = Building (Just p)}
        _ -> s
    -- Completing a load flips to Settled AND publishes the result atomically,
    -- under the same buildId. A result arriving after a restart is dropped.
    BuildFinished r -> case s.cycle of
        Restarting -> s
        _ ->
            s
                { cycle = Settled
                , history = adjustCurrent (\rec -> rec {build = Built r}) s
                }
    -- GHCi produced no result at all (startup crash, reload threw).
    BuildAborted msg -> case s.cycle of
        Restarting -> s
        _ -> s {cycle = Failed msg}


-- | Start a fresh build: bump 'current', seed an empty record, evict to K.
beginBuild :: BuildState -> BuildState
beginBuild s =
    s
        { current = nextId
        , cycle = Building Nothing
        , history = evictHistory kHistory $ Map.insert nextId emptyBuildRecord s.history
        }
  where
    nextId = s.current + 1


-- | Modify the current build's record (creating it if absent).
adjustCurrent :: (BuildRecord -> BuildRecord) -> BuildState -> Map BuildId BuildRecord
adjustCurrent f s =
    Map.insert s.current (f (currentRecord s)) s.history


-- | Keep the K entries with the largest keys (most recent builds).
evictHistory :: Int -> Map BuildId BuildRecord -> Map BuildId BuildRecord
evictHistory k m
    | Map.size m <= k = m
    | otherwise = Map.fromDistinctAscList $ drop (Map.size m - k) $ Map.toAscList m


--------------------------------------------------------------------------------
-- Selection helpers (keep reader policy DRY)
--------------------------------------------------------------------------------

-- | The current build's record (empty if somehow absent).
currentRecord :: BuildState -> BuildRecord
currentRecord s = Map.findWithDefault emptyBuildRecord s.current s.history


-- | The record of the build immediately before 'current', if retained.
previousRecord :: BuildState -> Maybe BuildRecord
previousRecord s =
    fmap snd $ Map.lookupMax $ Map.delete s.current s.history


atBuild :: BuildId -> BuildState -> Maybe BuildRecord
atBuild bid s = Map.lookup bid s.history


-- | Write the current build's test register. This is the only mutation the
-- test producer can express — it cannot reach the cycle or the build register.
overCurrentTests :: (TestOutput -> TestOutput) -> BuildState -> BuildState
overCurrentTests f s =
    s {history = Map.insert s.current (rec {tests = f rec.tests}) s.history}
  where
    rec = currentRecord s


-- | SPIKE (straggler-safety prototype): write the test register of a
-- /specific/ build, not @current@. A straggling write from build N whose fiber
-- captured @bid = N@ files under @history[N]@ even if @current@ has bumped to
-- N+1. If build N was already evicted from the bounded history, the write is
-- silently dropped (there is nothing to corrupt).
overHistoryAt :: BuildId -> (TestOutput -> TestOutput) -> BuildState -> BuildState
overHistoryAt bid f s = case Map.lookup bid s.history of
    Nothing -> s
    Just rec -> s {history = Map.insert bid (rec {tests = f rec.tests}) s.history}


-- | SPIKE: the ambient \"which build is this fiber working for\" binding,
-- deliberately named distinctly from @state.current@. Bound via 'Reader.local'
-- around a cycle body; read by the test setters to target 'overHistoryAt'.
newtype ActiveBuild = ActiveBuild BuildId
    deriving stock (Eq, Show)


--------------------------------------------------------------------------------
-- Derived views (pure folds over history[current])
--------------------------------------------------------------------------------

testsSettled :: TestOutput -> Bool
testsSettled = \case
    TestsIdle -> True
    TestsDone _ -> True
    TestsRunning _ -> False


-- | What @status --wait@ blocks on: the current cycle has fully come to rest.
isSettled :: BuildState -> Bool
isSettled s = case s.cycle of
    Settled -> testsSettled (currentRecord s).tests
    Failed _ -> True
    Building _ -> False
    Restarting -> False


isBuilding :: BuildState -> Bool
isBuilding = not . isSettled


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


data BuildResult = BuildResult
    { completedAt :: UTCTime
    , duration :: Millisecond
    , moduleCount :: Int
    , diagnostics :: [Diagnostic]
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildResult


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


stateLabel :: BuildState -> Text
stateLabel s = case s.cycle of
    Restarting -> "restarting"
    Building _ -> "building"
    Failed _ -> "error"
    Settled
        | anyError -> "error"
        | anyWarning -> "warning"
        | testsRunning -> "testing"
        | otherwise -> "ok"
  where
    rec = currentRecord s
    (anyError, anyWarning) = case rec.build of
        Built r ->
            ( any (\m -> m.severity == SError) r.diagnostics
            , any (\m -> m.severity == SWarning) r.diagnostics
            )
        NotBuilt -> (False, False)
    testsRunning = case rec.tests of
        TestsRunning suites -> Tests.anyRunningTests suites
        _ -> False


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
        { current = BuildId 0
        , cycle = Building Nothing
        , history = Map.singleton (BuildId 0) emptyBuildRecord
        , daemonInfo = di
        }
