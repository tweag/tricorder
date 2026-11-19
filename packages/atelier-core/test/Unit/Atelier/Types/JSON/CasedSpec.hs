{-# LANGUAGE AllowAmbiguousTypes #-}

module Unit.Atelier.Types.JSON.CasedSpec (test_Cased) where

import Data.Aeson (FromJSON, ToJSON, Value, eitherDecode, encode, object, toJSON, (.=))
import Data.Default (Default (..))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Data.Aeson.Key qualified as Key

import Atelier.Types.JSON.Cased (Cased (..), Casing (..), KnownCasing (..), applyCasing)
import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Atelier.Types.JSON.WithDefaults (WithDefaults (..))


data Fixture = Fixture
    { maxRetries :: Int
    , httpURL :: Text
    , ipv4Address :: Text
    }
    deriving stock (Eq, Generic, Show)


instance Default Fixture where
    def = Fixture {maxRetries = 3, httpURL = "http://localhost", ipv4Address = "127.0.0.1"}


data Mode = DryRun | FullRun
    deriving stock (Eq, Generic, Show)


data Settings = Settings
    { retries :: Int
    , dryRun :: Bool
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via Cased 'PascalCase Settings
    deriving (FromJSON) via WithDefaults (Cased 'PascalCase Settings)


instance Default Settings where
    def = Settings {retries = 3, dryRun = False}


test_Cased :: TestTree
test_Cased =
    testGroup
        "Atelier.Types.JSON.Cased"
        [ testGroup "applyCasing" testApplyCasing
        , testGroup "encoding" testEncoding
        , testGroup "round trip" testRoundTrip
        , testGroup "QuietSnake compatibility" testQuietSnake
        , testGroup "WithDefaults" testWithDefaults
        ]


testWithDefaults :: [TestTree]
testWithDefaults =
    [ testCase "wrapping Cased directly fills missing fields" do
        getCased . getWithDefaults
            <$> eitherDecode @(WithDefaults (Cased 'KebabCase Fixture)) "{\"max-retries\": 7}"
            @?= Right def {maxRetries = 7}
    , testCase "deriving via fills missing fields" do
        eitherDecode @Settings "{\"Retries\": 7}"
            @?= Right Settings {retries = 7, dryRun = False}
    , testCase "deriving via decodes an empty object to the default" do
        eitherDecode @Settings "{}" @?= Right def
    , testCase "deriving via ignores keys in another casing" do
        eitherDecode @Settings "{\"retries\": 7, \"DryRun\": true}"
            @?= Right Settings {retries = 3, dryRun = True}
    , testCase "deriving via round trips" do
        let settings = Settings {retries = 9, dryRun = True}
        eitherDecode @Settings (encode settings) @?= Right settings
    ]


testApplyCasing :: [TestTree]
testApplyCasing =
    [ casingCase "maxRetries" "maxRetries" "MaxRetries" "max_retries" "MAX_RETRIES" "max-retries"
    , casingCase "httpURL" "httpUrl" "HttpUrl" "http_url" "HTTP_URL" "http-url"
    , casingCase "HTTPServer" "httpServer" "HttpServer" "http_server" "HTTP_SERVER" "http-server"
    , casingCase "ipv4Address" "ipv4Address" "Ipv4Address" "ipv4_address" "IPV4_ADDRESS" "ipv4-address"
    , casingCase "DryRun" "dryRun" "DryRun" "dry_run" "DRY_RUN" "dry-run"
    , casingCase "x" "x" "X" "x" "X" "x"
    , casingCase "fooBar_baz" "fooBarBaz" "FooBarBaz" "foo_bar_baz" "FOO_BAR_BAZ" "foo-bar-baz"
    , casingCase "_foo" "foo" "Foo" "_foo" "FOO" "foo"
    ]
  where
    casingCase input camel pascal snake screaming kebab =
        testCase input do
            map (`applyCasing` input) [minBound .. maxBound]
                @?= [camel, pascal, snake, screaming, kebab]


testEncoding :: [TestTree]
testEncoding =
    [ testCase "CamelCase" do
        toJSON (Cased @'CamelCase fixture) @?= fixtureJson "maxRetries" "httpUrl" "ipv4Address"
        toJSON (Cased @'CamelCase DryRun) @?= "dryRun"
    , testCase "PascalCase" do
        toJSON (Cased @'PascalCase fixture) @?= fixtureJson "MaxRetries" "HttpUrl" "Ipv4Address"
        toJSON (Cased @'PascalCase DryRun) @?= "DryRun"
    , testCase "QuietSnakeCase" do
        toJSON (Cased @'QuietSnakeCase fixture) @?= fixtureJson "max_retries" "http_url" "ipv4_address"
        toJSON (Cased @'QuietSnakeCase DryRun) @?= "dry_run"
    , testCase "ScreamingSnakeCase" do
        toJSON (Cased @'ScreamingSnakeCase fixture) @?= fixtureJson "MAX_RETRIES" "HTTP_URL" "IPV4_ADDRESS"
        toJSON (Cased @'ScreamingSnakeCase DryRun) @?= "DRY_RUN"
    , testCase "KebabCase" do
        toJSON (Cased @'KebabCase fixture) @?= fixtureJson "max-retries" "http-url" "ipv4-address"
        toJSON (Cased @'KebabCase DryRun) @?= "dry-run"
    ]


testRoundTrip :: [TestTree]
testRoundTrip =
    [ roundTrip @'CamelCase
    , roundTrip @'PascalCase
    , roundTrip @'QuietSnakeCase
    , roundTrip @'ScreamingSnakeCase
    , roundTrip @'KebabCase
    ]
  where
    roundTrip :: forall c. (KnownCasing c) => TestTree
    roundTrip =
        testCase (show (casingVal @c)) do
            getCased <$> eitherDecode @(Cased c Fixture) (encode (Cased @c fixture))
                @?= Right fixture


testQuietSnake :: [TestTree]
testQuietSnake =
    [ testCase "QuietSnake encodes like Cased 'QuietSnakeCase" do
        encode (QuietSnake fixture) @?= encode (Cased @'QuietSnakeCase fixture)
        encode (QuietSnake FullRun) @?= encode (Cased @'QuietSnakeCase FullRun)
    ]


fixture :: Fixture
fixture = Fixture {maxRetries = 5, httpURL = "https://example.com", ipv4Address = "10.0.0.1"}


fixtureJson :: Text -> Text -> Text -> Value
fixtureJson retriesKey urlKey ipKey =
    object
        [ Key.fromText retriesKey .= fixture.maxRetries
        , Key.fromText urlKey .= fixture.httpURL
        , Key.fromText ipKey .= fixture.ipv4Address
        ]
