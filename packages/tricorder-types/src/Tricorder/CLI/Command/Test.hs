module Tricorder.CLI.Command.Test
    ( Command (..)
    , SuiteName
    , CaseNumber
    , Filter (..)
    , commandToArgs
    , failedOnlyFlagName
    , failedOnlyFlagShortName
    )
where

import Prelude hiding (All, filter)

import Tricorder.CLI.Command.WaitMode (WaitMode)

import Tricorder.CLI.Command.WaitMode qualified as WaitMode


data Command
    = Suites Filter WaitMode
    | Suite SuiteName Filter WaitMode
    | Case SuiteName CaseNumber WaitMode


type SuiteName = Text


type CaseNumber = Word


data Filter = All | FailedOnly


commandToArgs :: Command -> [String]
commandToArgs = \case
    Suites filter waitMode ->
        ["test", "suites"]
            <> filterToArgs filter
            <> WaitMode.toArgs waitMode
    Suite suiteName filter waitMode ->
        ["test", "suite", toString suiteName]
            <> filterToArgs filter
            <> WaitMode.toArgs waitMode
    Case suiteName caseName waitMode ->
        ["test", "case", toString suiteName, show caseName]
            <> WaitMode.toArgs waitMode


filterToArgs :: Filter -> [String]
filterToArgs All = []
filterToArgs FailedOnly = ["--" <> failedOnlyFlagName]


failedOnlyFlagName :: String
failedOnlyFlagName = "failed-only"


failedOnlyFlagShortName :: Char
failedOnlyFlagShortName = 'f'
