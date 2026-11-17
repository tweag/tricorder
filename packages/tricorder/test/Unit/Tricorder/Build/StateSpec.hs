module Unit.Tricorder.Build.StateSpec (test_State) where

import Data.Aeson (eitherDecode, encode)
import Data.Time (UTCTime (..), fromGregorian)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.FileSystem.Path qualified as Path

import Tricorder.Build.Diagnostic (Diagnostic (..))
import Tricorder.Build.DiagnosticLocation (DiagnosticLocation (..))
import Tricorder.Build.Duration (Duration (..))
import Tricorder.Build.Id (Id (..))
import Tricorder.Build.Phase (Phase (..))
import Tricorder.Build.PostBuild (PostBuild (..))
import Tricorder.Build.Result (Result (..))
import Tricorder.Build.State (State (..))

import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Severity qualified as Severity


test_State :: TestTree
test_State =
    testGroup
        "Tricorder.Build.State"
        [ testGroup
            "JSON round-trip"
            [ testCase "survives Unicode smart quotes in message text" do
                let msg =
                        Diagnostic
                            { severity = Severity.Warning
                            , file = Location (Path.Relative (Path.rel @"<interactive>"))
                            , line = 2
                            , col = 8
                            , endLine = 2
                            , endCol = 8
                            , title = "Found \8216qualified\8217 in prepositive position"
                            , text =
                                "Found \8216qualified\8217 in prepositive position\n    Suggested fixes:\n      \8226 Place \8216qualified\8217 after the module name."
                            }
                    bs = mkBuildState [msg]
                eitherDecode (encode bs) @?= Right bs
            , testCase "survives control characters in message text" do
                let msg =
                        Diagnostic
                            { severity = Severity.Warning
                            , file = Location (Path.Relative (Path.rel @"<interactive>"))
                            , line = 1
                            , col = 1
                            , endLine = 1
                            , endCol = 1
                            , title = "text with \CAN control \EM chars and \ESC[1m ANSI \ESC[0m codes"
                            , text = "text with \CAN control \EM chars and \ESC[1m ANSI \ESC[0m codes"
                            }
                    bs = mkBuildState [msg]
                eitherDecode (encode bs) @?= Right bs
            , testCase "survives curly double quotes in message text" do
                let msg =
                        Diagnostic
                            { severity = Severity.Warning
                            , file = Location (Path.Relative (Path.rel @"<interactive>"))
                            , line = 1
                            , col = 1
                            , endLine = 1
                            , endCol = 1
                            , title = "\8220Place qualified after the module name.\8221"
                            , text = "\8220Place qualified after the module name.\8221"
                            }
                    bs = mkBuildState [msg]
                eitherDecode (encode bs) @?= Right bs
            , -- Guards the wire format for the BuildFailed phase: the captured
              -- cabal/build error (multi-line, Unicode) must round-trip intact so
              -- the CLI/UI clients can render it.
              testCase "survives a BuildFailed phase with a multi-line message" do
                let bs =
                        mkBuildState [] :: State
                    failed =
                        bs
                            { phase =
                                Failed
                                    "cabal: Could not resolve dependencies:\n[__0] trying: \8216base\8217\nrejecting: ..."
                            }
                eitherDecode (encode failed) @?= Right failed
            ]
        ]


mkBuildState :: [Diagnostic] -> State
mkBuildState msgs =
    State
        { buildId = Id 1
        , phase =
            Finished
                ( Result
                    { completedAt = epoch
                    , duration = Duration 0
                    , moduleCount = 0
                    , diagnostics = msgs
                    }
                )
                $ PostBuild mempty Eval.NoneFound
        }
  where
    epoch = UTCTime (fromGregorian 1970 1 1) 0
