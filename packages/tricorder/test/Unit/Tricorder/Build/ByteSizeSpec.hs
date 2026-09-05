module Unit.Tricorder.Build.ByteSizeSpec (spec_ByteSize) where

import Test.Hspec (Spec, describe, it, shouldBe)

import Tricorder.Build.ByteSize (ByteSize (..), Unit (..))

import Tricorder.Build.ByteSize qualified as ByteSize


spec_ByteSize :: Spec
spec_ByteSize = describe "fromText" testFromText


testFromText :: Spec
testFromText = do
    it "parses no unit as bytes" do
        ByteSize.fromText "1000" `shouldBe` Just (ByteSize 1000 B)

    it "parses bytes with unit" do
        ByteSize.fromText "1000B" `shouldBe` Just (ByteSize 1000 B)

    it "parses decimal kilobytes" do
        ByteSize.fromText "10kb" `shouldBe` Just (ByteSize 10 KB)

    it "parses binary kibibytes" do
        ByteSize.fromText "10kib" `shouldBe` Just (ByteSize 10 KiB)

    it "parses decimal megabytes" do
        ByteSize.fromText "1mb" `shouldBe` Just (ByteSize 1 MB)

    it "parses binary mebibytes" do
        ByteSize.fromText "1mib" `shouldBe` Just (ByteSize 1 MiB)

    it "parses decimal gigabytes" do
        ByteSize.fromText "1gb" `shouldBe` Just (ByteSize 1 GB)

    it "parses binary gibibytes" do
        ByteSize.fromText "1gib" `shouldBe` Just (ByteSize 1 GiB)

    it "parses decimal terabytes" do
        ByteSize.fromText "1tb" `shouldBe` Just (ByteSize 1 TB)

    it "parses binary tebibytes" do
        ByteSize.fromText "1tib" `shouldBe` Just (ByteSize 1 TiB)

    it "parses decimal petabytes" do
        ByteSize.fromText "1pb" `shouldBe` Just (ByteSize 1 PB)

    it "parses binary pebibytes" do
        ByteSize.fromText "1pib" `shouldBe` Just (ByteSize 1 PiB)

    it "allows a space between the number and the unit" do
        ByteSize.fromText "10 kb" `shouldBe` Just (ByteSize 10 KB)

    it "allows multiple spaces between the number and the unit" do
        ByteSize.fromText "10   kb" `shouldBe` Just (ByteSize 10 KB)

    it "is case-insensitive on the unit" do
        ByteSize.fromText "10KB" `shouldBe` Just (ByteSize 10 KB)
        ByteSize.fromText "10Kb" `shouldBe` Just (ByteSize 10 KB)
        ByteSize.fromText "10KiB" `shouldBe` Just (ByteSize 10 KiB)

    it "fails when there is no number" do
        ByteSize.fromText "kb" `shouldBe` Nothing

    it "fails on an unrecognized unit" do
        ByteSize.fromText "10xb" `shouldBe` Nothing

    it "fails on empty text" do
        ByteSize.fromText "" `shouldBe` Nothing

    it "fails on unrelated text" do
        ByteSize.fromText "hello world" `shouldBe` Nothing
