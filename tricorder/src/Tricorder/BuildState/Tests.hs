module Tricorder.BuildState.Tests
    ( Suites (..)
    , hasFailedTests
    , suiteRuns
    , anyRunningTests
    , nullSuites
    , Suite (..)
    , isFailedRun
    , Outcome (..)
    , Case (..)
    , SuiteCompletion (..)
    , SuiteError (..)
    ) where

import Atelier.Time (Millisecond)
import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generically (..))

import Data.Map.Strict qualified as Map

import Tricorder.BuildState.BuildProgress (BuildProgress)
import Tricorder.Session (TestTarget)


newtype Suites = Suites {getSuites :: Map TestTarget Suite}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically Suites


hasFailedTests :: Suites -> Bool
hasFailedTests = any isFailedRun . suiteRuns


suiteRuns :: Suites -> [Suite]
suiteRuns = Map.elems . getSuites


anyRunningTests :: Suites -> Bool
anyRunningTests =
    any
        ( \case
            SuiteRunning _ -> True
            _ -> False
        )
        . toList
        . getSuites


nullSuites :: Suites -> Bool
nullSuites = Map.null . getSuites


data Suite
    = SuiteRunning (Maybe BuildProgress)
    | SuiteErrored SuiteError
    | SuiteCompleted SuiteCompletion
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via (Generically Suite)


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
