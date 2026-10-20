module Unit.Tricorder.FieldMask.ArgsSpec (test_Args) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertFailure, testCase, (@?=))

import Tricorder.FieldMask (Field (..), FieldMask (..))
import Tricorder.FieldMask.Args (parse)

import Tricorder.FieldMask qualified as FieldMask


test_Args :: TestTree
test_Args =
    testGroup
        "Tricorder.FieldMask.Args"
        [ testGroup "parse" testParse
        ]


testParse :: [TestTree]
testParse =
    [ testCase "parses a flat list of fields" do
        parse "name,status" @?= Right (mask [field "name", field "status"])
    , testCase "parses nested fields" do
        parse "name,cases(description,failure)"
            @?= Right (mask [field "name", Field "cases" $ Just $ mask [field "description", field "failure"]])
    , testCase "allows whitespace between tokens" do
        parse " name , cases ( description ) "
            @?= Right (mask [field "name", Field "cases" $ Just $ mask [field "description"]])
    , testCase "rejects an empty mask" do
        assertLeft $ parse ""
    , testCase "rejects a trailing comma" do
        assertLeft $ parse "name,"
    , testCase "rejects empty parentheses" do
        assertLeft $ parse "cases()"
    , testCase "rejects unbalanced parentheses" do
        assertLeft $ parse "cases(description"
    , testCase "round-trips through render" do
        let input = "name,cases(description,failure),output"
        (FieldMask.render <$> parse input) @?= Right input
    ]


mask :: [Field] -> FieldMask
mask = maybe (error "mask: no fields") FieldMask . nonEmpty


field :: Text -> Field
field name = Field name Nothing


assertLeft :: (Show a) => Either Text a -> IO ()
assertLeft = \case
    Left _ -> pass
    Right a -> assertFailure $ "expected Left, got Right " <> show a
