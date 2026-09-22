module Unit.Tricorder.CLI.FieldMaskSpec (test_FieldMask) where

import Data.Aeson (Value (..), object, (.=))
import Data.Aeson.Text (encodeToLazyText)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, assertFailure, testCase, (@?=))
import Tricorder.CLI.Command.FieldMask (Field (..), FieldMask (..))

import Data.Text qualified as T
import Tricorder.CLI.Command.FieldMask qualified as Command

import Tricorder.CLI.FieldMask (Projected (..), Schema (..), leaf, nested)

import Tricorder.CLI.FieldMask qualified as FieldMask


test_FieldMask :: TestTree
test_FieldMask =
    testGroup
        "FieldMask"
        [ testGroup "parse" testParse
        , testGroup "select" testSelect
        , testGroup "project" testProject
        ]


testParse :: [TestTree]
testParse =
    [ testCase "parses a flat list of fields" do
        FieldMask.parse "name,status" @?= Right (mask [field "name", field "status"])
    , testCase "parses nested fields" do
        FieldMask.parse "name,cases(description,failure)"
            @?= Right (mask [field "name", Field "cases" $ Just $ mask [field "description", field "failure"]])
    , testCase "allows whitespace between tokens" do
        FieldMask.parse " name , cases ( description ) "
            @?= Right (mask [field "name", Field "cases" $ Just $ mask [field "description"]])
    , testCase "rejects an empty mask" do
        assertLeft $ FieldMask.parse ""
    , testCase "rejects a trailing comma" do
        assertLeft $ FieldMask.parse "name,"
    , testCase "rejects empty parentheses" do
        assertLeft $ FieldMask.parse "cases()"
    , testCase "rejects unbalanced parentheses" do
        assertLeft $ FieldMask.parse "cases(description"
    , testCase "round-trips through render" do
        let input = "name,cases(description,failure),output"
        (Command.render <$> FieldMask.parse input) @?= Right input
    ]


testSelect :: [TestTree]
testSelect =
    [ testCase "keeps the requested fields in the requested order" do
        select "status,name" @?= Right (Schema [leaf "status", leaf "name"])
    , testCase "a field without sub-fields keeps its whole nested schema" do
        select "cases" @?= Right (Schema [casesSchema])
    , testCase "narrows nested fields" do
        select "cases(outcome)" @?= Right (Schema [nested "cases" [leaf "outcome"]])
    , testCase "rejects unknown fields" do
        assertLeftContaining "unknown field 'nope'" $ select "name,nope"
    , testCase "names the path of unknown nested fields" do
        assertLeftContaining "unknown field 'cases.nope'" $ select "cases(nope)"
    , testCase "rejects sub-fields of a field without any" do
        assertLeftContaining "field 'name' has no sub-fields" $ select "name(x)"
    ]
  where
    select input = FieldMask.select schema =<< FieldMask.parse input


testProject :: [TestTree]
testProject =
    [ testCase "keeps only the selected fields, in selection order" do
        FieldMask.project (Schema [leaf "status", leaf "name"]) suite
            @?= PObject [("status", PScalar "failed"), ("name", PScalar "suite")]
    , testCase "projects every element of an array" do
        FieldMask.project (Schema [nested "cases" [leaf "outcome"]]) suite
            @?= PObject
                [ ("cases", PArray [PObject [("outcome", PScalar "passed")], PObject [("outcome", PScalar "failed")]])
                ]
    , testCase "leaves out missing and null fields" do
        FieldMask.project (Schema [leaf "name", leaf "missing", leaf "error"]) suite
            @?= PObject [("name", PScalar "suite")]
    , testCase "encodes JSON objects in selection order" do
        encodeToLazyText (FieldMask.project (Schema [leaf "status", leaf "name"]) suite)
            @?= "{\"status\":\"failed\",\"name\":\"suite\"}"
    , testCase "renders YAML in selection order" do
        FieldMask.renderYaml (FieldMask.project (Schema [leaf "status", leaf "name"]) suite)
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


schema :: Schema
schema = Schema [leaf "name", leaf "status", casesSchema]


casesSchema :: (Text, Maybe Schema)
casesSchema = nested "cases" [leaf "description", leaf "outcome"]


mask :: [Field] -> FieldMask
mask = maybe (error "mask: no fields") FieldMask . nonEmpty


field :: Text -> Field
field name = Field name Nothing


assertLeft :: (Show a) => Either Text a -> IO ()
assertLeft = \case
    Left _ -> pass
    Right a -> assertFailure $ "expected Left, got Right " <> show a


assertLeftContaining :: (Show a) => Text -> Either Text a -> IO ()
assertLeftContaining needle = \case
    Left err -> assertBool (toString $ err <> "\ndoes not contain\n" <> needle) $ needle `T.isInfixOf` err
    Right a -> assertFailure $ "expected Left, got Right " <> show a
