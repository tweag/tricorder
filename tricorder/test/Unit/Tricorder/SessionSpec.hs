module Unit.Tricorder.SessionSpec (spec_Session) where

import Atelier.Config (LoadedConfig (..))
import Atelier.Effects.FileSystem (runFileSystemState)
import Atelier.Effects.Input (runInputConst)
import Atelier.Effects.Log (Message (..), Severity (..), runLogWriter)
import Data.Aeson (Value (Null))
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Effectful (runPureEff)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState)
import Effectful.Writer.Static.Shared (execWriter)
import Test.Hspec

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (loadSession)
import Tricorder.Session.CabalFile (CabalFile (..))
import Unit.Tricorder.Session.Helpers (libWithPreludeCabal, preludeOnlyLibCabal)


spec_Session :: Spec
spec_Session = do
    describe "loadSession" testLoadSession


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
