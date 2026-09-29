module Unit.Tricorder.Build.ByteSizeSpec (test_ByteSize) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Build.ByteSize (ByteSize (..), Unit (..))

import Tricorder.Build.ByteSize qualified as ByteSize


test_ByteSize :: TestTree
test_ByteSize =
    testGroup
        "ByteSize"
        [ testGroup "fromText" testFromText
        ]


testFromText :: [TestTree]
testFromText =
    [ testCase "parses no unit as bytes" do
        ByteSize.fromText "1000" @?= Just (ByteSize 1000 B)
    , testCase "parses bytes with unit" do
        ByteSize.fromText "1000B" @?= Just (ByteSize 1000 B)
    , testCase "parses decimal kilobytes" do
        ByteSize.fromText "10kb" @?= Just (ByteSize 10 KB)
    , testCase "parses binary kibibytes" do
        ByteSize.fromText "10kib" @?= Just (ByteSize 10 KiB)
    , testCase "parses decimal megabytes" do
        ByteSize.fromText "1mb" @?= Just (ByteSize 1 MB)
    , testCase "parses binary mebibytes" do
        ByteSize.fromText "1mib" @?= Just (ByteSize 1 MiB)
    , testCase "parses decimal gigabytes" do
        ByteSize.fromText "1gb" @?= Just (ByteSize 1 GB)
    , testCase "parses binary gibibytes" do
        ByteSize.fromText "1gib" @?= Just (ByteSize 1 GiB)
    , testCase "parses decimal terabytes" do
        ByteSize.fromText "1tb" @?= Just (ByteSize 1 TB)
    , testCase "parses binary tebibytes" do
        ByteSize.fromText "1tib" @?= Just (ByteSize 1 TiB)
    , testCase "parses decimal petabytes" do
        ByteSize.fromText "1pb" @?= Just (ByteSize 1 PB)
    , testCase "parses binary pebibytes" do
        ByteSize.fromText "1pib" @?= Just (ByteSize 1 PiB)
    , testCase "allows a space between the number and the unit" do
        ByteSize.fromText "10 kb" @?= Just (ByteSize 10 KB)
    , testCase "allows multiple spaces between the number and the unit" do
        ByteSize.fromText "10   kb" @?= Just (ByteSize 10 KB)
    , testCase "is case-insensitive on the unit" do
        ByteSize.fromText "10KB" @?= Just (ByteSize 10 KB)
        ByteSize.fromText "10Kb" @?= Just (ByteSize 10 KB)
        ByteSize.fromText "10KiB" @?= Just (ByteSize 10 KiB)
    , testCase "fails when there is no number" do
        ByteSize.fromText "kb" @?= Nothing
    , testCase "fails on an unrecognized unit" do
        ByteSize.fromText "10xb" @?= Nothing
    , testCase "fails on empty text" do
        ByteSize.fromText "" @?= Nothing
    , testCase "fails on unrelated text" do
        ByteSize.fromText "hello world" @?= Nothing
    ]
