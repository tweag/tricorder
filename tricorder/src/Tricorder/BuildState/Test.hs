module Tricorder.BuildState.Test
    ( Suites (..)
    , initSuites
    , suitesFromList
    , suitesToList
    , suitesToMap
    , hasFailedTests
    , suiteRuns
    , anyRunningTests
    , nullSuites
    , TestPhase (..)
    , testPhase
    , Suite (..)
    , isFailedRun
    , Outcome (..)
    , Case (..)
    , caseFailed
    , SuiteCompletion (..)
    , SuiteError (..)
    ) where

import Atelier.Time (Millisecond)
import Data.Aeson (FromJSON, ToJSON)
import Data.Map.Monoidal (MonoidalMap)
import GHC.Generics (Generically (..))

import Data.Map.Monoidal qualified as MMap

import Tricorder.BuildState.BuildProgress (BuildProgress)
import Tricorder.Session (TestTarget)


-- | The test register: a monoidal map from test target to its 'Suite'.
--
-- The running/done phase is a pure derivation ('testPhase'), never a stored tag.
-- Producer writes are monoidal delta-merges: the register's 'Semigroup' unions
-- per target, combining suites with their own 'Semigroup' (terminal-wins,
-- monotone).
--
-- 'MonoidalMap' serialises exactly like a plain 'Map', so the JSON is a
-- target-keyed object.
newtype Suites = Suites {getSuites :: MonoidalMap TestTarget Suite}
    deriving stock (Eq, Generic, Show)
    deriving newtype (Monoid, Semigroup)
    deriving (FromJSON, ToJSON) via Generically Suites


-- | Seed a register with every target marked 'SuiteRunning', so the suite set is
-- complete before any suite finishes.
initSuites :: [TestTarget] -> Suites
initSuites = suitesFromList . map (,SuiteRunning Nothing)


-- | Build a register from an association list (producer / test convenience).
suitesFromList :: [(TestTarget, Suite)] -> Suites
suitesFromList = Suites . MMap.fromList


-- | The register as an association list, ordered by target.
suitesToList :: Suites -> [(TestTarget, Suite)]
suitesToList = MMap.toList . getSuites


-- | The register as a plain strict 'Map' (reader convenience — lets the CLI /
-- TUI keep using ordinary 'Data.Map.Strict' operations).
suitesToMap :: Suites -> Map TestTarget Suite
suitesToMap = MMap.getMonoidalMap . getSuites


hasFailedTests :: Suites -> Bool
hasFailedTests = any isFailedRun . suiteRuns


suiteRuns :: Suites -> [Suite]
suiteRuns = MMap.elems . getSuites


anyRunningTests :: Suites -> Bool
anyRunningTests =
    any
        ( \case
            SuiteRunning _ -> True
            _ -> False
        )
        . suiteRuns


nullSuites :: Suites -> Bool
nullSuites = MMap.null . getSuites


-- | The running/done phase, derived from the register rather than stored.
--
-- The one edge to respect: an /empty/ register is 'NoTests' (idle), NOT
-- 'Tested' — a reader must not read @not anyRunningTests@ as \"done\".
data TestPhase = NoTests | Testing | Tested
    deriving stock (Eq, Show)


testPhase :: Suites -> TestPhase
testPhase ss
    | nullSuites ss = NoTests
    | anyRunningTests ss = Testing
    | otherwise = Tested


data Suite
    = SuiteRunning (Maybe BuildProgress)
    | SuiteErrored SuiteError
    | SuiteCompleted SuiteCompletion
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via (Generically Suite)


-- | Monotone merge of a suite delta into an existing suite. A suite advances
-- @SuiteRunning → terminal@ (completed / errored) and a terminal never regresses
-- to running; the newest terminal (and the newest running progress tick) wins.
-- This is a right-biased \"max by terminality\", which is associative.
instance Semigroup Suite where
    _ <> SuiteCompleted c = SuiteCompleted c
    _ <> SuiteErrored e = SuiteErrored e
    SuiteCompleted c <> SuiteRunning _ = SuiteCompleted c
    SuiteErrored e <> SuiteRunning _ = SuiteErrored e
    SuiteRunning _ <> SuiteRunning b = SuiteRunning b


isFailedRun :: Suite -> Bool
isFailedRun (SuiteCompleted c) = not c.passed
isFailedRun (SuiteErrored _) = True
isFailedRun (SuiteRunning _) = False


data Outcome
    = Passed
    | Failed Text
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via (Generically Outcome)


data Case = Case
    { description :: Text
    , outcome :: Outcome
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via (Generically Case)


caseFailed :: Case -> Bool
caseFailed (Case _ (Failed _)) = True
caseFailed _ = False


newtype SuiteError = SuiteError
    { message :: Text
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via (Generically SuiteError)


data SuiteCompletion = SuiteCompletion
    { passed :: Bool
    , output :: Text
    , testCases :: [Case]
    , duration :: Maybe Millisecond
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via (Generically SuiteCompletion)
