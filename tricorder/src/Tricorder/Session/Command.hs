module Tricorder.Session.Command
    ( Command (..)
    , Repl (..)
    , render
    , resolveCommand
    ) where

import Atelier.Effects.FileSystem (FileSystem)
import Data.Default (Default (..))
import Effectful.NonDet (NonDet, OnEmptyPolicy (..), emptyEff, plusEff, runNonDet)
import GHC.Records (HasField (..))
import System.FilePath ((</>))

import Atelier.Effects.FileSystem qualified as FileSystem
import Data.List qualified as List

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Target (Target, renderTarget)
import Tricorder.Session.TestTarget (TestTarget, renderTestTarget)


data Command = Command Repl [Text]
    deriving stock (Eq, Generic, Show)


instance HasField "repl" Command Repl where
    getField (Command r _) = r


instance HasField "arguments" Command [Text] where
    getField (Command _ args) = args


appendArgs :: [Text] -> Command -> Command
appendArgs args (Command r oldArgs) = Command r $ oldArgs <> args


data Repl = Stack | Cabal | Unknown
    deriving stock (Eq, Generic, Show)


render :: Command -> Text
render (Command r args) = unwords $ renderRepl r <> args


renderRepl :: Repl -> [Text]
renderRepl Stack = ["stack", "ghci"]
renderRepl Cabal = ["cabal", "repl"]
renderRepl Unknown = []


instance Default Command where
    def = Command Unknown []


-- | Resolve the GHCi command, using config if set or autodetecting otherwise.
--
-- The @testTargets@ are the discovered @test:@ components; they are appended to
-- the auto-detected @all@ target (see 'detectCommand'). They are ignored when
-- the user has pinned an explicit @command@ or explicit @targets@ in config.
resolveCommand :: (FileSystem :> es) => ProjectRoot -> Config -> [Target] -> [TestTarget] -> Eff es Command
resolveCommand projectRoot cfg targets testTargets =
    case cfg.command of
        Just cmd -> case words cmd of
            "stack" : "repl" : args -> pure $ Command Stack args
            "stack" : "ghci" : args -> pure $ Command Stack args
            "cabal" : "repl" : args -> pure $ Command Cabal args
            args -> pure $ Command Unknown args
        Nothing -> detectCommand targets testTargets cfg.replBuildDir projectRoot


detectCommand :: (FileSystem :> es) => [Target] -> [TestTarget] -> FilePath -> ProjectRoot -> Eff es Command
detectCommand targets testTargets replBuildDir projectRoot = do
    cmd <-
        fmap (fromMaybe (fallback replBuildDir) . rightToMaybe)
            $ runNonDet OnEmptyKeep
            $ useStack projectRoot
                `plusEff` useMultiCabal projectRoot replBuildDir
    pure $ appendArgs targetArgs cmd
  where
    targetArgs
        | not (null targets) = map renderTarget targets
        | otherwise = "all" : map renderTestTarget testTargets


useStack :: (FileSystem :> es, NonDet :> es) => ProjectRoot -> Eff es Command
useStack (ProjectRoot projectRoot) = do
    hasStack <- FileSystem.doesFileExist $ projectRoot </> "stack.yaml"
    if hasStack then
        pure $ Command Stack []
    else
        emptyEff


useMultiCabal :: (FileSystem :> es, NonDet :> es) => ProjectRoot -> FilePath -> Eff es Command
useMultiCabal (ProjectRoot projectRoot) replBuildDir = do
    hasCabalProject <- FileSystem.doesFileExist $ projectRoot </> "cabal.project"
    hasCabalFiles <- any (".cabal" `List.isSuffixOf`) <$> FileSystem.listDirectory projectRoot
    if hasCabalFiles || hasCabalProject then
        pure $ Command Cabal $ ["--enable-multi-repl"] <> buildDirFlag replBuildDir
    else
        emptyEff


fallback :: FilePath -> Command
fallback replBuildDir = Command Cabal $ buildDirFlag replBuildDir


buildDirFlag :: FilePath -> [Text]
buildDirFlag replBuildDir = ["--builddir", toText replBuildDir]
