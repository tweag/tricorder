module Tricorder.Build.PostBuild (PostBuild (..)) where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generically (..))

import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Test qualified as Test


data PostBuild = PostBuild
    { testSuites :: Test.Suites
    , evalComments :: Eval.Phase
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically PostBuild
