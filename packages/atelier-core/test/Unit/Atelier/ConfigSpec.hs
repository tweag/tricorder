module Unit.Atelier.ConfigSpec (test_Config) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import GHC.Generics (Generically (..))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Data.Aeson qualified as Aeson
import Data.Aeson.KeyMap qualified as KM

import Atelier.Config (LoadedConfig (..), extractNestedConfig)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))


test_Config :: TestTree
test_Config =
    testGroup
        "Config"
        [ testGroup "extractNestedConfig" testExtractNestedConfig
        ]


testExtractNestedConfig :: [TestTree]
testExtractNestedConfig =
    [ testCase "should use default value for non-object Values" do
        let actual = extractNestedConfig @"foo" $ LoadedConfig $ Aeson.String "foo"
        actual @?= Val "default"
    , testCase "should fetch top-level property" do
        let actual =
                extractNestedConfig @"foo"
                    $ LoadedConfig
                    $ Aeson.Object
                    $ KM.singleton "foo"
                    $ Aeson.Object
                    $ KM.singleton "value"
                    $ Aeson.String "actual"
        actual @?= Val "actual"
    , testCase "should return default for a missing key" do
        let actual =
                extractNestedConfig @"missing"
                    $ LoadedConfig
                    $ Aeson.Object KM.empty
        actual @?= Val "default"
    , testCase "should fetch a nested property via dot notation" do
        let actual =
                extractNestedConfig @"foo.bar"
                    $ LoadedConfig
                    $ Aeson.Object
                    $ KM.singleton "foo"
                    $ Aeson.Object
                    $ KM.singleton "bar"
                    $ Aeson.Object
                    $ KM.singleton "value"
                    $ Aeson.String "nested"
        actual @?= Val "nested"
    , testCase "should return default for a missing intermediate segment" do
        let actual =
                extractNestedConfig @"foo.bar"
                    $ LoadedConfig
                    $ Aeson.Object KM.empty
        actual @?= Val "default"
    , testCase "should return default for a missing leaf segment" do
        let actual =
                extractNestedConfig @"foo.bar"
                    $ LoadedConfig
                    $ Aeson.Object
                    $ KM.singleton "foo"
                    $ Aeson.Object KM.empty
        actual @?= Val "default"
    , testCase "should return default when an intermediate value is not an object" do
        let actual =
                extractNestedConfig @"foo.bar"
                    $ LoadedConfig
                    $ Aeson.Object
                    $ KM.singleton "foo"
                    $ Aeson.String "not-an-object"
        actual @?= Val "default"
    , testCase "should return default when the leaf value fails to decode" do
        let actual =
                extractNestedConfig @"foo"
                    $ LoadedConfig
                    $ Aeson.Object
                    $ KM.singleton "foo"
                    $ Aeson.String "not-an-object"
        actual @?= Val "default"
    ]


data Val = Val {value :: Text}
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via Generically Val
    deriving (FromJSON) via WithDefaults (QuietSnake Val)


instance Default Val where
    def = Val "default"
