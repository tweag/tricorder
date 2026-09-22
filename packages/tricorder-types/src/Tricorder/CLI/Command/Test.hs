module Tricorder.CLI.Command.Test
    ( Command (..)
    , SuitesOptions (..)
    , SuiteName
    , toArgs
    )
where

import Prelude hiding (All, filter)

import Tricorder.CLI.Command.FieldMask (FieldMask)
import Tricorder.CLI.Command.IfDaemonIsStopped (IfDaemonIsStopped)
import Tricorder.CLI.Command.OutputFormat (OutputFormat)
import Tricorder.CLI.Command.TestFilter (TestFilter)
import Tricorder.CLI.Command.WaitMode (WaitMode)

import Tricorder.CLI.Command.FieldMask qualified as FieldMask
import Tricorder.CLI.Command.IfDaemonIsStopped qualified as IfDaemonIsStopped
import Tricorder.CLI.Command.OutputFormat qualified as OutputFormat
import Tricorder.CLI.Command.TestFilter qualified as TestFilter
import Tricorder.CLI.Command.WaitMode qualified as WaitMode


data Command
    = Suites SuitesOptions


data SuitesOptions = SuitesOptions
    { suiteNames :: [SuiteName]
    -- ^ Test suites to show. Empty means all of them.
    , testFilter :: TestFilter
    , fields :: Maybe FieldMask
    -- ^ Fields to show for each test suite. 'Nothing' uses the default fields.
    , format :: OutputFormat
    , wait :: WaitMode
    , ifDaemonIsStopped :: IfDaemonIsStopped
    }


type SuiteName = Text


toArgs :: Command -> [String]
toArgs = \case
    Suites (SuitesOptions {suiteNames, testFilter, fields, format, wait, ifDaemonIsStopped}) ->
        "suites"
            : fmap toString suiteNames
                <> TestFilter.toArgs testFilter
                <> FieldMask.toArgs fields
                <> OutputFormat.toArgs format
                <> WaitMode.toArgs wait
                <> IfDaemonIsStopped.toArgs ifDaemonIsStopped
