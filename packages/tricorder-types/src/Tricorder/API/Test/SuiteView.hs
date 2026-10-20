module Tricorder.API.Test.SuiteView
    ( SuiteView (..)
    , Status (..)
    , CaseView (..)
    , Outcome (..)
    )
where

import Atelier.Time (AsRawUnit, Millisecond)
import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Data.Aeson (ToJSON (..))


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
