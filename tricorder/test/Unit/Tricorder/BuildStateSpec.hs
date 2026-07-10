module Unit.Tricorder.BuildStateSpec (spec_BuildState) where

import Data.Aeson (eitherDecode, encode)
import Data.Time (UTCTime (..), fromGregorian)
import Test.Hspec

import Tricorder.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , PostBuild (..)
    , Severity (..)
    )


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

        -- Guards the wire format for the BuildFailed phase: the captured
        -- cabal/build error (multi-line, Unicode) must round-trip intact so
        -- the CLI/UI clients can render it.
        it "survives a BuildFailed phase with a multi-line message" do
            let bs =
                    mkBuildState [] :: BuildState
                failed =
                    bs
                        { phase =
                            BuildFailed
                                "cabal: Could not resolve dependencies:\n[__0] trying: \8216base\8217\nrejecting: ..."
                        }
            eitherDecode (encode failed) `shouldBe` Right failed


mkBuildState :: [Diagnostic] -> BuildState
mkBuildState msgs =
    BuildState
        { buildId = BuildId 1
        , phase =
            BuildComplete
                ( BuildResult
                    { completedAt = epoch
                    , duration = 0
                    , moduleCount = 0
                    , diagnostics = msgs
                    }
                )
                $ PostBuild mempty mempty
        , daemonInfo =
            DaemonInfo
                { targets = []
                , watchDirs = []
                , sockPath = ""
                , logFile = ""
                , metricsPort = Nothing
                }
        }
  where
    epoch = UTCTime (fromGregorian 1970 1 1) 0
