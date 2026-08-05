module Tricorder.Session.Command
    ( Command (..)
    , resolveCommand
    ) where

import Atelier.Effects.FileSystem (FileSystem, doesFileExist, listDirectory)
import Data.Aeson (FromJSON (..), ToJSON (..))
import Data.Default (Default (..))
import System.FilePath (takeExtension, (</>))

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Target (Target, renderTarget)
import Tricorder.Session.TestTarget (TestTarget, renderTestTarget)


newtype Command = Command {getCommand :: Text}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Text


instance Default Command where
    def = Command ""


-- | Resolve the GHCi command, using config if set or autodetecting otherwise.
--
-- The @testTargets@ are the discovered @test:@ components; they are appended to
-- the auto-detected @all@ target (see 'detectCommand'). They are ignored when
-- the user has pinned an explicit @command@ or explicit @targets@ in config.
resolveCommand :: (FileSystem :> es) => ProjectRoot -> Config -> [Target] -> [TestTarget] -> Eff es Command
resolveCommand projectRoot cfg targets testTargets =
    case cfg.command of
        Just cmd -> pure $ Command cmd
        Nothing -> detectCommand targets testTargets cfg.replBuildDir projectRoot


-- | Build the autodetected GHCi command.
--
-- Configured @targets@ are spelled out verbatim. Otherwise we use cabal's
-- catch-all @all@ plus the discovered @test:@ targets, because
-- @cabal repl --enable-multi-repl all@ omits test suites unless the project sets
-- @tests: True@ in @cabal.project@ — so test errors would go unnoticed.
--
-- We keep @all@ rather than enumerating every component: @all@ lets cabal order
-- the multi-repl units, and GHCi makes the /last/ unit the active one. If that
-- unit imports a custom @Prelude@ from a sibling home package, GHCi reports it
-- "not loaded" and the session dies — which a naive discovery-order enumeration
-- triggers but @all@ avoids. Appending already-included test targets is a no-op
-- (cabal deduplicates).
detectCommand :: (FileSystem :> es) => [Target] -> [TestTarget] -> FilePath -> ProjectRoot -> Eff es Command
detectCommand targets testTargets replBuildDir (ProjectRoot projectRoot) = do
    hasCabalProject <- doesFileExist (projectRoot </> "cabal.project")
    cabalFiles <- filter (\f -> takeExtension f == ".cabal") <$> listDirectory projectRoot
    hasStack <- doesFileExist (projectRoot </> "stack.yaml")
    let targetStr
            | not (null targets) = unwords (map renderTarget targets)
            | otherwise = unwords ("all" : map renderTestTarget testTargets)
        buildDirFlag = "--builddir " <> toText replBuildDir <> " "
    pure
        if
            | hasCabalProject || not (null cabalFiles) ->
                Command $ "cabal repl --enable-multi-repl " <> buildDirFlag <> targetStr
            | hasStack -> Command $ "stack ghci " <> targetStr
            | otherwise -> Command $ "cabal repl " <> buildDirFlag <> targetStr
