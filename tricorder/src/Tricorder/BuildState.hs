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
    , Status (..)
    , CyclePhase (..)
    , BuildOutput (..)
    , TestOutput (..)
    , BuildRecord (..)
    , emptyRecord
    , CycleEvent (..)
    , step
    , beginBuild
    , historyBound
    , currentId
    , currentRecord
    , currentBuild
    , currentTests
    , suitesOf
    , atBuild
    , overHistoryAt
    , overCurrent
    , setCurrentBuild
    , setCurrentTests
    , overCurrentTests
    , isDone
    , liveSnapshot
    , BuildResult (..)
    , DaemonInfo (..)
    , loadDaemonInfo
    , runDaemonInfo
    , Diagnostic (..)
    , Severity (..)
    , ChangeKind (..)
    , initialBuildState
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
import Tricorder.Effects.SessionStore qualified as SessionStore
import Tricorder.Observability qualified as Observability


-- | The reduced build state: exactly what build/test/eval events produce.
--
-- Only two fields survive after the proposal-008 refinements:
--
--   * 'cycle'   — the phase state machine, mutated by one sequencer (the
--     reducer, driven via 'CycleEvent'). This is the genuinely contended state.
--   * 'history' — producer outputs, a @'BuildId'@-keyed accumulator bounded to
--     the last 'historyBound' builds. Each producer writes only its own field of
--     @history[currentId]@.
--
-- There is no stored @current@ pointer ('currentId' derives it from the map's
-- greatest key) and no @daemonInfo@ (that is ambient config, joined at the wire
-- edge in 'Status', not produced by any build event).
--
-- NOTE: the field name 'cycle' shadows nothing today only because
-- @atelier-prelude@ does not re-export @Prelude.cycle@. If it ever starts to,
-- this record's @OverloadedRecordDot@ selector and 'Prelude.cycle' would clash;
-- rename the field rather than adding a hiding import.
data BuildState = BuildState
    { cycle :: CyclePhase
    -- ^ Phase of the current build (contended, single sequencer).
    , history :: Map BuildId BuildRecord
    -- ^ Producer outputs, bounded to the last 'historyBound' builds.
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildState


-- | The @status@ wire envelope: the reduced 'BuildState' joined with the
-- ambient daemon configuration at the socket edge (see 'loadDaemonInfo'). The
-- daemon config is read fresh here rather than parked in the reduced state, so a
-- snapshot can never carry a 'DaemonInfo' that lagged a cabal reload.
data Status = Status
    { daemon :: DaemonInfo
    , build :: BuildState
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically Status


newtype BuildId = BuildId Int
    deriving stock (Eq, Ord, Show)
    deriving newtype (FromJSON, FromJSONKey, ToJSON, ToJSONKey)
    deriving (Num) via Int


-- | The cycle state machine. Lifecycle status only — no producer output.
--
-- Done-ness is a pure check over this type ('isDone'); no reader inspects a
-- register to decide what phase the cycle is in.
data CyclePhase
    = -- | Session teardown/reload in progress.
      Restarting
    | -- | A GHCi load is running.
      Building (Maybe BuildProgress)
    | -- | The load produced NO result (startup crash / reload threw).
      BuildFailed Text
    | -- | The build produced a result; post-build analyses (tests, evals) run.
      Analysing
    | -- | The cycle is complete; read @history[currentId].build@ for the result.
      Idle
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically CyclePhase


-- | The build register: written by the compile step (via 'setCurrentBuild').
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


emptyRecord :: BuildRecord
emptyRecord = BuildRecord {build = NotBuilt, tests = TestsIdle}


-- | Keep this many builds (current + previous). Retention/display only, NOT a
-- correctness knob.
historyBound :: Int
historyBound = 2


--------------------------------------------------------------------------------
-- Cycle event + reducer
--------------------------------------------------------------------------------

-- | Inputs to the cycle state machine. The reducer 'step' owns 'cycle' and the
-- structure of 'history' (which build ids exist); it never writes output
-- contents. Test/eval producers do NOT emit these — they write their register
-- directly.
data CycleEvent
    = -- | Debounced source edit: begin a new build.
      SourceChanged
    | -- | .cabal/package.yaml edit: restart the session.
      CabalChanged
    | -- | A fresh GHCi session came up post-restart.
      SessionStarted
    | -- | @[N of M] Compiling …@ during a load.
      BuildProgressed BuildProgress
    | -- | @Building -> Analysing@: a clean build; downstream analyses will run.
      EnterAnalysis
    | -- | @(Building | Analysing) -> Idle@: the cycle finished.
      AnalysisComplete
    | -- | @-> BuildFailed@: GHCi produced no result at all.
      BuildAborted Text
    deriving stock (Eq, Show)


-- | The cycle reducer. A pure phase machine: it owns 'cycle' and the /structure/
-- of 'history' (slot lifecycle), and never writes an output value.
step :: BuildState -> CycleEvent -> BuildState
step s = \case
    -- A .cabal change wins over everything, including a build that finished a
    -- moment ago.
    CabalChanged -> s {cycle = Restarting}
    -- New build cycle. Bump the id (per build), seed an empty record, evict to K.
    SessionStarted -> beginBuild s
    SourceChanged -> beginBuild s
    -- Progress only advances a live build; a late line never resurrects an
    -- Analysing / Idle / Restarting / BuildFailed cycle.
    BuildProgressed p -> case s.cycle of
        Building _ -> s {cycle = Building (Just p)}
        _ -> s
    -- Restarting absorbs every stale terminal transition below (the entire
    -- Restarting-clobber fix); otherwise a clean build enters analysis.
    EnterAnalysis -> unlessRestarting s {cycle = Analysing}
    AnalysisComplete -> unlessRestarting s {cycle = Idle}
    BuildAborted msg -> unlessRestarting s {cycle = BuildFailed msg}
  where
    -- A single home for the Restarting-clobber rule: a stale terminal transition
    -- never overwrites a session restart that has already been queued.
    unlessRestarting new = case s.cycle of
        Restarting -> s
        _ -> new


-- | Start a fresh build: reset the phase, seed an empty record under the next
-- id, evict to K. Total construction; no @mempty@ (there is no lawful Monoid —
-- 'history' must be carried, and the next id is a bump, not a reset).
beginBuild :: BuildState -> BuildState
beginBuild s =
    s
        { cycle = Building Nothing
        , history = evictHistory historyBound (Map.insert next emptyRecord s.history)
        }
  where
    next = maybe (BuildId 0) ((+ 1) . fst) (Map.lookupMax s.history)


-- | Insert-then-keep-last-K. Keys are 'BuildId' (ordered); keep the K greatest.
-- Only ever called right after a single 'Map.insert' (see 'beginBuild'), so the
-- map is over-bound by at most one key — dropping the smallest suffices.
evictHistory :: Int -> Map BuildId BuildRecord -> Map BuildId BuildRecord
evictHistory k m
    | Map.size m > k = Map.deleteMin m
    | otherwise = m


--------------------------------------------------------------------------------
-- Derived current build + selection helpers (keep reader policy DRY)
--------------------------------------------------------------------------------

-- | The current build id: the greatest key present. Not stored — a new build
-- inserts at @max+1@ and eviction only ever drops the smallest keys, so this can
-- never disagree with the map's keys.
currentId :: BuildState -> BuildId
currentId = maybe (BuildId 0) fst . Map.lookupMax . (.history)


-- | The current build's record (empty if somehow absent). One traversal: the
-- current build is the greatest key, so read it straight off 'Map.lookupMax'.
currentRecord :: BuildState -> BuildRecord
currentRecord s = maybe emptyRecord snd (Map.lookupMax s.history)


-- | The current build's build register.
currentBuild :: BuildState -> BuildOutput
currentBuild s = (currentRecord s).build


-- | The current build's test register.
currentTests :: BuildState -> TestOutput
currentTests s = (currentRecord s).tests


-- | The suites held in a test register, regardless of running/done. The single
-- extractor every reader (CLI, TUI) funnels through, so a new 'TestOutput'
-- constructor is a compile error here rather than a silent @mempty@ in one copy.
suitesOf :: TestOutput -> Test.Suites
suitesOf = \case
    TestsRunning s -> s
    TestsDone s -> s
    TestsIdle -> Test.Suites mempty


atBuild :: BuildId -> BuildState -> Maybe BuildRecord
atBuild bid s = Map.lookup bid s.history


--------------------------------------------------------------------------------
-- Output setters (symmetric — build is not special)
--------------------------------------------------------------------------------

-- | Modify a /specific/ build's record. A 'Map.adjust' — a no-op if @bid@ has
-- been evicted, so a pathological late write for a dropped build is dropped
-- rather than corrupting a live one.
overHistoryAt :: BuildId -> (BuildRecord -> BuildRecord) -> BuildState -> BuildState
overHistoryAt bid f s = s {history = Map.adjust f bid s.history}


-- | Modify the current build's record. Under the sequential-worker invariant
-- (see "Tricorder.Effects.BuildStore") the current id never advances while a
-- write for the current build is in flight, so this always targets the build
-- being written.
overCurrent :: (BuildRecord -> BuildRecord) -> BuildState -> BuildState
-- 'Map.updateMax' adjusts the greatest key (the current build) in one descent,
-- rather than deriving the id and re-descending via 'Map.adjust'.
overCurrent f s = s {history = Map.updateMax (Just . f) s.history}


setCurrentBuild :: BuildOutput -> BuildState -> BuildState
-- Explicit construction (not @rec {build = b}@) because the @build@ label is
-- shared with 'Status', which makes a bare record update ambiguous
-- (-Wambiguous-fields). The constructor pins it to 'BuildRecord'.
setCurrentBuild b = overCurrent \rec -> BuildRecord {build = b, tests = rec.tests}


setCurrentTests :: TestOutput -> BuildState -> BuildState
setCurrentTests t = overCurrent \rec -> rec {tests = t}


overCurrentTests :: (TestOutput -> TestOutput) -> BuildState -> BuildState
overCurrentTests f = overCurrent \rec -> rec {tests = f rec.tests}


--------------------------------------------------------------------------------
-- Derived views — done-ness is a pure cycle check
--------------------------------------------------------------------------------

-- | What @status --wait@ blocks on: the current cycle has come to rest. A pure
-- 'cycle' check — no register is inspected to decide done-ness.
isDone :: BuildState -> Bool
isDone s = case s.cycle of
    Idle -> True
    BuildFailed _ -> True
    Restarting -> False
    Building _ -> False
    Analysing -> False


-- | The snapshot to stream on each live ('Tricorder.Socket.Server.watchStream')
-- transition. While a cycle is live (non-terminal) every reader renders only the
-- current build's record — the retained previous build(s) are never displayed
-- mid-rebuild, so re-encoding their full diagnostics on every @[N of M]@ progress
-- line is pure wire waste. Trim history to the current build for live frames;
-- terminal frames ('isDone') keep the full 'historyBound' history, which is when
-- a client actually reads the previous build.
liveSnapshot :: BuildState -> BuildState
liveSnapshot s
    | isDone s = s
    | otherwise = s {history = Map.filterWithKey (\bid _ -> bid == cur) s.history}
  where
    cur = currentId s


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


-- | Classifies what kind of file change triggered a dirty signal.
-- 'CabalChange' takes priority over 'SourceChange': if both fire before the
-- next build starts, the session will be fully restarted rather than reloaded.
data ChangeKind = SourceChange | CabalChange deriving stock (Eq, Ord, Show)


data CabalChangeDetected = CabalChangeDetected FilePath FileEvent
    deriving stock (Eq, Show)
data SourceChangeDetected = SourceChangeDetected FilePath FileEvent
    deriving stock (Eq, Show)


initialBuildState :: BuildState
initialBuildState =
    BuildState
        { cycle = Building Nothing
        , history = Map.singleton (BuildId 0) emptyRecord
        }
