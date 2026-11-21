module Unit.Tricorder.Daemon.Ghci.SessionSpec (test_Session) where

import Atelier.Effects.PubSub.Pub (Pub)
import Atelier.Time (AsRawUnit (..))
import Control.Exception (ErrorCall (..))
import Data.Default (def)
import Effectful (IOE, runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Exception (try)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, assertFailure, testCase, (@?=))

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Handles qualified as Handles
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Process qualified as Process
import Atelier.Effects.PubSub.Pub qualified as Pub
import Atelier.Effects.Timeout qualified as Timeout
import Atelier.FileSystem.Path qualified as Path
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text qualified as T
import System.Timeout qualified

import Tricorder.Build.Diagnostic (Diagnostic (..))
import Tricorder.Build.DiagnosticLocation (DiagnosticLocation (..))
import Tricorder.Build.Progress (Progress)
import Tricorder.Daemon.Ghci.Config (Config (..))
import Tricorder.Daemon.Ghci.Controls (Controls (..))
import Tricorder.Daemon.Ghci.LoadResult (LoadResult (..))
import Tricorder.Daemon.Ghci.Process (Error (StartupTimeout))
import Tricorder.Daemon.Ghci.Session (Session)
import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.Command.RenderedCommand (RenderedCommand (..))
import Tricorder.Session.Stage (Stage (..))

import Tricorder.Build.Severity qualified as Build.Severity
import Tricorder.Daemon.Ghci.Session qualified as Session


test_Session :: TestTree
test_Session =
    testGroup
        "Session"
        [ testGroup "GHCi subprocess" testSubprocess
        , testGroup "runScripted" testScripted
        ]


testSubprocess :: [TestTree]
testSubprocess =
    [ testCase "uses the configured banner timeout" testStartupTimeout
    , testCase "uses configured setup commands and shutdown timeout" testSetupAndShutdown
    ]


testStartupTimeout :: IO ()
testStartupTimeout = do
    -- Give up on startup immediately
    let config = def {startupTimeout = AsRawUnit 0} :: Config
        -- This subprocess never prints a GHCi banner. If the startupTimeout is
        -- honored, it should time out immediately.
        command = RenderedCommand "exec sleep 30"
    result <-
        -- If we ever have a regression, this will prevent the test from
        -- hanging for the full 30s
        System.Timeout.timeout 5_000_000
            $ runEff
                . runConcurrent
                . Timeout.run
                . Handles.run
                . Log.runNoOp
                . Conc.runIO
                . Process.run
                . Session.run
            $ try @Error
            $ Session.with config (\_ -> pure ()) command (ProjectRoot (Path.absolute @"/")) \_ _ -> pure ()
    case result of
        Just (Left StartupTimeout) -> pure ()
        _ -> assertFailure "expected the configured banner timeout to expire immediately"


testSetupAndShutdown :: IO ()
testSetupAndShutdown = do
    let config =
            -- Don't wait for a graceful exit after :quit
            def
                { shutdownTimeout = AsRawUnit 0
                , extraSetupCommands = ["configured-setup"]
                }
        -- The fake REPL echoes sync markers on stdout and stderr only after it receives
        -- the setup command. It delays exit after :quit so if shutdownTimeout
        -- is respected, it should time out immediately.
        command =
            RenderedCommand
                $ T.unlines
                    [ "printf 'GHCi, version fake\\n'"
                    , "ready="
                    , "while IFS= read -r line; do"
                    , "  case \"$line\" in"
                    , "    configured-setup) ready=yes ;;"
                    , "    *TRI-FINISH*)"
                    , "      [ \"$ready\" = yes ] || exit 1"
                    , "      printf '%s\\n' \"$line\""
                    , "      printf '%s\\n' \"$line\" >&2 ;;"
                    , "    :quit) sleep 30; exit ;;"
                    , "  esac"
                    , "done"
                    ]
    result <-
        -- Fail the test if the session doesn't honor the shutdownTimeout of 0
        System.Timeout.timeout 2_000_000
            $ runEff
                . runConcurrent
                . Timeout.run
                . Handles.run
                . Log.runNoOp
                . Conc.runIO
                . Process.run
                . Session.run
            $ Session.with config (\_ -> pure ()) command (ProjectRoot (Path.absolute @"/")) \_ _ -> pure ()
    result @?= Just ()


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: [TestTree]
testScripted =
    [ testGroup
        "withGhci"
        [ testGroup
            "initial load"
            [ testCase "returns scripted messages" do
                LoadResult {diagnostics = msgs} <-
                    runScripted [simpleResult [errMsg]]
                        $ Session.with def Pub.publish cmd (ProjectRoot (Path.absolute @"/")) \initial _ -> pure initial
                msgs @?= [errMsg]
            , testCase "returns empty list when scripted result has no messages" do
                LoadResult {diagnostics = msgs} <-
                    runScripted [simpleResult []]
                        $ Session.with def Pub.publish cmd (ProjectRoot (Path.absolute @"/")) \initial _ -> pure initial
                msgs @?= []
            , testCase "throws when scripted result is Left" do
                result <-
                    runScripted [Left (toException boom)]
                        $ try @ErrorCall
                        $ Session.with def Pub.publish cmd (ProjectRoot (Path.absolute @"/")) \initial _ -> pure initial
                result @?= Left boom
            ]
        , testGroup
            "reloading"
            [ testCase "returns scripted messages" do
                LoadResult {diagnostics = msgs} <-
                    runScripted [simpleResult [warnMsg], simpleResult [errMsg]]
                        $ Session.with def Pub.publish cmd (ProjectRoot (Path.absolute @"/")) \_ controls -> controls.reload
                msgs @?= [errMsg]
            , testCase "throws when scripted result is Left" do
                result <-
                    runScripted [Left (toException boom)]
                        $ try @ErrorCall
                        $ Session.with def Pub.publish cmd (ProjectRoot (Path.absolute @"/")) \_ controls -> controls.reload
                result @?= Left boom
            ]
        ]
    , testGroup
        "sequencing"
        [ testCase "consumes results in order across mixed operations" do
            (a, b) <- runScripted [simpleResult [errMsg], simpleResult [warnMsg]] do
                Session.with def Pub.publish cmd (ProjectRoot (Path.absolute @"/")) \LoadResult {diagnostics = a} controls -> do
                    LoadResult {diagnostics = b} <- controls.reload
                    pure (a, b)
            a @?= [errMsg]
            b @?= [warnMsg]
        , testCase "recover scenario: error then success" do
            result <- runScripted [Left (toException boom), simpleResult []] do
                r1 <- try @ErrorCall $ Session.with def Pub.publish cmd (ProjectRoot (Path.absolute @"/")) \i _ -> pure i
                LoadResult {diagnostics = r2} <- Session.with def Pub.publish cmd (ProjectRoot (Path.absolute @"/")) \i _ -> pure i
                pure (r1, r2)
            assertBool "expected Left" $ isLeft (fst result)
            snd result @?= []
        ]
    ]


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

cmd :: RenderedCommand 'Build
cmd = RenderedCommand "cabal repl lib:foo"


boom :: ErrorCall
boom = ErrorCall "simulated GHCi crash"


errMsg :: Diagnostic
errMsg =
    Diagnostic
        { severity = Build.Severity.Error
        , file = Location (Path.Relative (Path.rel @"src/Foo.hs"))
        , line = 1
        , col = 1
        , endLine = 1
        , endCol = 5
        , title = "Variable not in scope: foo"
        , text = "Variable not in scope: foo"
        }


warnMsg :: Diagnostic
warnMsg =
    Diagnostic
        { severity = Build.Severity.Warning
        , file = Location (Path.Relative (Path.rel @"src/Bar.hs"))
        , line = 10
        , col = 3
        , endLine = 10
        , endCol = 8
        , title = "Unused import"
        , text = "Unused import"
        }


-- | Convenience constructor: a scripted result with no compiled-file info.
simpleResult :: [Diagnostic] -> Either SomeException LoadResult
simpleResult msgs =
    Right
        LoadResult
            { moduleCount = 0
            , compiledFiles = Set.empty
            , loadedModules = Map.empty
            , targetNames = []
            , diagnostics = msgs
            }


runScripted
    :: [Either SomeException LoadResult]
    -> Eff '[Session, Pub Progress, IOE] a
    -> IO a
runScripted results = runEff . Pub.noOp . Session.runScripted results
