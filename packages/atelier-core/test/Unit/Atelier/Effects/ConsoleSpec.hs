module Unit.Atelier.Effects.ConsoleSpec (spec_Console) where

import Effectful (runPureEff)
import Test.Hspec (Spec, describe, it, shouldBe)

import Atelier.Effects.Console (runConsoleToList)

import Atelier.Effects.Console qualified as Console


spec_Console :: Spec
spec_Console = do
    describe "runConsoleToList" $ do
        describe "when nothing is logged" $ it "returns an empty list" $ do
            let (_, msgs) = runPureEff $ runConsoleToList $ pure ()
            msgs `shouldBe` []

        describe "when logging once" $ it "collects a single traced message" $ do
            let (_, msgs) = runPureEff $ runConsoleToList $ Console.putStr "hello"
            msgs `shouldBe` ["hello"]

        it "collects multiple logged messages in order" $ do
            let (_, msgs) =
                    runPureEff . runConsoleToList $ do
                        Console.putStr "first"
                        Console.putStr "second"
                        Console.putStr "third"
            msgs `shouldBe` ["first", "second", "third"]

        it "returns the result alongside the traced messages" $ do
            let (result, msgs) =
                    runPureEff . runConsoleToList $ do
                        Console.putStr "side effect"
                        pure (42 :: Int)
            result `shouldBe` 42
            msgs `shouldBe` ["side effect"]

        it "traceLn appends a newline to the message" $ do
            let (_, msgs) = runPureEff $ runConsoleToList $ Console.putStrLn "line"
            msgs `shouldBe` ["line\n"]
