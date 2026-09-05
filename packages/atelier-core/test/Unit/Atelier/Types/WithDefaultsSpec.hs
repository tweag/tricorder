module Unit.Atelier.Types.WithDefaultsSpec (spec_WithDefaults) where

import Data.Aeson (FromJSON, ToJSON, eitherDecode)
import Data.Default (Default (..))
import Test.Hspec

import Data.ByteString.Lazy qualified as LBS

import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))


-- | A minimal fixture type with non-Maybe list fields to exercise WithDefaults.
data Fixture = Fixture
    { requiredField :: Text
    , items :: [Text]
    , count :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake Fixture


instance Default Fixture where
    def =
        Fixture
            { requiredField = "default-value"
            , items = ["default-item"]
            , count = 0
            }


decodeWithDefaults :: LBS.ByteString -> Either String Fixture
decodeWithDefaults bs = getQuietSnake . getWithDefaults <$> eitherDecode @(WithDefaults (QuietSnake Fixture)) bs


spec_WithDefaults :: Spec
spec_WithDefaults = do
    describe "WithDefaults" do
        it "falls back to Default values for missing non-Maybe fields" do
            let result = decodeWithDefaults "{}"
            result `shouldBe` Right def

        it "uses provided values when all fields are present" do
            let result =
                    decodeWithDefaults
                        "{\"required_field\": \"hello\", \"items\": [\"a\", \"b\"], \"count\": 42}"
            result
                `shouldBe` Right
                    Fixture
                        { requiredField = "hello"
                        , items = ["a", "b"]
                        , count = 42
                        }

        it "partial object: provided fields override defaults, missing fall back" do
            let result = decodeWithDefaults "{\"count\": 7}"
            result
                `shouldBe` Right
                    def {count = 7}

        it "explicitly provided empty list overrides the default list" do
            let result = decodeWithDefaults "{\"items\": []}"
            result `shouldBe` Right def {items = []}
