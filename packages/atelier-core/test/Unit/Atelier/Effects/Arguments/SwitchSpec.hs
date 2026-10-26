module Unit.Atelier.Effects.Arguments.SwitchSpec (test_Switch) where

import Options.Applicative
    ( Parser
    , ParserResult (..)
    , defaultPrefs
    , execParserPure
    , help
    , helper
    , info
    , long
    , renderFailure
    , short
    )
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertFailure, testCase, (@?=))

import Data.List qualified as List

import Atelier.Effects.Arguments.Switch qualified as Switch


useCurrent :: Parser Bool
useCurrent = Switch.parser (long "use-current" <> short 'c' <> help "Use the current status.")


parse :: [String] -> Maybe Bool
parse args = case execParserPure defaultPrefs (info useCurrent mempty) args of
    Success b -> Just b
    _ -> Nothing


helpText :: IO String
helpText = case execParserPure defaultPrefs (info (useCurrent <**> helper) mempty) ["--help"] of
    Failure failure -> pure $ fst $ renderFailure failure "prog"
    _ -> assertFailure "expected --help to produce help text"


test_Switch :: TestTree
test_Switch =
    testGroup
        "Switch"
        [ testCase "defaults to False" do
            parse [] @?= Just False
        , testCase "--<name> enables" do
            parse ["--use-current"] @?= Just True
        , testCase "short name enables" do
            parse ["-c"] @?= Just True
        , testCase "--no-<name> disables" do
            parse ["--no-use-current"] @?= Just False
        , testCase "last flag wins when enabling" do
            parse ["--no-use-current", "--use-current"] @?= Just True
        , testCase "last flag wins when disabling" do
            parse ["-c", "--no-use-current"] @?= Just False
        , testCase "last flag wins across many flags" do
            parse ["--use-current", "--no-use-current", "-c", "--no-use-current"] @?= Just False
        , testCase "help shows the combined flag" do
            text <- helpText
            List.lines text
                @?= [ "Usage: prog [-c,--[no-]use-current]"
                    , ""
                    , "Available options:"
                    , "  -c,--[no-]use-current    Use the current status."
                    , "  -h,--help                Show this help text"
                    ]
        ]
