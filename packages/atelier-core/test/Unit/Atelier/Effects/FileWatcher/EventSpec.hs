module Unit.Atelier.Effects.FileWatcher.EventSpec (test_Event) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.Effects.FileWatcher.Event (Event (..), collapse)

import Atelier.FileSystem.Path qualified as Path


test_Event :: TestTree
test_Event =
    testGroup
        "Atelier.Effects.FileWatcher.Event"
        [ testGroup "collapse" testCollapse
        ]


testCollapse :: [TestTree]
testCollapse =
    [ testCase "distinct paths are kept in arrival order" do
        collapse [(fileA, Modified), (fileB, Modified)]
            @?= [(fileA, Modified), (fileB, Modified)]
    , testCase "events for one path merge into a single event" do
        collapse [(fileA, Added), (fileA, Modified)]
            @?= [(fileA, Added)]
    , testCase "a removal wins over earlier events for the same path" do
        collapse [(fileA, Modified), (fileA, Removed)]
            @?= [(fileA, Removed)]
    , testCase "paths are ordered by their most recent event" do
        collapse [(fileA, Modified), (fileB, Modified), (fileA, Modified)]
            @?= [(fileB, Modified), (fileA, Modified)]
    ]


fileA :: Path.Any
fileA = Path.Relative $ Path.rel @"./src/A.hs"


fileB :: Path.Any
fileB = Path.Relative $ Path.rel @"./src/B.hs"
