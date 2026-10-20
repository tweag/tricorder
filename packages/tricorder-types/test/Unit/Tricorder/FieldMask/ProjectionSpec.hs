module Unit.Tricorder.FieldMask.ProjectionSpec (test_Projection) where

import Data.Aeson (Value (..), object, (.=))
import Data.Aeson.Text (encodeToLazyText)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.FieldMask.Projection (Projection (..), project, renderYaml)
import Tricorder.FieldMask.Schema (Schema (..), leaf, nested)


test_Projection :: TestTree
test_Projection =
    testGroup
        "Tricorder.FieldMask.Projection"
        [ testGroup "project" testProject
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
    , testCase "encodes JSON objects in selection order" do
        encodeToLazyText (project (Schema [leaf "status", leaf "name"]) suite)
            @?= "{\"status\":\"failed\",\"name\":\"suite\"}"
    , testCase "renders YAML in selection order" do
        renderYaml (project (Schema [leaf "status", leaf "name"]) suite)
            @?= "status: failed\nname: suite\n"
    ]
  where
    suite =
        object
            [ "name" .= ("suite" :: Text)
            , "status" .= ("failed" :: Text)
            , "error" .= Null
            , "cases"
                .= [ object ["description" .= ("a" :: Text), "outcome" .= ("passed" :: Text)]
                   , object ["description" .= ("b" :: Text), "outcome" .= ("failed" :: Text)]
                   ]
            ]
