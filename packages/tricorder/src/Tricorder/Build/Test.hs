module Tricorder.Build.Test
    ( Suites (..)
    , hasFailedTests
    , suiteRuns
    , anyRunningTests
    , nullSuites
    , Suite (..)
    , isFailedRun
    , Progress (..)
    , Outcome (..)
    , Case (..)
    , caseFailed
    , SuiteCompletion (..)
    , SuiteError (..)
    )
where

import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON (..), ToJSON (..))

import Data.Map.Strict qualified as Map

import Tricorder.Build.Duration (Duration)
import Tricorder.Session.TestTarget (TestTarget)


newtype Suites = Suites {getSuites :: Map TestTarget Suite}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, Monoid, Semigroup, ToJSON) via Map TestTarget Suite


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
    = SuiteRunning (Maybe Progress)
    | SuiteErrored SuiteError
    | SuiteCompleted SuiteCompletion
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake Suite


isFailedRun :: Suite -> Bool
isFailedRun (SuiteCompleted c) = not c.passed
isFailedRun (SuiteErrored _) = True
isFailedRun (SuiteRunning _) = False


data Progress = Progress
    { compiled :: Int
    , total :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake Progress


data Outcome
    = Passed
    | Failed Text
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake Outcome


data Case = Case
    { description :: Text
    , outcome :: Outcome
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake Case


caseFailed :: Case -> Bool
caseFailed (Case _ (Failed _)) = True
caseFailed _ = False


newtype SuiteError = SuiteError
    { message :: Text
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake SuiteError


data SuiteCompletion = SuiteCompletion
    { passed :: Bool
    , output :: Text
    , testCases :: [Case]
    , duration :: Maybe Duration
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake SuiteCompletion
