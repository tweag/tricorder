module Tricorder.CLI.App.Test.Json
    ( showSuites
    , wrapSuites
    , showBasePhase
    , argumentError
    )
where

import Autodocodec (ValueCodec, nullCodec, toEncodingVia)
import Data.Aeson (toJSON)
import Data.Aeson.Encoding (encodingToLazyByteString)
import Tricorder.API.FieldMask.Projection (Projection)
import Tricorder.API.Response (MessageWithLoc (..), Response (..))
import Tricorder.API.Test.SuitesResponse (SuitesResponse (..))
import Tricorder.API.TestFilter (TestFilter)

import Data.Text qualified as T
import Tricorder.API.FieldMask.Projection qualified as FieldMask.Projection
import Tricorder.API.FieldMask.Schema qualified as FieldMask (Schema)
import Tricorder.API.Response qualified as Responses
import Tricorder.API.Test.SuitesResponse qualified as SuitesResponse

import Tricorder.Build
    ( BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , Diagnostic (..)
    , PostBuild (..)
    , Severity (..)
    )
import Tricorder.CLI.App.Test.SuiteView (selectSuites)
import Tricorder.Session.TestTarget (TestTarget)

import Tricorder.Build.Test qualified as Test
import Tricorder.Session.TestTarget qualified as TestTarget


showSuites
    :: [TestTarget]
    -> TestFilter
    -> FieldMask.Schema
    -> Test.Suites
    -> Response (SuitesResponse Projection)
showSuites targets testFilter selection testSuites =
    case selectSuites targets testFilter testSuites of
        Left notFound ->
            Responses.Error
                $ MessageWithLoc (T.intercalate ", " $ TestTarget.render <$> toList notFound) "not found"
        Right suites -> Responses.Success $ SuitesResponse $ FieldMask.Projection.project selection . toJSON <$> suites


-- | Encode test suites projected down to the fields of the selection, in the
-- order they were selected in.
wrapSuites :: FieldMask.Schema -> Response (SuitesResponse Projection) -> Either Text Text
wrapSuites selection = wrapResponse $ SuitesResponse.codec $ FieldMask.Projection.codec selection


wrapResponse :: ValueCodec a output -> Response a -> Either Text Text
wrapResponse payload resp = case resp of
    Responses.Error _ -> Left encoded
    _ -> Right encoded
  where
    encoded = decodeUtf8 $ encodingToLazyByteString $ toEncodingVia (Responses.codec payload) resp


-- | Report invalid arguments given to a command.
argumentError :: Text -> Either Text Text
argumentError err = wrapResponse nullCodec $ Responses.Error $ MessageWithLoc "arguments" err


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
        Finished buildResult postBuild
            | buildFailed buildResult postBuild ->
                Responses.Error $ MessageWithLoc "finished" "build failed before tests ran"
            | otherwise -> mkResponse postBuild.testSuites
        Failed reason -> Responses.Error $ MessageWithLoc "build" $ "build failed: " <> reason
  where
    buildFailed buildResult postBuild =
        postBuild.testSuites == mempty && any (\d -> d.severity >= SError) buildResult.diagnostics
