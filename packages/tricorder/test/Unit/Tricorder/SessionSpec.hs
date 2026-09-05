module Unit.Tricorder.SessionSpec (spec_Session) where

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
import Test.Hspec

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..), loadSession)
import Tricorder.Session.CabalFile (CabalFile (..))
import Tricorder.Session.IdleTimeout (IdleTimeout (..))
import Unit.Tricorder.Session.Helpers (libWithPreludeCabal, preludeOnlyLibCabal)


spec_Session :: Spec
spec_Session = do
    describe "loadSession" testLoadSession
    describe "loadSession idleTimeout" testIdleTimeout


testLoadSession :: Spec
testLoadSession = do
    describe "when every resolved target exposes a custom Prelude module" do
        it "emits a WARN" do
            let msgs = captureSessionLogs [preludeOnlyCF]
            any (\m -> m.severity == WARN) msgs `shouldBe` True

    describe "when not every resolved target exposes a custom Prelude module" do
        it "does not emit a WARN" do
            -- libWithPreludeCabal has both a lib (custom Prelude) and an exe (no Prelude)
            let msgs = captureSessionLogs [mixedCF]
            any (\m -> m.severity == WARN) msgs `shouldBe` False

    it "does not emit a WARN when there are no resolved targets" do
        any (\m -> m.severity == WARN) (captureSessionLogs []) `shouldBe` False
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


testIdleTimeout :: Spec
testIdleTimeout = do
    it "defaults to 300 seconds when unset" do
        (loadSessionWith (LoadedConfig Null)).idleTimeout `shouldBe` IdleTimeout 300

    it "reads idle_timeout_seconds from the session config" do
        let cfg = LoadedConfig $ object ["session" .= object ["idle_timeout_seconds" .= (5 :: Int)]]
        (loadSessionWith cfg).idleTimeout `shouldBe` IdleTimeout 5
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
