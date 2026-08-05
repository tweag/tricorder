module Tricorder.Session
    ( Session (..)
    , Config (..)
    , Command (..)
    , parseTestTargets
    , Target (..)
    , ComponentKind (..)
    , parseTarget
    , renderTarget
    , TestTarget (..)
    , renderTestTarget
    , WatchDirs (..)
    , WatchExclusionPatterns (..)
    , ReplBuildDir (..)
    , TestTimeout (..)
    , Pattern
    , loadSession
    , inputSession
    , CabalFile (..)
    , inputCabalFiles
    , resolveCommand
    , resolveTargets
    , discoverCabalFiles
    , allComponentTargets
    , resolveTestTargets
    , resolveWatchDirs
    , sourceDirsForTarget
    , compareTargets
    , definesCustomPrelude
    ) where

import Atelier.Config (LoadedConfig, extractConfig)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, listDirectory, readFileBs)
import Atelier.Effects.Input (Input, input, runInputEff)
import Atelier.Effects.Log (Log)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Data.Aeson (FromJSON (..), FromJSONKey, ToJSON (..), ToJSONKey)
import Data.Default (Default (..))
import Data.List (nub)
import Data.Traversable (for)
import Distribution.Compat.Lens (view)
import Distribution.Fields (Field (..), FieldLine (..), Name (..), readFields)
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
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
import Distribution.Types.Library (exposedModules)
import Distribution.Types.PackageDescription (package)
import Distribution.Types.PackageId (pkgName)
import Distribution.Types.PackageName (unPackageName)
import Distribution.Types.UnqualComponentName (mkUnqualComponentName, unUnqualComponentName)
import Distribution.Utils.Path (getSymbolicPath)
import Effectful.Reader.Static (Reader, ask)
import System.FilePath (normalise, takeDirectory, takeExtension, (</>))
import Text.Regex.TDFA.ReadRegex (parseRegex)

import Atelier.Effects.Log qualified as Log
import Data.ByteString.Char8 qualified as BC
import Data.Text qualified as T
import Distribution.Types.BuildInfo.Lens qualified as Lens
import Text.Regex.TDFA.Pattern qualified as Regex

import Tricorder.Runtime (ProjectRoot (..))


data Session = Session
    { command :: Command
    , targets :: [Target]
    , testTargets :: [TestTarget]
    , watchDirs :: WatchDirs
    , watchExclusionPatterns :: WatchExclusionPatterns
    , replBuildDir :: ReplBuildDir
    , testTimeout :: TestTimeout
    }
    deriving stock (Eq)


type Pattern = (Regex.Pattern, (Regex.GroupIndex, Regex.DoPa))


instance Default Session where
    def =
        Session
            { command = Command ""
            , targets = []
            , testTargets = projectTestTargets []
            , watchDirs = WatchDirs []
            , watchExclusionPatterns = WatchExclusionPatterns []
            , replBuildDir = ReplBuildDir "/tmp"
            , testTimeout = TestTimeout 10
            }


data Config = Config
    { command :: Maybe Text
    , targets :: [Text]
    , watchDirs :: [FilePath]
    , watchExclusionPatterns :: [Text]
    , testTargets :: Maybe [Text]
    , replBuildDir :: FilePath
    , testTimeout :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via WithDefaults (QuietSnake Config)


instance Default Config where
    def =
        Config
            { command = Nothing
            , targets = []
            , watchDirs = []
            , watchExclusionPatterns = []
            , testTargets = Nothing
            , replBuildDir = "dist-newstyle/tricorder"
            , testTimeout = 10
            }


newtype Command = Command {getCommand :: Text}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Text


-- | [tag:test_targets_invariant] Project a target list onto its test suites —
-- the only way to build a 'TestTargets', so the @test:@-only invariant holds by
-- construction.
projectTestTargets :: [Target] -> [TestTarget]
projectTestTargets = mapMaybe mkTestTarget
  where
    mkTestTarget tgt@(Qualified Test _) = Just $ TestTarget tgt
    mkTestTarget _ = Nothing


-- | Parse raw target strings (e.g. the @test_targets@ config) and project them
-- onto their test suites — non-test entries are dropped.
parseTestTargets :: [Text] -> [TestTarget]
parseTestTargets = projectTestTargets . map parseTarget


-- | A cabal build target, parsed from its textual @[kind:]name@ form. Used to
-- resolve which source directories belong to a target.
data Target
    = -- | A @kind:name@ reference, e.g. @lib:foo@, @exe:foo@, @test:foo@. An
      -- empty name with 'Lib' (i.e. @lib:@) denotes the package's main library.
      Qualified ComponentKind Text
    | -- | A name with no @kind:@ prefix. Refers either to a package (all of its
      -- components) or to a single component matched by name.
      Bare Text
    | -- | A form we don't recognize: an unknown kind, or extra colons.
      Unrecognized Text
    deriving stock (Eq, Generic, Ord, Show)


-- | The kind of cabal component a 'Qualified' target names. Covers every
-- component kind cabal models (matching @Distribution.Types.ComponentName@).
data ComponentKind = Lib | FLib | Exe | Test | Bench
    deriving stock (Bounded, Enum, Eq, Generic, Ord, Show)


-- | [tag:kind_prefix_sole_source] The canonical prefix cabal uses for each
-- component kind. Single source of truth shared by 'parseTarget' and
-- 'renderTarget' — keep this the only place the prefix strings appear.
--
-- We deliberately model only these canonical prefixes, not cabal's full set of
-- aliases (@executable@, @test-suite@, …) or its case-folding. Those would mean
-- hand-mirroring an unexported, internally-inconsistent cabal table; instead an
-- aliased spelling falls to 'Unrecognized', which is still handed to cabal
-- verbatim for the build and still resolves watch dirs by matching its trailing
-- component name [ref:alias_name_match].
kindPrefix :: ComponentKind -> Text
kindPrefix = \case
    Lib -> "lib"
    FLib -> "flib"
    Exe -> "exe"
    Test -> "test"
    Bench -> "bench"


-- | Parse a kind prefix, derived as the inverse of 'kindPrefix' so the two
-- never drift apart [ref:kind_prefix_sole_source].
parseKind :: Text -> Maybe ComponentKind
parseKind = inverseMap kindPrefix


-- | Classify a target's textual form. The grammar is @[kind:]name@ where
-- @kind@ is one of @lib@, @flib@, @exe@, @test@, or @bench@; anything else (an
-- unknown kind, a cabal alias such as @executable@, or extra colons) is
-- 'Unrecognized'.
parseTarget :: Text -> Target
parseTarget target = case T.splitOn ":" target of
    [prefix, name] | Just kind <- parseKind prefix -> Qualified kind name
    [name] -> Bare name
    _ -> Unrecognized target


-- | Render a 'Target' back to the textual form cabal understands. Inverse of
-- 'parseTarget' (lossless: @parseTarget . renderTarget == id@). Builds prefixes
-- via 'kindPrefix' rather than hardcoding them [ref:kind_prefix_sole_source].
renderTarget :: Target -> Text
renderTarget = \case
    Qualified kind name -> kindPrefix kind <> ":" <> name
    Bare name -> name
    Unrecognized raw -> raw


instance ToJSON Target where
    toJSON = toJSON . renderTarget


instance FromJSON Target where
    parseJSON = fmap parseTarget . parseJSON


instance ToJSONKey Target
instance FromJSONKey Target


newtype TestTarget = TestTarget {getTestTarget :: Target}
    deriving stock (Eq, Generic, Ord, Show)
    deriving (FromJSON, ToJSON) via Target
    deriving (FromJSONKey, ToJSONKey) via Target


renderTestTarget :: TestTarget -> Text
renderTestTarget = renderTarget . getTestTarget


newtype WatchDirs = WatchDirs {getWatchDirs :: [FilePath]}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via [FilePath]


newtype WatchExclusionPatterns = WatchExclusionPatterns {getWatchExclusionPatterns :: [Pattern]}
    deriving stock (Eq, Generic, Show)


newtype ReplBuildDir = ReplBuildDir {getReplBuildDir :: FilePath}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via FilePath


newtype TestTimeout = TestTimeout {getTestTimeout :: Int}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Int


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


-- | Resolve the directories to watch.
--
-- Priority:
-- 1. @watch_dirs@ from config, if non-empty (used as-is relative to project root)
-- 2. @hs-source-dirs@ inferred from cabal targets, if targets are set
-- 3. Falls back to @["."]@ (project root) if neither is available
resolveWatchDirs :: ProjectRoot -> [CabalFile] -> Config -> [Target] -> WatchDirs
resolveWatchDirs projectRoot projectFiles cfg targets =
    case cfg.watchDirs of
        dirs@(_ : _) -> WatchDirs $ map (coerce projectRoot </>) dirs
        [] -> resolveWatchDirsFromTargets projectFiles targets


resolveWatchDirsFromTargets :: [CabalFile] -> [Target] -> WatchDirs
resolveWatchDirsFromTargets _ [] = WatchDirs ["."]
resolveWatchDirsFromTargets projectFiles targets =
    WatchDirs $ case dirs of
        [] -> ["."]
        _ -> dirs
  where
    dirs = nub . concat $ watchDirsForCabal <$> projectFiles
    -- @hs-source-dirs@ are relative to the package's own directory, so scope
    -- them to the directory holding that package's @.cabal@. In a
    -- single-package project that directory is the project root; in a
    -- multi-package project it's the per-package subdirectory. Targets that
    -- don't belong to this package yield no dirs.
    watchDirsForCabal projectFile =
        let pkgDir = takeDirectory projectFile.projectFilePath
            sourceDirs = sourceDirsForTarget projectFile.projectPackageDescription
        in  (pkgDir </>) <$> concatMap sourceDirs targets


sourceDirsForTarget :: GenericPackageDescription -> Target -> [FilePath]
sourceDirsForTarget gpd target =
    map getSymbolicPath $ case target of
        Qualified Lib "" -> mainLibSourceDirs
        Qualified Lib name
            | toString name == mainPkgName -> mainLibSourceDirs
            | otherwise -> subLibSourceDirs name
        Qualified FLib name -> flibSourceDirs name
        Qualified Exe name -> exeSourceDirs name
        Qualified Test name -> testSourceDirs name
        Qualified Bench name -> benchSourceDirs name
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


-- | Infer the effective targets to build and watch. This is the boundary where
-- raw target strings (from config) are parsed into structured 'Target's: the
-- configured targets are parsed as-is, or all components across every
-- discovered package are auto-detected when no targets are configured. Either
-- way the result is sorted with 'compareTargets' so libraries exposing a custom
-- @Prelude@ come last [ref:lib_sort_order].
resolveTargets :: [CabalFile] -> [Text] -> [Target]
resolveTargets cabalFiles targets@(_ : _) =
    sortBy (compareTargets (definesCustomPrelude cabalFiles)) $ parseTarget <$> targets
resolveTargets cabalFiles [] =
    sortBy (compareTargets (definesCustomPrelude cabalFiles))
        $ foldMap (allComponentTargets . (.projectPackageDescription)) cabalFiles


-- | [tag:lib_sort_order] When running @cabal repl <package defining custom
-- prelude> <other packages...>@, GHCi fails because it attempts to load the
-- provided @Prelude@ module before loading the package itself. This is not a
-- problem if the package defining the prelude module is not the first component
-- listed.
--
-- We check each library target against the discovered cabal files via
-- 'definesCustomPrelude': only those that expose a @Prelude@ module are sorted
-- last. This is more precise than sorting every @lib:@ target last — only the
-- libraries that actually cause the failure are reordered.
compareTargets :: (Target -> Bool) -> Target -> Target -> Ordering
compareTargets definesPrelude a b
    | definesPrelude a && not (definesPrelude b) = GT
    | not (definesPrelude a) && definesPrelude b = LT
    | otherwise = compare (renderTarget a) (renderTarget b)


-- | Check whether any of the discovered packages' libraries expose a @Prelude@
-- module for the given target. Used to build the predicate passed to
-- 'compareTargets' so that only the libraries that actually cause the GHCi
-- startup failure are sorted last [ref:lib_sort_order].
definesCustomPrelude :: [CabalFile] -> Target -> Bool
definesCustomPrelude cabalFiles target = any check cabalFiles
  where
    check cabalFile = any hasPrelude $ relevantLibs cabalFile.projectPackageDescription
    hasPrelude lib = "Prelude" `elem` exposedModules lib
    relevantLibs gpd =
        let pkgN = unPackageName gpd.packageDescription.package.pkgName
        in  case target of
                Qualified Lib "" ->
                    toList $ condTreeData <$> condLibrary gpd
                Qualified Lib name
                    | toString name == pkgN ->
                        toList $ condTreeData <$> condLibrary gpd
                    | otherwise ->
                        subLibsNamed gpd (toString name)
                Bare name
                    | toString name == pkgN ->
                        toList (condTreeData <$> condLibrary gpd)
                            <> (condTreeData . snd <$> condSubLibraries gpd)
                    | otherwise ->
                        subLibsNamed gpd (toString name)
                _ -> []
    subLibsNamed gpd name =
        map (condTreeData . snd)
            $ filter ((== mkUnqualComponentName name) . fst)
            $ condSubLibraries gpd


-- | Locate every package's @.cabal@ file, logging what drove the result. In a
-- multi-package project the packages live in subdirectories listed under
-- @packages:@ in @cabal.project@; in a single-package project the @.cabal@
-- file(s) sit in the root. Called once per session load; the result is shared
-- by target and watch-dir resolution.
discoverCabalFiles :: (FileSystem :> es, Log :> es) => ProjectRoot -> Eff es [FilePath]
discoverCabalFiles (ProjectRoot projectRoot) = do
    hasProject <- doesFileExist projectFile
    cabalFiles <-
        if hasProject then do
            contents <- readFileBs projectFile
            concat <$> traverse cabalFilesForEntry (projectPackageEntries contents)
        else
            cabalFilesIn projectRoot
    let listed
            | null cabalFiles = "none"
            | otherwise = T.intercalate ", " (map toText cabalFiles)
    if hasProject then
        Log.debug
            $ "Found cabal.project; discovered "
                <> show (length cabalFiles)
                <> " package cabal file(s): "
                <> listed
    else
        Log.debug $ "No cabal.project; using cabal file(s) in project root: " <> listed
    pure cabalFiles
  where
    projectFile = projectRoot </> "cabal.project"

    -- A @packages:@ entry is either a direct path to a @.cabal@ file or a
    -- directory to search for one.
    cabalFilesForEntry entry
        | takeExtension entry == ".cabal" = pure [projectRoot </> entry]
        | otherwise = cabalFilesIn (normalise (projectRoot </> entry))


-- | List the @.cabal@ files directly inside a directory.
cabalFilesIn :: (FileSystem :> es) => FilePath -> Eff es [FilePath]
cabalFilesIn dir = do
    entries <- filter (\f -> takeExtension f == ".cabal") <$> listDirectory dir
    pure $ map (dir </>) entries


-- | Extract the directory/file entries from the @packages:@ field of a
-- @cabal.project@. Glob entries (containing @*@) are not expanded and are
-- skipped.
projectPackageEntries :: ByteString -> [FilePath]
projectPackageEntries contents =
    case readFields contents of
        Left _ -> []
        Right fields -> filter (notElem '*') $ concatMap fromField fields
  where
    fromField (Field (Name _ name) fieldLines)
        | name == "packages" = concatMap fromLine fieldLines
    fromField _ = []
    fromLine (FieldLine _ bs) = map BC.unpack (BC.words bs)


allComponentTargets :: GenericPackageDescription -> [Target]
allComponentTargets gpd =
    mainLibTargets
        ++ subLibTargets
        ++ flibTargets
        ++ exeTargets
        ++ testTargets
        ++ benchTargets
  where
    mainPkgName = toText $ unPackageName . pkgName . package . packageDescription $ gpd
    mainLibTargets = maybe [] (const [Qualified Lib mainPkgName]) (condLibrary gpd)
    subLibTargets = map (\(n, _) -> Qualified Lib (componentName n)) (condSubLibraries gpd)
    flibTargets = map (\(n, _) -> Qualified FLib (componentName n)) (condForeignLibs gpd)
    exeTargets = map (\(n, _) -> Qualified Exe (componentName n)) (condExecutables gpd)
    testTargets = map (\(n, _) -> Qualified Test (componentName n)) (condTestSuites gpd)
    benchTargets = map (\(n, _) -> Qualified Bench (componentName n)) (condBenchmarks gpd)
    componentName = toText . unUnqualComponentName


-- | Resolve which test suites to run after a clean build. Either source — the
-- explicit @test_targets@ config or the build 'targets' — is projected onto its
-- @test:@ components (see 'projectTestTargets'), so non-test entries are
-- dropped and the result only ever names test suites [ref:test_targets_invariant].
resolveTestTargets :: Config -> [Target] -> [TestTarget]
resolveTestTargets cfg targets = case cfg.testTargets of
    Just explicit -> parseTestTargets explicit
    Nothing -> projectTestTargets targets


resolveWatchExclusionPatterns :: [Text] -> Either Text WatchExclusionPatterns
resolveWatchExclusionPatterns rawPatterns = do
    bimap show WatchExclusionPatterns
        $ traverse (parseRegex . toString) rawPatterns


data CabalFile = CabalFile
    { projectFilePath :: FilePath
    , projectPackageDescription :: GenericPackageDescription
    }
    deriving stock (Show)


inputCabalFiles
    :: ( FileSystem :> es
       , Log :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Input [CabalFile] : es) a -> Eff es a
inputCabalFiles = runInputEff do
    projectRoot <- ask
    projectFilePaths <- discoverCabalFiles projectRoot
    (faileds, packageDescriptions) <-
        partitionEithers <$> for projectFilePaths \p -> do
            contents <- readFileBs p
            case parseGenericPackageDescriptionMaybe contents of
                Nothing -> pure $ Left p
                Just gpd -> pure $ Right $ CabalFile p gpd
    unless (null faileds) do
        Log.warn
            $ "Failed to parse .cabal files for the following packages: "
                <> T.intercalate ", " (toText <$> faileds)
    pure $ packageDescriptions


loadSession
    :: ( FileSystem :> es
       , Input LoadedConfig :> es
       , Input [CabalFile] :> es
       , Log :> es
       , Reader ProjectRoot :> es
       )
    => Eff es Session
loadSession = do
    projectRoot <- ask @ProjectRoot
    loadedCfg <- input
    projectFiles <- input

    let cfgFile = extractConfig @"session" @Config loadedCfg
        effectiveTargets = resolveTargets projectFiles cfgFile.targets
        testTargets = resolveTestTargets cfgFile effectiveTargets
        watchDirs = resolveWatchDirs projectRoot projectFiles cfgFile effectiveTargets

    watchExclusionPatterns <-
        case resolveWatchExclusionPatterns cfgFile.watchExclusionPatterns of
            Left err -> do
                Log.err
                    $ T.intercalate
                        "\n"
                        [ "Failed to parse watch exclusion patterns:"
                        , err
                        , "Defaulting to no exclusion patterns."
                        ]
                pure $ WatchExclusionPatterns []
            Right pts -> pure pts

    when (not (null effectiveTargets) && all (definesCustomPrelude projectFiles) effectiveTargets)
        $ Log.warn
            "Every resolved target exposes a custom Prelude module. GHCi may \
            \fail to start because the first target's Prelude will be loaded \
            \before its package is ready. Consider adding a target that does \
            \not define its own Prelude, or set an explicit command in your \
            \tricorder configuration."

    command <- resolveCommand projectRoot cfgFile effectiveTargets testTargets

    pure
        $ Session
            { targets = effectiveTargets
            , command
            , watchDirs
            , watchExclusionPatterns
            , testTargets
            , replBuildDir = ReplBuildDir cfgFile.replBuildDir
            , testTimeout = TestTimeout cfgFile.testTimeout
            }


inputSession
    :: ( FileSystem :> es
       , Input LoadedConfig :> es
       , Input [CabalFile] :> es
       , Log :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Input Session : es) a -> Eff es a
inputSession = runInputEff loadSession
