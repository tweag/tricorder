module Unit.Tricorder.API.SuitesResponseSpec (test_SuitesResponse) where

import Atelier.Time (AsRawUnit (..))
import Autodocodec (HasCodec (..), toEncodingVia, toJSONVia)
import Autodocodec.Schema (jsonSchemaVia, validateAccordingTo)
import Data.Aeson (Value, eitherDecode, toJSON)
import Data.Aeson.Encoding (encodingToLazyByteString)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, assertFailure, testCase, (@?=))

import Tricorder.API.FieldMask.Args (parse)
import Tricorder.API.Response (Response (..))
import Tricorder.API.Test.SuiteView (CaseView (..), Outcome (..), Status (..), SuiteView (..))
import Tricorder.API.Test.SuitesResponse (SuitesResponse (..))

import Tricorder.API.FieldMask.Projection qualified as Projection
import Tricorder.API.FieldMask.Schema qualified as FieldMask.Schema
import Tricorder.API.Response qualified as Response
import Tricorder.API.Test.SuiteView.Schema qualified as SuiteView.Schema
import Tricorder.API.Test.SuitesResponse qualified as SuitesResponse


test_SuitesResponse :: TestTree
test_SuitesResponse =
    testGroup
        "Tricorder.API.Test.SuitesResponse"
        [ testCase "projected suites match the schema of any projection" do
            for_
                [ "name"
                , "status,name"
                , "name,status,error,passed_cases,total_cases,duration_ms"
                , "output"
                , "cases"
                , "name,cases(outcome)"
                ]
                \fields -> do
                    encoded <- encodeSuites fields
                    assertBool (toString fields) $ validateAccordingTo encoded projectionSchema
        , testCase "encodes fields in the order they were selected in" do
            selection <- either (assertFailure . toString) pure $ select "status,name"
            encodingToLazyByteString
                (toEncodingVia (suitesCodec selection) $ Success $ SuitesResponse [projected selection runningView])
                @?= "{\"success\":{\"suites\":[{\"status\":\"running\",\"name\":\"test:suite\"}]}}"
        , testCase "the schema rejects unknown values" do
            assertBool "accepted"
                $ not
                $ validateAccordingTo
                    (toJSONVia (Response.codec $ SuitesResponse.codec codec) $ Success $ SuitesResponse [toJSON @Int 1])
                    projectionSchema
        ]
  where
    projectionSchema =
        jsonSchemaVia $ Response.codec $ SuitesResponse.codec $ Projection.optionalKeys $ codec @SuiteView

    encodeSuites fields = do
        selection <- either (assertFailure . toString) pure $ select fields
        either assertFailure pure
            $ eitherDecode @Value
            $ encodingToLazyByteString
            $ toEncodingVia (suitesCodec selection)
            $ Success
            $ SuitesResponse
            $ projected selection <$> [finishedView, erroredView, runningView]

    select fields = FieldMask.Schema.select SuiteView.Schema.schema =<< parse fields
    projected selection = Projection.project selection . toJSON
    suitesCodec = Response.codec . SuitesResponse.codec . Projection.codec


finishedView :: SuiteView
finishedView =
    SuiteView
        { name = "test:suite"
        , status = Failed
        , error = Nothing
        , passedCases = Just 1
        , totalCases = Just 2
        , durationMs = Just $ AsRawUnit 5
        , output = Just "output"
        , cases = Just [CaseView "a" CasePassed Nothing, CaseView "b" CaseFailed (Just "failure")]
        }


erroredView :: SuiteView
erroredView =
    finishedView
        { status = Errored
        , error = Just "error"
        , passedCases = Nothing
        , totalCases = Nothing
        , durationMs = Nothing
        , output = Nothing
        , cases = Nothing
        }


runningView :: SuiteView
runningView = erroredView {status = Running, error = Nothing}
