-- | The full, unprojected view of a test suite that @tricorder test suites@
-- selects fields from.
module Tricorder.CLI.App.Test.SuiteView
    ( SuiteView (..)
    , Status (..)
    , CaseView (..)
    , Outcome (..)
    , schema
    , defaultFields
    , selectSuites
    )
where

import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Data.Aeson (ToJSON (..))
import Tricorder.CLI.Command.FieldMask (Field (..), FieldMask (..))
import Tricorder.CLI.Command.TestFilter (TestFilter)

import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Tricorder.CLI.Command.TestFilter qualified as TestFilter

import Tricorder.Build.Duration (Duration)
import Tricorder.CLI.FieldMask (Schema (..), leaf, nested)
import Tricorder.Session.TestTarget (TestTarget)
import Tricorder.TestOutput (stripGhciNoise)

import Tricorder.Build.Test qualified as Test
import Tricorder.Session.TestTarget qualified as TestTarget


-- | Fields that do not apply to a suite's 'Status' are 'Nothing', and are
-- left out of the output.
data SuiteView = SuiteView
    { name :: Text
    , status :: Status
    , error :: Maybe Text
    , passedCases :: Maybe Int
    , totalCases :: Maybe Int
    , durationMs :: Maybe Duration
    , output :: Maybe Text
    , cases :: Maybe [CaseView]
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via QuietSnake SuiteView


data Status = Running | Errored | Passed | Failed
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via QuietSnake Status


data CaseView = CaseView
    { description :: Text
    , outcome :: Outcome
    , failure :: Maybe Text
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via QuietSnake CaseView


data Outcome = CasePassed | CaseFailed
    deriving stock (Eq, Generic, Show)


instance ToJSON Outcome where
    toJSON = \case
        CasePassed -> "passed"
        CaseFailed -> "failed"


-- | Every field of a 'SuiteView', as named in its JSON encoding.
schema :: Schema
schema =
    Schema
        [ leaf "name"
        , leaf "status"
        , leaf "error"
        , leaf "passed_cases"
        , leaf "total_cases"
        , leaf "duration_ms"
        , leaf "output"
        , nested
            "cases"
            [ leaf "description"
            , leaf "outcome"
            , leaf "failure"
            ]
        ]


-- | A summary of each suite, leaving out the (potentially large) test output
-- and test cases.
defaultFields :: FieldMask
defaultFields =
    FieldMask
        $ (\name -> Field name Nothing)
            <$> "name" :| ["status", "error", "passed_cases", "total_cases", "duration_ms"]


-- | Pick out the requested suites, or all of them when none are requested.
-- Fails with the requested suites that do not exist.
--
-- 'TestFilter.FailedOnly' keeps only failed suites, and only the failed test
-- cases within them.
selectSuites
    :: [TestTarget] -> TestFilter -> Test.Suites -> Either (NonEmpty TestTarget) [SuiteView]
selectSuites requested testFilter (Test.Suites suites) = do
    selected <- case requested of
        [] -> Right $ Map.toList suites
        _ -> case nonEmpty missing of
            Just notFound -> Left notFound
            Nothing -> Right [(target, suite) | target <- ordNub requested, Just suite <- [Map.lookup target suites]]
    pure $ uncurry toView <$> filter (keepSuite . snd) selected
  where
    missing = filter (`Map.notMember` suites) requested

    keepSuite suite = case testFilter of
        TestFilter.FailedOnly -> Test.isFailedRun suite
        TestFilter.All -> True

    keepCase testCase = case testFilter of
        TestFilter.FailedOnly -> Test.caseFailed testCase
        TestFilter.All -> True

    toView target suite =
        let view =
                SuiteView
                    { name = TestTarget.render target
                    , status = Running
                    , error = Nothing
                    , passedCases = Nothing
                    , totalCases = Nothing
                    , durationMs = Nothing
                    , output = Nothing
                    , cases = Nothing
                    }
        in  case suite of
                Test.SuiteRunning _ -> view
                Test.SuiteErrored err -> view {status = Errored, error = Just err.message}
                Test.SuiteCompleted completion ->
                    view
                        { status = if completion.passed then Passed else Failed
                        , passedCases = Just $ length $ filter (not . Test.caseFailed) completion.testCases
                        , totalCases = Just $ length completion.testCases
                        , durationMs = completion.duration
                        , output = Just $ T.unlines $ stripGhciNoise $ T.lines completion.output
                        , cases = Just $ toCaseView <$> filter keepCase completion.testCases
                        }

    toCaseView testCase = case testCase.outcome of
        Test.Passed -> CaseView testCase.description CasePassed Nothing
        Test.Failed reason -> CaseView testCase.description CaseFailed (Just reason)
