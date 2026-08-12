module Tricorder.Session.Target
    ( Target (..)
    , ComponentKind (..)
    , parseTarget
    , renderTarget
    , componentName
    , resolveTargets
    , definesCustomPrelude
    , compareTargets
    , allComponentTargets
    ) where

import Data.Aeson (FromJSON (..), FromJSONKey, ToJSON (..), ToJSONKey)
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

import Data.Text qualified as T

import Tricorder.Session.CabalFile (CabalFile (..))


-- | A cabal build target, parsed from its textual @[kind:]name@ form. Used to
-- resolve which source directories belong to a target.
data Target
    = -- | A @kind:name@ reference, e.g. @lib:foo@, @exe:foo@, @test:foo@. An
      -- empty name with 'Lib' (i.e. @lib:@) denotes the package's main library.
      Qualified ComponentKind Text
    | -- | A @package:kind:name@ reference, e.g. @foo:lib:foo@, @bar:exe:foo@,
      -- @baz:test:foo@. An empty name with 'Lib' (i.e. @foo:lib:@) denotes the
      -- package's main library.
      PackageQualified Text ComponentKind Text
    | -- | A name with no @kind:@ prefix. Refers either to a package (all of its
      -- components) or to a single component matched by name.
      Bare Text
    | -- | A form we don't recognize: an unknown kind, or extra colons.
      Unrecognized Text
    deriving stock (Eq, Generic, Ord, Show)


instance ToJSON Target where
    toJSON = toJSON . renderTarget


instance FromJSON Target where
    parseJSON = fmap parseTarget . parseJSON


instance ToJSONKey Target
instance FromJSONKey Target


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
    [packageName, prefix, name] | Just kind <- parseKind prefix -> PackageQualified packageName kind name
    [prefix, name] | Just kind <- parseKind prefix -> Qualified kind name
    [name] -> Bare name
    _ -> Unrecognized target


-- | Render a 'Target' back to the textual form cabal understands. Inverse of
-- 'parseTarget' (lossless: @parseTarget . renderTarget == id@). Builds prefixes
-- via 'kindPrefix' rather than hardcoding them [ref:kind_prefix_sole_source].
renderTarget :: Target -> Text
renderTarget = \case
    Qualified kind name -> kindPrefix kind <> ":" <> name
    PackageQualified packageName kind name -> packageName <> ":" <> kindPrefix kind <> ":" <> name
    Bare name -> name
    Unrecognized raw -> raw


componentName :: Target -> Text
componentName = \case
    Qualified _ name -> name
    PackageQualified _ _ name -> name
    Bare name -> name
    Unrecognized raw -> raw


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
                PackageQualified _ Lib "" -> getMainLib gpd
                Qualified Lib "" -> getMainLib gpd
                PackageQualified _ Lib name -> getSubLib gpd pkgN name
                Qualified Lib name -> getSubLib gpd pkgN name
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
    getMainLib gpd = toList $ condTreeData <$> condLibrary gpd
    getSubLib gpd pkgN name
        | toString name == pkgN =
            toList $ condTreeData <$> condLibrary gpd
        | otherwise =
            subLibsNamed gpd (toString name)


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
    mainLibTargets = maybe [] (const [qualified Lib mainPkgName]) (condLibrary gpd)
    subLibTargets = map (\(n, _) -> qualified Lib (getComponentName n)) (condSubLibraries gpd)
    flibTargets = map (\(n, _) -> qualified FLib (getComponentName n)) (condForeignLibs gpd)
    exeTargets = map (\(n, _) -> qualified Exe (getComponentName n)) (condExecutables gpd)
    testTargets = map (\(n, _) -> qualified Test (getComponentName n)) (condTestSuites gpd)
    benchTargets = map (\(n, _) -> qualified Bench (getComponentName n)) (condBenchmarks gpd)
    getComponentName = toText . unUnqualComponentName
    qualified = PackageQualified mainPkgName
