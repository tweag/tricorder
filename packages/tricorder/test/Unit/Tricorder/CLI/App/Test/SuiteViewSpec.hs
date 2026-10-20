module Unit.Tricorder.CLI.App.Test.SuiteViewSpec (test_SuiteView) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))
import Tricorder.API.Test.SuiteView (CaseView (..), Outcome (..), Status (..), SuiteView (..))

import Data.Map.Strict qualified as Map
import Tricorder.API.TestFilter qualified as TestFilter

import Tricorder.CLI.App.Test.SuiteView (selectSuites)
import Tricorder.Session.TestTarget (TestTarget)

import Tricorder.Build.Test qualified as Test
import Tricorder.Session.TestTarget qualified as TestTarget


test_SuiteView :: TestTree
test_SuiteView =
    testGroup
        "SuiteView"
        [ testGroup "selectSuites" testSelectSuites
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


-- | Keys of a JSON value, nested keys of arrays taken from their first element.
data Keys = Keys [(Text, Maybe Keys)]
    deriving stock (Eq, Show)
