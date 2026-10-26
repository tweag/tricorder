module Unit.Tricorder.API.FieldMask.ProjectionSpec (test_Projection) where

import Autodocodec (object, parseJSONVia, requiredField, toEncodingVia, (.=))
import Autodocodec.Schema (jsonSchemaVia, validateAccordingTo)
import Data.Aeson (Value (..))
import Data.Aeson.Encoding (encodingToLazyByteString)
import Data.Aeson.Types (parseEither)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Data.Aeson qualified as Aeson

import Tricorder.API.FieldMask.Projection
    ( Projection (..)
    , codec
    , optionalKeys
    , project
    , renderYaml
    )
import Tricorder.API.FieldMask.Schema (Schema (..), leaf, nested)


test_Projection :: TestTree
test_Projection =
    testGroup
        "Tricorder.API.FieldMask.Projection"
        [ testGroup "project" testProject
        , testGroup "codec" testCodec
        , testGroup "optionalKeys" testOptionalKeys
        ]


testProject :: [TestTree]
testProject =
    [ testCase "keeps only the selected fields, in selection order" do
        project (Schema [leaf "status", leaf "name"]) suite
            @?= PObject [("status", PScalar "failed"), ("name", PScalar "suite")]
    , testCase "projects every element of an array" do
        project (Schema [nested "cases" [leaf "outcome"]]) suite
            @?= PObject
                [ ("cases", PArray [PObject [("outcome", PScalar "passed")], PObject [("outcome", PScalar "failed")]])
                ]
    , testCase "leaves out missing and null fields" do
        project (Schema [leaf "name", leaf "missing", leaf "error"]) suite
            @?= PObject [("name", PScalar "suite")]
    , testCase "renders YAML in selection order" do
        renderYaml (project (Schema [leaf "status", leaf "name"]) suite)
            @?= "status: failed\nname: suite\n"
    ]


testCodec :: [TestTree]
testCodec =
    [ testCase "encodes JSON objects in selection order" do
        encode (Schema [leaf "status", leaf "name"])
            @?= "{\"status\":\"failed\",\"name\":\"suite\"}"
    , testCase "encodes nested fields of every element of an array" do
        encode (Schema [nested "cases" [leaf "outcome", leaf "description"]])
            @?= "{\"cases\":[{\"outcome\":\"passed\",\"description\":\"a\"},{\"outcome\":\"failed\",\"description\":\"b\"}]}"
    , testCase "leaves out fields missing from the projection" do
        encode (Schema [leaf "name", leaf "error"]) @?= "{\"name\":\"suite\"}"
    , testCase "fails to decode, even what it encoded" do
        assertBool "decoded" $ isLeft $ parseEither (parseJSONVia $ codec $ Schema [leaf "name"]) suite
    ]
  where
    encode selection = encodingToLazyByteString $ toEncodingVia (codec selection) $ project selection suite


testOptionalKeys :: [TestTree]
testOptionalKeys =
    [ testCase "accepts objects missing required keys" do
        assertBool "missing key rejected"
            $ validateAccordingTo
                (Aeson.object ["name" Aeson..= ("suite" :: Text)])
                (jsonSchemaVia $ optionalKeys pair)
    , testCase "keeps the types of the keys" do
        assertBool "wrong type accepted"
            $ not
            $ validateAccordingTo
                (Aeson.object ["count" Aeson..= ("one" :: Text)])
                (jsonSchemaVia $ optionalKeys pair)
    , testCase "leaves the schema of the original codec as-is" do
        assertBool "missing key accepted"
            $ not
            $ validateAccordingTo (Aeson.object ["name" Aeson..= ("suite" :: Text)]) (jsonSchemaVia pair)
    ]
  where
    pair =
        object "Pair"
            $ (,)
                <$> requiredField @Text "name" "a name" .= fst
                <*> requiredField @Int "count" "a count" .= snd


suite :: Value
suite =
    Aeson.object
        [ "name" Aeson..= ("suite" :: Text)
        , "status" Aeson..= ("failed" :: Text)
        , "error" Aeson..= Null
        , "cases"
            Aeson..= [ Aeson.object ["description" Aeson..= ("a" :: Text), "outcome" Aeson..= ("passed" :: Text)]
                     , Aeson.object ["description" Aeson..= ("b" :: Text), "outcome" Aeson..= ("failed" :: Text)]
                     ]
        ]
