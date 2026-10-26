module Tricorder.API.Test.SuiteView
    ( SuiteView (..)
    , Status (..)
    , CaseView (..)
    , Outcome (..)
    )
where

import Atelier.Time (AsRawUnit (..), Millisecond)
import Autodocodec
    ( Autodocodec (..)
    , Bounds (..)
    , HasCodec (..)
    , JSONCodec
    , boundedEnumCodec
    , dimapCodec
    , integerWithBoundsCodec
    , object
    , optionalField
    , optionalFieldWith
    , requiredField
    , (.=)
    )
import Data.Aeson (ToJSON)


-- | Fields that do not apply to a suite's 'Status' are 'Nothing', and are
-- left out of the output.
data SuiteView = SuiteView
    { name :: Text
    , status :: Status
    , error :: Maybe Text
    , passedCases :: Maybe Int
    , totalCases :: Maybe Int
    , durationMs :: Maybe (AsRawUnit Millisecond)
    , output :: Maybe Text
    , cases :: Maybe [CaseView]
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via Autodocodec SuiteView


instance HasCodec SuiteView where
    codec =
        object "SuiteView"
            $ SuiteView
                <$> requiredField "name" "The Cabal target of the test suite, e.g. `pkg:test:pkg-test`."
                    .= (.name)
                <*> requiredField
                    "status"
                    "`running` while the suite runs, `errored` if it could not be run, otherwise `passed` or `failed`."
                    .= (.status)
                <*> optionalField "error" "Why the suite could not be run. Only for `errored` suites."
                    .= (.error)
                <*> optionalFieldWith "passed_cases" countCodec "Number of passed test cases. Only for finished suites."
                    .= (.passedCases)
                <*> optionalFieldWith "total_cases" countCodec "Number of test cases. Only for finished suites."
                    .= (.totalCases)
                <*> optionalFieldWith
                    "duration_ms"
                    (dimapCodec (AsRawUnit . fromIntegral) (fromIntegral . (.getAsRawUnit)) countCodec)
                    "How long the suite ran, in milliseconds. Only for finished suites."
                    .= (.durationMs)
                <*> optionalField "output" "The output of the suite. Only for finished suites."
                    .= (.output)
                <*> optionalField "cases" "The test cases of the suite. Only for finished suites."
                    .= (.cases)


data Status = Running | Errored | Passed | Failed
    deriving stock (Bounded, Enum, Eq, Generic, Show)
    deriving (ToJSON) via Autodocodec Status


instance HasCodec Status where
    codec = boundedEnumCodec \case
        Running -> "running"
        Errored -> "errored"
        Passed -> "passed"
        Failed -> "failed"


data CaseView = CaseView
    { description :: Text
    , outcome :: Outcome
    , failure :: Maybe Text
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via Autodocodec CaseView


instance HasCodec CaseView where
    codec =
        object "CaseView"
            $ CaseView
                <$> requiredField "description" "The description of the test case." .= (.description)
                <*> requiredField "outcome" "Whether the test case passed." .= (.outcome)
                <*> optionalField "failure" "Why the test case failed. Only for failed test cases." .= (.failure)


data Outcome = CasePassed | CaseFailed
    deriving stock (Bounded, Enum, Eq, Generic, Show)
    deriving (ToJSON) via Autodocodec Outcome


instance HasCodec Outcome where
    codec = boundedEnumCodec \case
        CasePassed -> "passed"
        CaseFailed -> "failed"


-- | A non-negative integer.
countCodec :: JSONCodec Int
countCodec =
    dimapCodec fromInteger toInteger
        $ integerWithBoundsCodec Bounds {boundsLower = Just 0, boundsUpper = Nothing}
