module Tricorder.CLI.Arguments.Test (parser) where

import Options.Applicative
    ( FlagFields
    , Mod
    , Parser
    , ParserInfo
    , argument
    , auto
    , command
    , flag
    , help
    , hsubparser
    , info
    , long
    , metavar
    , progDesc
    , short
    , strArgument
    )
import Tricorder.CLI.Command.Test (Command, failedOnlyFlagName, failedOnlyFlagShortName)

import Tricorder.CLI.Command.Test qualified as Test


parser :: ParserInfo Command
parser =
    info commandParser (progDesc "See statuses and information on configured test suites.")


commandParser :: Parser Command
commandParser =
    hsubparser
        $ command "suites" (info suitesParser (progDesc "Show test suite statuses."))
            <> command "suite" (info suiteParser (progDesc "Show test cases for a specific test suite."))
            <> command "case" (info caseParser (progDesc "Show a single test case in a test suite."))


suitesParser :: Parser Command
suitesParser =
    Test.Suites
        <$> filterParser (help "Show only failed test suites")


suiteParser :: Parser Command
suiteParser =
    Test.Suite
        <$> strArgument (metavar "test-target-name")
        <*> filterParser (help "Show only failed test cases")


filterParser :: Mod FlagFields Test.Filter -> Parser Test.Filter
filterParser extraMods =
    flag
        Test.All
        Test.FailedOnly
        ( long failedOnlyFlagName
            <> short failedOnlyFlagShortName
            <> extraMods
        )


caseParser :: Parser Command
caseParser =
    Test.Case
        <$> strArgument (metavar "test-target-name")
        <*> argument auto (metavar "test-case-index")
