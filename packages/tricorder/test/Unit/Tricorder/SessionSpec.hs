module Unit.Tricorder.SessionSpec (test_Session) where

import Atelier.Effects.Log (Message (..), Severity (..))
import Data.Aeson (object, (.=))
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Effectful.Reader.Static (runReader)
import Effectful.Writer.Static.Shared (execWriter)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertFailure, testCase, (@?), (@?=))

import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log qualified as Log
import Atelier.FileSystem.Path qualified as Path
import Data.Aeson qualified as Aeson
import Data.Text qualified as T

import Tricorder.Config.LoadedConfig (LoadedConfig (..))
import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.CabalFile (CabalFile (..))
import Tricorder.Session.IdleTimeout (IdleTimeout (..))
import Unit.Tricorder.Session.Helpers (libWithPreludeCabal, preludeOnlyLibCabal, withProjectFiles)

import Tricorder.Config qualified
import Tricorder.Session qualified as Session


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
        "load"
        [ testGroup
            "when every resolved target exposes a custom Prelude module"
            [ testCase "logs one message" do
                msgs <- captureSessionLogs [preludeOnlyCF]
                length msgs @?= 1
            , testCase "emits a WARN" do
                msgs <- fmap (\m -> (m.severity, m.text)) <$> captureSessionLogs [preludeOnlyCF]
                case msgs of
                    [(sev, msg)] -> do
                        sev @?= WARN
                        "Every resolved target exposes a custom Prelude module" `T.isPrefixOf` msg
                            @? "does not start with expected string"
                    xs ->
                        assertFailure $ "Too many logged messages: " <> show (length xs)
            ]
        , testGroup
            "when not every resolved target exposes a custom Prelude module"
            [ testCase "does not emit a WARN" do
                -- libWithPreludeCabal has both a lib (custom Prelude) and an exe (no Prelude)
                msgs <- captureSessionLogs [mixedCF]
                any (\m -> m.severity == WARN) msgs @?= False
            ]
        , testCase "does not emit a WARN when there are no resolved targets" do
            msgs <- captureSessionLogs []
            any (\m -> m.severity == WARN) msgs @?= False
        ]
  where
    preludeOnlyCF =
        CabalFile (Path.absolute @"/p.cabal")
            $ fromMaybe (error "preludeOnlyLibCabal failed to parse")
            $ parseGenericPackageDescriptionMaybe (preludeOnlyLibCabal "p")
    mixedCF =
        CabalFile (Path.absolute @"/mixed.cabal")
            $ fromMaybe (error "libWithPreludeCabal failed to parse")
            $ parseGenericPackageDescriptionMaybe (libWithPreludeCabal "mixed")
    captureSessionLogs = captureSessionLogs' $ Aeson.Object mempty
    captureSessionLogs' cfg cabalFiles =
        withProjectFiles mempty \root ->
            fmap (filter (\m -> m.severity /= DEBUG))
                . execWriter @[Message]
                . Log.runWriter
                . Input.withConst cabalFiles
                . runReader (ProjectRoot root)
                . Input.withConst (LoadedConfig $ toStrict $ Aeson.encode cfg)
                . Tricorder.Config.asInput
                $ Session.load


testMissingTargetPlaceholder :: TestTree
testMissingTargetPlaceholder =
    testGroup
        "loadSession missing {target} placeholder"
        [ testGroup
            "test.command_template"
            [ testCase "emits a WARN when it has no {target} placeholder" do
                let cfg = sessionCfg ["test" .= object ["command_template" .= ("cabal repl test:foo" :: Text)]]
                logs <- captureLogsFor cfg
                any (\m -> m.severity == WARN) logs @?= True
            , testCase "does not emit a WARN when it has the {target} placeholder" do
                let cfg = sessionCfg ["test" .= object ["command_template" .= ("cabal repl {target}" :: Text)]]
                logs <- captureLogsFor cfg
                any (\m -> m.severity == WARN) logs @?= False
            ]
        , testGroup
            "eval.command_template"
            [ testCase "emits a WARN when it has no {target} placeholder" do
                let cfg = sessionCfg ["eval" .= object ["command_template" .= ("cabal repl Tricorder.Foo" :: Text)]]
                logs <- captureLogsFor cfg
                any (\m -> m.severity == WARN) logs @?= True
            , testCase "does not emit a WARN when it has the {target} placeholder" do
                let cfg = sessionCfg ["eval" .= object ["command_template" .= ("cabal repl {target}" :: Text)]]
                logs <- captureLogsFor cfg
                any (\m -> m.severity == WARN) logs @?= False
            ]
        , testGroup
            "build.command_template"
            [ testCase "does not emit a WARN when it has no {targets} placeholder" do
                let cfg = sessionCfg ["build" .= object ["command_template" .= ("cabal repl lib:foo" :: Text)]]
                logs <- captureLogsFor cfg
                any (\m -> m.severity == WARN) logs @?= False
            ]
        ]
  where
    sessionCfg session = object ["session" .= object session]
    captureLogsFor cfg =
        withProjectFiles mempty \root ->
            execWriter @[Message]
                . Log.runWriter
                . Input.withConst ([] :: [CabalFile])
                . runReader (ProjectRoot root)
                . Input.withConst (LoadedConfig $ toStrict $ Aeson.encode cfg)
                . Tricorder.Config.asInput
                $ Session.load


testIdleTimeout :: TestTree
testIdleTimeout =
    testGroup
        "loadSession idleTimeout"
        [ testCase "defaults to 300 seconds when unset" do
            loaded <- loadSessionWith (Aeson.Object mempty)
            (.idleTimeout) <$> loaded @?= Right (IdleTimeout 300)
        , testCase "reads idle_timeout_seconds from the session config" do
            let cfg = object ["session" .= object ["idle_timeout_seconds" .= (5 :: Int)]]
            loaded <- loadSessionWith cfg
            (.idleTimeout) <$> loaded @?= Right (IdleTimeout 5)
        ]
  where
    loadSessionWith cfg =
        withProjectFiles mempty \root ->
            Log.runNoOp
                . Input.withConst ([] :: [CabalFile])
                . runReader (ProjectRoot root)
                . Input.withConst (LoadedConfig $ toStrict $ Aeson.encode cfg)
                . Tricorder.Config.asInput
                $ Session.load
