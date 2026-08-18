module Tricorder.Session.Command
    ( Command (..)
    , Repl (..)
    , render
    , resolveCommand
    )
where

import Atelier.Effects.FileSystem (FileSystem)
import Data.Default (Default (..))
import Effectful.NonDet (NonDet, OnEmptyPolicy (..), emptyEff, plusEff, runNonDet)
import System.FilePath ((</>))

import Atelier.Effects.FileSystem qualified as FileSystem
import Data.List qualified as List

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Config (Config, command, replBuildDir)
import Tricorder.Session.Target (Target (..))
import Tricorder.Session.TestTarget (TestTarget, getTestTarget)

import Tricorder.Session.Target qualified as Target


data Command = Command
    { repl :: Repl
    , arguments :: [Text]
    , targets :: [Target]
    }
    deriving stock (Eq, Generic, Show)


data Repl = StackMulti | Stack | Cabal | Unknown
    deriving stock (Eq, Generic, Show)


render :: Command -> Text
render command = unwords $ renderRepl command.repl <> command.arguments <> tgts
  where
    tgts = case command.repl of
        Stack -> List.nub $ Target.componentName <$> command.targets
        StackMulti -> List.nub $ Target.renderTarget <$> command.targets
        Cabal -> Target.renderTarget <$> command.targets
        Unknown -> Target.renderTarget <$> command.targets


renderRepl :: Repl -> [Text]
renderRepl StackMulti = ["stack", "ghci"]
renderRepl Stack = ["stack", "ghci"]
renderRepl Cabal = ["cabal", "repl"]
renderRepl Unknown = []


instance Default Command where
    def = Command Unknown [] []


-- | Resolve the GHCi command, using config if set or autodetecting otherwise.
--
-- The @testTargets@ are the discovered @test:@ components; they are appended to
-- the auto-detected @all@ target (see 'detectCommand'). They are ignored when
-- the user has pinned an explicit @command@ or explicit @targets@ in config.
resolveCommand :: (FileSystem :> es) => ProjectRoot -> Config -> [Target] -> [TestTarget] -> Eff es Command
resolveCommand projectRoot@(ProjectRoot root) cfg targets testTargets =
    case cfg.command of
        Just cmd -> case words cmd of
            "stack" : "repl" : args -> detectStackKind args
            "stack" : "ghci" : args -> detectStackKind args
            "cabal" : "repl" : args -> pure $ Command Cabal args []
            args -> pure $ Command Unknown args []
        Nothing ->
            detectCommand targets testTargets cfg.replBuildDir projectRoot
  where
    detectStackKind args = do
        hasCabalFileInRoot <- any (".cabal" `List.isSuffixOf`) <$> FileSystem.listDirectory root
        let repl =
                if hasCabalFileInRoot then
                    Stack
                else
                    StackMulti
        pure $ Command repl args []


detectCommand :: (FileSystem :> es) => [Target] -> [TestTarget] -> FilePath -> ProjectRoot -> Eff es Command
detectCommand targets testTargets replBuildDir projectRoot = do
    cmd <-
        fmap (fromMaybe (fallback replBuildDir) . rightToMaybe)
            $ runNonDet OnEmptyKeep
            $ useStack projectRoot
                `plusEff` useMultiCabal projectRoot replBuildDir
    pure
        $ cmd
            { targets =
                if not (null targets) then
                    targets
                else
                    Bare "all" : (getTestTarget <$> testTargets)
            }


useStack :: (FileSystem :> es, NonDet :> es) => ProjectRoot -> Eff es Command
useStack (ProjectRoot projectRoot) = do
    hasStack <- FileSystem.doesFileExist $ projectRoot </> "stack.yaml"
    if hasStack then
        pure $ Command Stack [] []
    else
        emptyEff


useMultiCabal :: (FileSystem :> es, NonDet :> es) => ProjectRoot -> FilePath -> Eff es Command
useMultiCabal (ProjectRoot projectRoot) replBuildDir = do
    hasCabalProject <- FileSystem.doesFileExist $ projectRoot </> "cabal.project"
    hasCabalFiles <- any (".cabal" `List.isSuffixOf`) <$> FileSystem.listDirectory projectRoot
    if hasCabalFiles || hasCabalProject then
        pure
            $ Command
                { repl = Cabal
                , arguments = ["--enable-multi-repl"] <> buildDirFlag replBuildDir
                , targets = []
                }
    else
        emptyEff


fallback :: FilePath -> Command
fallback replBuildDir =
    Command
        { repl = Cabal
        , arguments = buildDirFlag replBuildDir
        , targets = [Bare "all"]
        }


buildDirFlag :: FilePath -> [Text]
buildDirFlag replBuildDir = ["--builddir", toText replBuildDir]
