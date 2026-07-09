module Unit.Tricorder.BuildStateSpec (spec_BuildState) where

import Data.Aeson (eitherDecode, encode)
import Data.Time (UTCTime (..), fromGregorian)
import Test.Hspec

import Data.Map.Strict qualified as Map

import Tricorder.BuildState
    ( BuildId (..)
    , BuildOutput (..)
    , BuildRecord (..)
    , BuildResult (..)
    , BuildState (..)
    , CyclePhase (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , Severity (..)
    , TestOutput (..)
    )

import Tricorder.BuildState.Test qualified as Test


spec_BuildState :: Spec
spec_BuildState = do
    describe "JSON round-trip" do
        it "survives Unicode smart quotes in message text" do
            let msg =
                    Diagnostic
                        { severity = SWarning
                        , file = "<interactive>"
                        , line = 2
                        , col = 8
                        , endLine = 2
                        , endCol = 8
                        , title = "Found \8216qualified\8217 in prepositive position"
                        , text = "Found \8216qualified\8217 in prepositive position\n    Suggested fixes:\n      \8226 Place \8216qualified\8217 after the module name."
                        }
                bs = mkBuildState [msg]
            eitherDecode (encode bs) `shouldBe` Right bs

        it "survives control characters in message text" do
            let msg =
                    Diagnostic
                        { severity = SWarning
                        , file = "<interactive>"
                        , line = 1
                        , col = 1
                        , endLine = 1
                        , endCol = 1
                        , title = "text with \CAN control \EM chars and \ESC[1m ANSI \ESC[0m codes"
                        , text = "text with \CAN control \EM chars and \ESC[1m ANSI \ESC[0m codes"
                        }
                bs = mkBuildState [msg]
            eitherDecode (encode bs) `shouldBe` Right bs

        it "survives curly double quotes in message text" do
            let msg =
                    Diagnostic
                        { severity = SWarning
                        , file = "<interactive>"
                        , line = 1
                        , col = 1
                        , endLine = 1
                        , endCol = 1
                        , title = "\8220Place qualified after the module name.\8221"
                        , text = "\8220Place qualified after the module name.\8221"
                        }
                bs = mkBuildState [msg]
            eitherDecode (encode bs) `shouldBe` Right bs

        -- Guards the wire format for the Failed cycle arm: the captured
        -- cabal/build error (multi-line, Unicode) must round-trip intact so
        -- the CLI/UI clients can render it.
        it "survives a Failed cycle with a multi-line message" do
            let bs =
                    mkBuildState [] :: BuildState
                failed =
                    bs
                        { cycle =
                            Failed
                                "cabal: Could not resolve dependencies:\n[__0] trying: \8216base\8217\nrejecting: ..."
                        }
            eitherDecode (encode failed) `shouldBe` Right failed

        -- Guards the buildId-keyed history: the Map BuildId BuildRecord must
        -- round-trip, i.e. the BuildId newtype's ToJSONKey/FromJSONKey work.
        it "survives a multi-build history (K=2)" do
            let bs = mkBuildState []
                twoBuilds =
                    bs
                        { current = BuildId 3
                        , history =
                            Map.fromList
                                [ (BuildId 2, BuildRecord (Built (mkResult [])) (TestsDone (Test.Suites mempty)))
                                , (BuildId 3, BuildRecord (Built (mkResult [])) TestsIdle)
                                ]
                        }
            eitherDecode (encode twoBuilds) `shouldBe` Right twoBuilds


mkResult :: [Diagnostic] -> BuildResult
mkResult msgs =
    BuildResult
        { completedAt = epoch
        , duration = 0
        , moduleCount = 0
        , diagnostics = msgs
        }


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0


mkBuildState :: [Diagnostic] -> BuildState
mkBuildState msgs =
    BuildState
        { current = BuildId 1
        , cycle = Settled
        , history =
            Map.singleton (BuildId 1)
                $ BuildRecord (Built (mkResult msgs))
                $ TestsDone
                $ Test.Suites mempty
        , daemonInfo =
            DaemonInfo
                { targets = []
                , watchDirs = []
                , sockPath = ""
                , logFile = ""
                , metricsPort = Nothing
                }
        }
