module Unit.Tricorder.CLI.App.Test.SuiteViewSpec (test_SuiteView) where

import Data.Aeson (Value (..), toJSON)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KeyMap
import Data.Map.Strict qualified as Map
import Tricorder.CLI.Command.TestFilter qualified as TestFilter

import Tricorder.Build.Duration (Duration (..))
import Tricorder.CLI.App.Test.SuiteView
    ( CaseView (..)
    , Outcome (..)
    , Status (..)
    , SuiteView (..)
    , defaultFields
    , schema
    , selectSuites
    )
import Tricorder.CLI.FieldMask (Schema (..))
import Tricorder.Session.TestTarget (TestTarget)

import Tricorder.Build.Test qualified as Test
import Tricorder.CLI.FieldMask qualified as FieldMask
import Tricorder.Session.TestTarget qualified as TestTarget


test_SuiteView :: TestTree
test_SuiteView =
    testGroup
        "SuiteView"
        [ testCase "schema lists every field of the JSON encoding" do
            schemaKeys schema @?= jsonKeys (toJSON fullView)
        , testCase "default fields are in the schema" do
            void (FieldMask.select schema defaultFields) @?= Right ()
        , testGroup "selectSuites" testSelectSuites
        ]


testSelectSuites :: [TestTree]
testSelectSuites =
    [ testCase "shows all suites when none are requested" do
        names (selectSuites [] TestFilter.All suites)
            @?= Right ["test:errored", "test:failing", "test:passing"]
    , testCase "shows requested suites in the requested order" do
        names (selectSuites [target "test:passing", target "test:failing"] TestFilter.All suites)
            @?= Right ["test:passing", "test:failing"]
    , testCase "fails on suites that do not exist" do
        names (selectSuites [target "test:passing", target "test:nope"] TestFilter.All suites)
            @?= Left (target "test:nope" :| [])
    , testCase "failed-only keeps failed and errored suites" do
        names (selectSuites [] TestFilter.FailedOnly suites) @?= Right ["test:errored", "test:failing"]
    , testCase "failed-only keeps only failed test cases" do
        fmap (fmap (.cases)) (selectSuites [target "test:failing"] TestFilter.FailedOnly suites)
            @?= Right [Just [CaseView "breaks" CaseFailed (Just "boom")]]
    , testCase "counts cases before filtering them" do
        fmap
            (fmap (\s -> (s.passedCases, s.totalCases)))
            (selectSuites [target "test:failing"] TestFilter.FailedOnly suites)
            @?= Right [(Just 1, Just 2)]
    , testCase "errored suites carry their error" do
        fmap (fmap (\s -> (s.status, s.error))) (selectSuites [target "test:errored"] TestFilter.All suites)
            @?= Right [(Errored, Just "did not compile")]
    ]
  where
    names = fmap (fmap (.name))
    suites =
        Test.Suites
            $ Map.fromList
                [ (target "test:passing", completed True [Test.Case "works" Test.Passed])
                ,
                    ( target "test:failing"
                    , completed False [Test.Case "works" Test.Passed, Test.Case "breaks" (Test.Failed "boom")]
                    )
                , (target "test:errored", Test.SuiteErrored $ Test.SuiteError "did not compile")
                ]
    completed passed testCases =
        Test.SuiteCompleted
            $ Test.SuiteCompletion {passed, output = "", testCases, duration = Nothing}


target :: Text -> TestTarget
target name = fromMaybe (Prelude.error $ "invalid test target: " <> name) $ TestTarget.parse name


-- | A view with every field set, so every field shows up in its JSON.
fullView :: SuiteView
fullView =
    SuiteView
        { name = "test:suite"
        , status = Failed
        , error = Just "error"
        , passedCases = Just 0
        , totalCases = Just 1
        , durationMs = Just $ Duration 5
        , output = Just "output"
        , cases = Just [CaseView "case" CaseFailed (Just "failure")]
        }


-- | Keys of a JSON value, nested keys of arrays taken from their first element.
data Keys = Keys [(Text, Maybe Keys)]
    deriving stock (Eq, Show)


schemaKeys :: Schema -> Keys
schemaKeys (Schema fields) = Keys $ sortOn fst $ second (fmap schemaKeys) <$> fields


jsonKeys :: Value -> Keys
jsonKeys = \case
    Object obj -> Keys $ sortOn fst [(Key.toText key, nestedKeys value) | (key, value) <- KeyMap.toList obj]
    _ -> Keys []
  where
    nestedKeys = \case
        Array values | Just element <- viaNonEmpty head (toList values) -> Just $ jsonKeys element
        _ -> Nothing
