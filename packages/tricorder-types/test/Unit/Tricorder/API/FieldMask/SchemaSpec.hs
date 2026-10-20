module Unit.Tricorder.API.FieldMask.SchemaSpec (test_Schema) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, assertFailure, testCase, (@?=))

import Data.Text qualified as T

import Tricorder.API.FieldMask.Args (parse)
import Tricorder.API.FieldMask.Schema (Schema (..), leaf, nested, select)


test_Schema :: TestTree
test_Schema =
    testGroup
        "Tricorder.API.FieldMask.Schema"
        [ testGroup "select" testSelect
        ]


testSelect :: [TestTree]
testSelect =
    [ testCase "keeps the requested fields in the requested order" do
        select' "status,name" @?= Right (Schema [leaf "status", leaf "name"])
    , testCase "a field without sub-fields keeps its whole nested schema" do
        select' "cases" @?= Right (Schema [casesSchema])
    , testCase "narrows nested fields" do
        select' "cases(outcome)" @?= Right (Schema [nested "cases" [leaf "outcome"]])
    , testCase "rejects unknown fields" do
        assertLeftContaining "unknown field 'nope'" $ select' "name,nope"
    , testCase "names the path of unknown nested fields" do
        assertLeftContaining "unknown field 'cases.nope'" $ select' "cases(nope)"
    , testCase "rejects sub-fields of a field without any" do
        assertLeftContaining "field 'name' has no sub-fields" $ select' "name(x)"
    ]
  where
    select' input = select schema =<< parse input


schema :: Schema
schema = Schema [leaf "name", leaf "status", casesSchema]


casesSchema :: (Text, Maybe Schema)
casesSchema = nested "cases" [leaf "description", leaf "outcome"]


assertLeftContaining :: (Show a) => Text -> Either Text a -> IO ()
assertLeftContaining needle = \case
    Left err -> assertBool (toString $ err <> "\ndoes not contain\n" <> needle) $ needle `T.isInfixOf` err
    Right a -> assertFailure $ "expected Left, got Right " <> show a
