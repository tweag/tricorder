module Unit.Tricorder.Session.StackProjectSpec (test_StackProject) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.FileSystem.Path qualified as Path
import Data.Yaml qualified as Yaml

import Tricorder.Session.StackProject (StackProject (..))


test_StackProject :: TestTree
test_StackProject =
    testGroup
        "StackProject"
        [ testCase "defaults packages to [\".\"] when the key is absent" do
            decode "resolver: lts-24.0\n"
                @?= Right (StackProject [Path.rel @"."])
        , testCase "defaults packages to [\".\"] for an empty document" do
            decode "{}\n"
                @?= Right (StackProject [Path.rel @"."])
        , testCase "reads an explicit packages list" do
            decode "packages:\n  - foo\n  - bar\n"
                @?= Right (StackProject [Path.rel @"foo", Path.rel @"bar"])
        , testCase "keeps an explicitly empty packages list" do
            decode "packages: []\n"
                @?= Right (StackProject [])
        ]
  where
    decode :: ByteString -> Either String StackProject
    decode = first show . Yaml.decodeEither'
