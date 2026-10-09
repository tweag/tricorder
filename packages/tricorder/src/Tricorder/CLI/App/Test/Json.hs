module Tricorder.CLI.App.Test.Json
    ( showSuites
    , wrapResponse
    , showBasePhase
    , argumentError
    )
where

import Data.Aeson (ToJSON, toJSON)
import Data.Aeson.Text (encodeToLazyText)
import Tricorder.CLI.Command.TestFilter (TestFilter)

import Data.Text qualified as T

import Tricorder.Build (BuildPhase (..), BuildState (..), PostBuild (..))
import Tricorder.CLI.App.Test.Json.Responses
    ( MessageWithLoc (..)
    , Response (..)
    , SuitesResponse (..)
    )
import Tricorder.CLI.App.Test.SuiteView (selectSuites)
import Tricorder.CLI.FieldMask (Schema, project)
import Tricorder.Session.TestTarget (TestTarget)

import Tricorder.Build.Test qualified as Test
import Tricorder.CLI.App.Test.Json.Responses qualified as Responses
import Tricorder.Session.TestTarget qualified as TestTarget


showSuites :: [TestTarget] -> TestFilter -> Schema -> Test.Suites -> Response SuitesResponse
showSuites targets testFilter selection testSuites =
    case selectSuites targets testFilter testSuites of
        Left notFound ->
            Responses.Error
                $ MessageWithLoc (T.intercalate ", " $ TestTarget.render <$> toList notFound) "not found"
        Right suites -> Responses.Success $ SuitesResponse $ project selection . toJSON <$> suites


wrapResponse :: (ToJSON a) => Response a -> Either Text Text
wrapResponse resp = case resp of
    Responses.Error _ -> Left $ toStrict $ encodeToLazyText resp
    _ -> Right $ toStrict $ encodeToLazyText resp


-- | Report invalid arguments given to a command.
argumentError :: Text -> Either Text Text
argumentError err = wrapResponse @() $ Responses.Error $ MessageWithLoc "arguments" err


showBasePhase :: Either Text BuildState -> (Test.Suites -> Response a) -> Response a
showBasePhase result mkResponse = case result of
    Left err -> Responses.Error $ MessageWithLoc "build" err
    Right build -> case build.phase of
        Starting -> Responses.Pending $ MessageWithLoc "build" "starting"
        Building _ _ -> Responses.Pending $ MessageWithLoc "build" "building"
        PostBuilding _ postBuild
            | Test.anyRunningTests postBuild.testSuites ->
                Responses.Pending $ MessageWithLoc "postBuild" "testing"
            | otherwise -> mkResponse postBuild.testSuites
        Finished _ postBuild -> mkResponse postBuild.testSuites
        Failed reason -> Responses.Error $ MessageWithLoc "build" $ "build failed: " <> reason
