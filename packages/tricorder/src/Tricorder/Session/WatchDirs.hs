module Tricorder.Session.WatchDirs
    ( WatchDirs (..)
    , resolve
    , sourceDirsForTarget
    , allSourceDirs
    )
where

import Atelier.FileSystem.Path ((</>))
import Data.Aeson (FromJSON (..), ToJSON (..))
import Data.Default (Default (..))
import Data.List (nub)
import Distribution.Compat.Lens (view)
import Distribution.Types.CondTree (condTreeData)
import Distribution.Types.GenericPackageDescription
    ( GenericPackageDescription
    , condBenchmarks
    , condExecutables
    , condForeignLibs
    , condLibrary
    , condSubLibraries
    , condTestSuites
    , packageDescription
    )
import Distribution.Types.PackageDescription (package)
import Distribution.Types.PackageId (pkgName)
import Distribution.Types.PackageName (unPackageName)
import Distribution.Types.UnqualComponentName (mkUnqualComponentName)
import Distribution.Utils.Path (getSymbolicPath)

import Atelier.FileSystem.Path qualified as Path
import Data.List qualified as List
import Data.Text qualified as T
import Distribution.Types.BuildInfo.Lens qualified as Lens

import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.CabalFile (CabalFile (..))
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Target (ComponentKind (..), Target (..))


newtype WatchDirs = WatchDirs {getWatchDirs :: [Path.Absolute]}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via [Path.Absolute]


instance Default WatchDirs where
    def = WatchDirs []


-- | Resolve the directories to watch.
--
-- Returns 'Left' if a configured or inferred directory is not a valid path.
--
-- Priority:
-- 1. @watch_dirs@ from config, if non-empty (relative entries are resolved
--    against the project root; absolute entries are used as-is)
-- 2. @hs-source-dirs@ inferred from cabal targets, if targets are set
-- 3. Falls back to the project root if neither is available
resolve :: ProjectRoot -> [CabalFile] -> Config -> [Target] -> Either Text WatchDirs
resolve (ProjectRoot projectRoot) projectFiles cfg targets
    | List.null cfg.watchDirs = resolveWatchDirsFromTargets projectRoot projectFiles targets
    | otherwise =
        fmap
            ( WatchDirs . fmap \case
                Path.Absolute p -> p
                Path.Relative p -> projectRoot </> p
            )
            $ traverse Path.fromFilePath cfg.watchDirs


resolveWatchDirsFromTargets :: Path.Absolute -> [CabalFile] -> [Target] -> Either Text WatchDirs
resolveWatchDirsFromTargets projectRoot _ [] = Right $ WatchDirs [projectRoot]
resolveWatchDirsFromTargets projectRoot projectFiles targets =
    case dirs of
        Left err -> Left $ "Could not resolve watch dirs from target: " <> err
        Right [] -> Right $ WatchDirs [projectRoot]
        Right ds -> Right $ WatchDirs ds
  where
    dirs = nub . concat <$> traverse watchDirsForCabal projectFiles
    -- @hs-source-dirs@ are relative to the package's own directory, so scope
    -- them to the directory holding that package's @.cabal@. In a
    -- single-package project that directory is the project root; in a
    -- multi-package project it's the per-package subdirectory. Targets that
    -- don't belong to this package yield no dirs.
    watchDirsForCabal projectFile =
        let pkgDir = Path.takeDirectory projectFile.projectFilePath
            sourceDirs = sourceDirsForTarget projectFile.projectPackageDescription
            absIfy = \case
                Path.Absolute p -> p
                Path.Relative p -> pkgDir </> p
        in  concat . fmap (fmap absIfy) <$> traverse sourceDirs targets


sourceDirsForTarget :: GenericPackageDescription -> Target -> Either Text [Path.Any]
sourceDirsForTarget gpd target =
    traverse Path.fromFilePath
        $ getSymbolicPath <$> case target of
            Qualified Lib "" -> mainLibSourceDirs
            Qualified Lib name
                | toString name == mainPkgName -> mainLibSourceDirs
                | otherwise -> subLibSourceDirs name
            Qualified FLib name -> flibSourceDirs name
            Qualified Exe name -> exeSourceDirs name
            Qualified Test name -> testSourceDirs name
            Qualified Bench name -> benchSourceDirs name
            PackageQualified _ Lib "" -> mainLibSourceDirs
            PackageQualified _ Lib name
                | toString name == mainPkgName -> mainLibSourceDirs
                | otherwise -> subLibSourceDirs name
            PackageQualified _ FLib name -> flibSourceDirs name
            PackageQualified _ Exe name -> exeSourceDirs name
            PackageQualified _ Test name -> testSourceDirs name
            PackageQualified _ Bench name -> benchSourceDirs name
            -- A bare target (no @kind:@ prefix) is a package name or a component
            -- name. A package name covers every component; otherwise match a
            -- single component by name across the kinds.
            Bare name
                | toString name == mainPkgName -> allComponentSourceDirs
                | otherwise -> componentSourceDirsByName name
            -- [tag:alias_name_match] A form we couldn't parse into a kind — a cabal
            -- alias (@executable:@) or a case variant (@Lib:@). The kind is
            -- untrustworthy, but cabal component names are unique within a package,
            -- so we match the trailing name across every kind. This recovers precise
            -- watch dirs for aliased spellings; worst case we over-match a
            -- same-named component, never miss one. (The raw string is still handed
            -- to cabal verbatim for the build.)
            Unrecognized raw -> componentSourceDirsByName (T.takeWhileEnd (/= ':') raw)
  where
    mainPkgName = unPackageName . pkgName . package . packageDescription $ gpd

    -- @hs-source-dirs@ of any component, via the @HasBuildInfo@ lens — one
    -- accessor that works uniformly across libraries, foreign libs, exes,
    -- tests, and benchmarks, so we don't repeat a per-kind @buildInfo@ getter.
    componentDirs component = view Lens.hsSourceDirs component

    mainLibSourceDirs = maybe [] (componentDirs . condTreeData) (condLibrary gpd)
    subLibSourceDirs name = dirsForComponent (condSubLibraries gpd) name
    flibSourceDirs name = dirsForComponent (condForeignLibs gpd) name
    exeSourceDirs name = dirsForComponent (condExecutables gpd) name
    testSourceDirs name = dirsForComponent (condTestSuites gpd) name
    benchSourceDirs name = dirsForComponent (condBenchmarks gpd) name

    -- Match a component name across every kind. The main library is keyed by
    -- the package name rather than an unqualified component name, so it joins
    -- in only when @name@ is the package name.
    componentSourceDirsByName name =
        mainLibForName name
            <> subLibSourceDirs name
            <> flibSourceDirs name
            <> exeSourceDirs name
            <> testSourceDirs name
            <> benchSourceDirs name

    mainLibForName name
        | toString name == mainPkgName = mainLibSourceDirs
        | otherwise = []

    allComponentSourceDirs =
        mainLibSourceDirs
            <> concatMap (componentDirs . condTreeData . snd) (condSubLibraries gpd)
            <> concatMap (componentDirs . condTreeData . snd) (condForeignLibs gpd)
            <> concatMap (componentDirs . condTreeData . snd) (condExecutables gpd)
            <> concatMap (componentDirs . condTreeData . snd) (condTestSuites gpd)
            <> concatMap (componentDirs . condTreeData . snd) (condBenchmarks gpd)

    dirsForComponent components name =
        let ucn = mkUnqualComponentName (toString name)
        in  concatMap (componentDirs . condTreeData . snd) $ filter ((== ucn) . fst) components


-- | The @hs-source-dirs@ of every component in the package, relative to the
-- package's own directory (unless absolute). 'Left' if any is not a valid path.
allSourceDirs :: GenericPackageDescription -> Either Text [Path.Any]
allSourceDirs gpd =
    fmap nub
        . sourceDirsForTarget gpd
        . Bare
        . toText
        . unPackageName
        . pkgName
        . package
        . packageDescription
        $ gpd
