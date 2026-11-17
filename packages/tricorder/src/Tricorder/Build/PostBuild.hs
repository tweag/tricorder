module Tricorder.Build.PostBuild (PostBuild (..)) where

import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON, ToJSON)

import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Test qualified as Test


data PostBuild = PostBuild
    { testSuites :: Test.Suites
    , evalComments :: Eval.Phase
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake PostBuild
