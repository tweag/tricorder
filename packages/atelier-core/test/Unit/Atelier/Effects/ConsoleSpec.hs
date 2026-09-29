module Unit.Atelier.Effects.ConsoleSpec (test_Console) where

import Effectful (runPureEff)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.Effects.Console (runConsoleToList)

import Atelier.Effects.Console qualified as Console


test_Console :: TestTree
test_Console =
    testGroup
        "Console"
        [ testGroup
            "runConsoleToList"
            [ testGroup
                "when nothing is logged"
                [ testCase "returns an empty list" $ do
                    let (_, msgs) = runPureEff $ runConsoleToList $ pure ()
                    msgs @?= []
                ]
            , testGroup
                "when logging once"
                [ testCase "collects a single traced message" $ do
                    let (_, msgs) = runPureEff $ runConsoleToList $ Console.putStr "hello"
                    msgs @?= ["hello"]
                ]
            , testCase "collects multiple logged messages in order" $ do
                let (_, msgs) =
                        runPureEff . runConsoleToList $ do
                            Console.putStr "first"
                            Console.putStr "second"
                            Console.putStr "third"
                msgs @?= ["first", "second", "third"]
            , testCase "returns the result alongside the traced messages" $ do
                let (result, msgs) =
                        runPureEff . runConsoleToList $ do
                            Console.putStr "side effect"
                            pure (42 :: Int)
                result @?= 42
                msgs @?= ["side effect"]
            , testCase "traceLn appends a newline to the message" $ do
                let (_, msgs) = runPureEff $ runConsoleToList $ Console.putStrLn "line"
                msgs @?= ["line\n"]
            ]
        ]
