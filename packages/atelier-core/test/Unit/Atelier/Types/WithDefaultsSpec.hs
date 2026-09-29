module Unit.Atelier.Types.WithDefaultsSpec (test_WithDefaults) where

import Data.Aeson (FromJSON, ToJSON, eitherDecode)
import Data.Default (Default (..))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

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


test_WithDefaults :: TestTree
test_WithDefaults =
    testGroup
        "WithDefaults"
        [ testGroup
            "WithDefaults"
            [ testCase "falls back to Default values for missing non-Maybe fields" do
                let result = decodeWithDefaults "{}"
                result @?= Right def
            , testCase "uses provided values when all fields are present" do
                let result =
                        decodeWithDefaults
                            "{\"required_field\": \"hello\", \"items\": [\"a\", \"b\"], \"count\": 42}"
                result
                    @?= Right
                        Fixture
                            { requiredField = "hello"
                            , items = ["a", "b"]
                            , count = 42
                            }
            , testCase "partial object: provided fields override defaults, missing fall back" do
                let result = decodeWithDefaults "{\"count\": 7}"
                result
                    @?= Right
                        def {count = 7}
            , testCase "explicitly provided empty list overrides the default list" do
                let result = decodeWithDefaults "{\"items\": []}"
                result @?= Right def {items = []}
            ]
        ]
