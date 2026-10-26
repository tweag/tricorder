module Tricorder.API.Test
    ( Command (..)
    , SuitesOptions (..)
    , SuiteName
    , toArgs
    )
where

import Prelude hiding (All, filter)

import Tricorder.API.FieldMask (FieldMask)
import Tricorder.API.IfBuildIsPending (IfBuildIsPending)
import Tricorder.API.IfDaemonIsStopped (IfDaemonIsStopped)
import Tricorder.API.OutputFormat (OutputFormat)
import Tricorder.API.TestFilter (TestFilter)

import Tricorder.API.FieldMask qualified as FieldMask
import Tricorder.API.IfBuildIsPending qualified as IfBuildIsPending
import Tricorder.API.IfDaemonIsStopped qualified as IfDaemonIsStopped
import Tricorder.API.OutputFormat qualified as OutputFormat
import Tricorder.API.TestFilter qualified as TestFilter


data Command
    = Suites SuitesOptions


data SuitesOptions = SuitesOptions
    { suiteNames :: [SuiteName]
    -- ^ Test suites to show. Empty means all of them.
    , testFilter :: TestFilter
    , fields :: Maybe FieldMask
    -- ^ Fields to show for each test suite. 'Nothing' uses the default fields.
    , format :: OutputFormat
    , ifBuildIsPending :: IfBuildIsPending
    , ifDaemonIsStopped :: IfDaemonIsStopped
    }


type SuiteName = Text


toArgs :: Command -> [String]
toArgs = \case
    Suites (SuitesOptions {suiteNames, testFilter, fields, format, ifBuildIsPending, ifDaemonIsStopped}) ->
        "suites"
            : fmap toString suiteNames
                <> TestFilter.toArgs testFilter
                <> FieldMask.toArgs fields
                <> OutputFormat.toArgs format
                <> IfBuildIsPending.toArgs ifBuildIsPending
                <> IfDaemonIsStopped.toArgs ifDaemonIsStopped
