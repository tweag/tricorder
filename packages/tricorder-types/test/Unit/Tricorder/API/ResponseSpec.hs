module Unit.Tricorder.API.ResponseSpec (test_Response) where

import Autodocodec (JSONCodec, toJSONVia)
import Autodocodec.Schema (jsonSchemaVia, validateAccordingTo)
import Data.Aeson (object, (.=))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Autodocodec qualified

import Tricorder.API.Response (MessageWithLoc (..), Response (..), codec)


test_Response :: TestTree
test_Response =
    testGroup
        "Tricorder.API.Response"
        [ testCase "encodes each constructor as an object with a single key" do
            toJSONVia responseCodec <$> [Error message, Pending message, Success 1]
                @?= [ object ["error" .= messageJson]
                    , object ["pending" .= messageJson]
                    , object ["success" .= (1 :: Int)]
                    ]
        , testCase "every constructor matches the schema" do
            for_ [Error message, Pending message, Success 1] \response ->
                assertBool (show response) $ validateAccordingTo (toJSONVia responseCodec response) schema
        , testCase "the schema rejects more than one key" do
            assertBool "accepted"
                $ not
                $ validateAccordingTo (object ["error" .= messageJson, "pending" .= messageJson]) schema
        , testCase "the schema checks the payload" do
            assertBool "accepted" $ not $ validateAccordingTo (object ["success" .= ("one" :: Text)]) schema
        ]
  where
    message = MessageWithLoc "build" "message"
    messageJson = object ["location" .= ("build" :: Text), "message" .= ("message" :: Text)]

    responseCodec :: JSONCodec (Response Int)
    responseCodec = codec Autodocodec.codec

    schema = jsonSchemaVia responseCodec
