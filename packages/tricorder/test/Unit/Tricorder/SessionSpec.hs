module Unit.Tricorder.SessionSpec (test_Session) where

import Atelier.Config (LoadedConfig (..))
import Atelier.Effects.FileSystem (runFileSystemState)
import Atelier.Effects.Input (runInputConst)
import Atelier.Effects.Log (Message (..), Severity (..), runLogNoOp, runLogWriter)
import Data.Aeson (Value (Null), object, (.=))
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Effectful (runPureEff)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState)
import Effectful.Writer.Static.Shared (execWriter)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..), loadSession)
import Tricorder.Session.CabalFile (CabalFile (..))
import Tricorder.Session.IdleTimeout (IdleTimeout (..))
import Unit.Tricorder.Session.Helpers (libWithPreludeCabal, preludeOnlyLibCabal)


test_Session :: TestTree
test_Session =
    testGroup
        "Session"
        [ testLoadSession
        , testIdleTimeout
        , testMissingTargetPlaceholder
        ]


testLoadSession :: TestTree
testLoadSession =
    testGroup
        "loadSession"
        [ testGroup
            "when every resolved target exposes a custom Prelude module"
            [ testCase "emits a WARN" do
                let msgs = captureSessionLogs [preludeOnlyCF]
                any (\m -> m.severity == WARN) msgs @?= True
            ]
        , testGroup
            "when not every resolved target exposes a custom Prelude module"
            [ testCase "does not emit a WARN" do
                -- libWithPreludeCabal has both a lib (custom Prelude) and an exe (no Prelude)
                let msgs = captureSessionLogs [mixedCF]
                any (\m -> m.severity == WARN) msgs @?= False
            ]
        , testCase "does not emit a WARN when there are no resolved targets" do
            any (\m -> m.severity == WARN) (captureSessionLogs []) @?= False
        ]
  where
    preludeOnlyCF =
        CabalFile "/p.cabal"
            $ fromMaybe (error "preludeOnlyLibCabal failed to parse")
            $ parseGenericPackageDescriptionMaybe (preludeOnlyLibCabal "p")
    mixedCF =
        CabalFile "/mixed.cabal"
            $ fromMaybe (error "libWithPreludeCabal failed to parse")
            $ parseGenericPackageDescriptionMaybe (libWithPreludeCabal "mixed")
    captureSessionLogs cabalFiles =
        runPureEff
            . execWriter @[Message]
            . runLogWriter
            . evalState @(Map FilePath ByteString) mempty
            . runFileSystemState
            . runInputConst cabalFiles
            . runReader (ProjectRoot "/")
            . runInputConst (LoadedConfig Null)
            $ loadSession


testMissingTargetPlaceholder :: TestTree
testMissingTargetPlaceholder =
    testGroup
        "loadSession missing {target} placeholder"
        [ testGroup
            "test.command_template"
            [ testCase "emits a WARN when it has no {target} placeholder" do
                let cfg = sessionCfg ["test" .= object ["command_template" .= ("cabal repl test:foo" :: Text)]]
                any (\m -> m.severity == WARN) (captureLogsFor cfg) @?= True
            , testCase "does not emit a WARN when it has the {target} placeholder" do
                let cfg = sessionCfg ["test" .= object ["command_template" .= ("cabal repl {target}" :: Text)]]
                any (\m -> m.severity == WARN) (captureLogsFor cfg) @?= False
            ]
        , testGroup
            "eval.command_template"
            [ testCase "emits a WARN when it has no {target} placeholder" do
                let cfg = sessionCfg ["eval" .= object ["command_template" .= ("cabal repl Tricorder.Foo" :: Text)]]
                any (\m -> m.severity == WARN) (captureLogsFor cfg) @?= True
            , testCase "does not emit a WARN when it has the {target} placeholder" do
                let cfg = sessionCfg ["eval" .= object ["command_template" .= ("cabal repl {target}" :: Text)]]
                any (\m -> m.severity == WARN) (captureLogsFor cfg) @?= False
            ]
        , testGroup
            "build.command_template"
            [ testCase "does not emit a WARN when it has no {targets} placeholder" do
                let cfg = sessionCfg ["build" .= object ["command_template" .= ("cabal repl lib:foo" :: Text)]]
                any (\m -> m.severity == WARN) (captureLogsFor cfg) @?= False
            ]
        ]
  where
    sessionCfg session = LoadedConfig $ object ["session" .= object session]
    captureLogsFor cfg =
        runPureEff
            . execWriter @[Message]
            . runLogWriter
            . evalState @(Map FilePath ByteString) mempty
            . runFileSystemState
            . runInputConst ([] :: [CabalFile])
            . runReader (ProjectRoot "/")
            . runInputConst cfg
            $ loadSession


testIdleTimeout :: TestTree
testIdleTimeout =
    testGroup
        "loadSession idleTimeout"
        [ testCase "defaults to 300 seconds when unset" do
            (loadSessionWith (LoadedConfig Null)).idleTimeout @?= IdleTimeout 300
        , testCase "reads idle_timeout_seconds from the session config" do
            let cfg = LoadedConfig $ object ["session" .= object ["idle_timeout_seconds" .= (5 :: Int)]]
            (loadSessionWith cfg).idleTimeout @?= IdleTimeout 5
        ]
  where
    loadSessionWith cfg =
        runPureEff
            . runLogNoOp
            . evalState @(Map FilePath ByteString) mempty
            . runFileSystemState
            . runInputConst ([] :: [CabalFile])
            . runReader (ProjectRoot "/")
            . runInputConst cfg
            $ loadSession
