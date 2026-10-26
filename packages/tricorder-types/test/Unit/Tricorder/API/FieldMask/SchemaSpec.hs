module Unit.Tricorder.API.FieldMask.SchemaSpec (test_Schema) where

import Autodocodec
    ( JSONCodec
    , listCodec
    , object
    , optionalFieldWith
    , requiredField
    , requiredFieldWith
    , textCodec
    , (.=)
    )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, assertFailure, testCase, (@?=))

import Data.Text qualified as T

import Tricorder.API.FieldMask.Args (parse)
import Tricorder.API.FieldMask.Schema (Schema (..), fromCodec, leaf, nested, select)


test_Schema :: TestTree
test_Schema =
    testGroup
        "Tricorder.API.FieldMask.Schema"
        [ testGroup "select" testSelect
        , testGroup "fromCodec" testFromCodec
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


testFromCodec :: [TestTree]
testFromCodec =
    [ testCase "lists the fields of an object in codec order, nesting through lists of objects" do
        fromCodec suiteCodec
            @?= Schema [leaf "name", leaf "tags", nested "cases" [leaf "description", leaf "outcome"]]
    , testCase "a codec of something other than an object has no fields" do
        fromCodec textCodec @?= Schema []
    ]
  where
    suiteCodec :: JSONCodec (Text, [Text], Maybe [(Text, Text)])
    suiteCodec =
        object "Suite"
            $ (,,)
                <$> requiredField "name" "the name" .= (\(name, _, _) -> name)
                <*> requiredField "tags" "the tags" .= (\(_, tags, _) -> tags)
                <*> optionalFieldWith "cases" (listCodec caseCodec) "the cases" .= (\(_, _, cases) -> cases)


caseCodec :: JSONCodec (Text, Text)
caseCodec =
    object "Case"
        $ (,)
            <$> requiredFieldWith "description" textCodec "the description" .= fst
            <*> requiredFieldWith "outcome" textCodec "the outcome" .= snd


schema :: Schema
schema = Schema [leaf "name", leaf "status", casesSchema]


casesSchema :: (Text, Maybe Schema)
casesSchema = nested "cases" [leaf "description", leaf "outcome"]


assertLeftContaining :: (Show a) => Text -> Either Text a -> IO ()
assertLeftContaining needle = \case
    Left err -> assertBool (toString $ err <> "\ndoes not contain\n" <> needle) $ needle `T.isInfixOf` err
    Right a -> assertFailure $ "expected Left, got Right " <> show a
