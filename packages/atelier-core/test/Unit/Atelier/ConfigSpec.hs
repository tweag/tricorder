module Unit.Atelier.ConfigSpec (spec_Config) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import GHC.Generics (Generically (..))
import Test.Hspec (Spec, describe, it, shouldBe)

import Data.Aeson qualified as Aeson
import Data.Aeson.KeyMap qualified as KM

import Atelier.Config (LoadedConfig (..), extractNestedConfig)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))


spec_Config :: Spec
spec_Config = do
    describe "extractNestedConfig" testExtractNestedConfig


testExtractNestedConfig :: Spec
testExtractNestedConfig = do
    it "should use default value for non-object Values" do
        let actual = extractNestedConfig @"foo" $ LoadedConfig $ Aeson.String "foo"
        actual `shouldBe` Val "default"

    it "should fetch top-level property" do
        let actual =
                extractNestedConfig @"foo"
                    $ LoadedConfig
                    $ Aeson.Object
                    $ KM.singleton "foo"
                    $ Aeson.Object
                    $ KM.singleton "value"
                    $ Aeson.String "actual"
        actual `shouldBe` Val "actual"

    it "should return default for a missing key" do
        let actual =
                extractNestedConfig @"missing"
                    $ LoadedConfig
                    $ Aeson.Object KM.empty
        actual `shouldBe` Val "default"

    it "should fetch a nested property via dot notation" do
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
        actual `shouldBe` Val "nested"

    it "should return default for a missing intermediate segment" do
        let actual =
                extractNestedConfig @"foo.bar"
                    $ LoadedConfig
                    $ Aeson.Object KM.empty
        actual `shouldBe` Val "default"

    it "should return default for a missing leaf segment" do
        let actual =
                extractNestedConfig @"foo.bar"
                    $ LoadedConfig
                    $ Aeson.Object
                    $ KM.singleton "foo"
                    $ Aeson.Object KM.empty
        actual `shouldBe` Val "default"

    it "should return default when an intermediate value is not an object" do
        let actual =
                extractNestedConfig @"foo.bar"
                    $ LoadedConfig
                    $ Aeson.Object
                    $ KM.singleton "foo"
                    $ Aeson.String "not-an-object"
        actual `shouldBe` Val "default"

    it "should return default when the leaf value fails to decode" do
        let actual =
                extractNestedConfig @"foo"
                    $ LoadedConfig
                    $ Aeson.Object
                    $ KM.singleton "foo"
                    $ Aeson.String "not-an-object"
        actual `shouldBe` Val "default"


data Val = Val {value :: Text}
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via Generically Val
    deriving (FromJSON) via WithDefaults (QuietSnake Val)


instance Default Val where
    def = Val "default"
