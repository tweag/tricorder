module Unit.Tricorder.SourceLookupSpec (test_SourceLookup) where

import Atelier.Effects.Env (Env)
import Atelier.Effects.Input (Input)
import Atelier.Effects.Log (Log)
import Atelier.FileSystem.Path ((</>))
import Data.Default (def)
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Effectful (IOE)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.FileSystem (FileSystem)
import Test.Tasty (DependencyType (AllFinish), TestTree, dependentTestGroup, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))
import Tricorder.SourceLookup.ModuleSourceResult (ModuleSourceResult (..))
import Tricorder.SourceLookup.ReexportLimits (ReexportLimits (..), defaultReexportLimits)
import Tricorder.SourceLookup.SourceQuery (ModuleName, SourceQuery (..))

import Atelier.Effects.Env qualified as Env
import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log qualified as Log
import Atelier.FileSystem.Path qualified as Path
import Codec.Archive.Tar qualified as Tar
import Codec.Archive.Tar.Entry qualified as Tar
import Codec.Compression.GZip qualified as GZip
import Data.ByteString.Lazy qualified as BSL
import Data.Map.Strict qualified as Map
import Data.Text qualified as T

import Tricorder.Session.CabalFile (CabalFile (..))
import Tricorder.SourceLookup
    ( ProjectSourceDirs (..)
    , lookupModuleSource
    , projectSourceDirs
    )
import Tricorder.SourceLookup.GhcPkg (GhcPkg, GhcPkgScript (..), runGhcPkgScripted)
import Tricorder.SourceLookup.Hackage (Hackage (..), Result (..))
import Tricorder.SourceLookup.PackageStore (PackageStore)
import Unit.Tricorder.Session.Helpers (withHome, withProjectFiles)

import Tricorder.Session.Stage.Build.Session qualified as Build
import Tricorder.SourceLookup.PackageStore qualified as PackageStore


test_SourceLookup :: TestTree
test_SourceLookup =
    -- The package store resolves its cache dir from $HOME, which is
    -- process-global, so these must not run concurrently.
    dependentTestGroup
        "SourceLookup"
        AllFinish
        [ testGroup
            "lookupModuleSource"
            [ testCase "reads the whole module from a cached tarball" do
                result <-
                    runTest [NextFindModule (Just "aeson-2.2.5.0")] withTarball noFetch
                        $ lookupModuleSource noProjectDirs defaultReexportLimits (wholeModule "Data.Aeson")
                result @?= SourceFound (wholeModule "Data.Aeson") moduleSource
            , testCase "slices a symbol (with its doc block) from a cached tarball" do
                result <-
                    runTest [NextFindModule (Just "aeson-2.2.5.0")] withTarball noFetch
                        $ lookupModuleSource noProjectDirs defaultReexportLimits (symbol "Data.Aeson" "encode")
                result
                    @?= SourceFound
                        (symbol "Data.Aeson" "encode")
                        "-- | Encode a value as JSON.\nencode :: Value -> ByteString\nencode = undefined"
            , testCase "returns FunctionNotFound for a symbol absent from the module" do
                result <-
                    runTest
                        (NextFindModule (Just "aeson-2.2.5.0") : cycle [NextFindModule Nothing])
                        withTarball
                        noFetch
                        $ lookupModuleSource noProjectDirs defaultReexportLimits (symbol "Data.Aeson" "nope")
                result @?= FunctionNotFound (symbol "Data.Aeson" "nope")
            , testCase "returns SourceNotFound when the module is in no package" do
                result <-
                    runTest [NextFindModule Nothing] Map.empty noFetch
                        $ lookupModuleSource noProjectDirs defaultReexportLimits (wholeModule "Data.Unknown")
                result @?= SourceNotFound (wholeModule "Data.Unknown")
            , testCase "fetches from Hackage on a cache miss, then reads the now-fetched tarball" do
                result <-
                    runTest
                        [NextFindModule (Just "aeson-2.2.5.0")]
                        Map.empty
                        (pure (Success (BSL.toStrict tarballBytes)))
                        $ lookupModuleSource noProjectDirs defaultReexportLimits (wholeModule "Data.Aeson")
                result @?= SourceFound (wholeModule "Data.Aeson") moduleSource
            , testCase "returns SourceUnavailable when the package is not found on Hackage" do
                result <-
                    runTest [NextFindModule (Just "aeson-2.2.5.0")] Map.empty noFetch
                        $ lookupModuleSource noProjectDirs defaultReexportLimits (wholeModule "Data.Aeson")
                result @?= SourceUnavailable (wholeModule "Data.Aeson") "aeson-2.2.5.0"
            , testCase "follows a re-export to the defining module" do
                result <-
                    runTest
                        (NextFindModule (Just "reex-1.0") : cycle [NextFindModule (Just "reex-1.0")])
                        withReexportTarball
                        noFetch
                        $ lookupModuleSource noProjectDirs defaultReexportLimits (symbol "Data.Reex" "pack")
                result
                    @?= SourceReexported
                        (symbol "Data.Reex" "pack")
                        "Data.Reex.Internal"
                        "-- | Pack a string.\npack :: String -> Text\npack = undefined"
            , testCase "follows a re-export into a module ghc-pkg cannot place" do
                -- A hidden (other-modules) module is not found by ghc-pkg; it is
                -- looked up in the re-exporting module's package instead.
                result <-
                    runTest
                        (NextFindModule (Just "reex-1.0") : cycle [NextFindModule Nothing])
                        withReexportTarball
                        noFetch
                        $ lookupModuleSource noProjectDirs defaultReexportLimits (symbol "Data.Reex" "pack")
                result
                    @?= SourceReexported
                        (symbol "Data.Reex" "pack")
                        "Data.Reex.Internal"
                        "-- | Pack a string.\npack :: String -> Text\npack = undefined"
            , testCase "follows a chain of re-exports to the defining module" do
                -- A re-exports foo from B, which re-exports it from C, which defines it.
                result <-
                    runTest
                        (replicate 3 (NextFindModule (Just "chain-1.0")) <> cycle [NextFindModule Nothing])
                        withChainTarball
                        noFetch
                        $ lookupModuleSource noProjectDirs defaultReexportLimits (symbol "A" "foo")
                result @?= SourceReexported (symbol "A" "foo") "C" "foo :: Int\nfoo = 42"
            , testGroup
                "re-export limits"
                -- The A -> B -> C chain takes 2 hops and reads 2 modules (B and C).
                [ testCase "finds the definition when the depth covers the chain" do
                    result <- lookupChain ReexportLimits {maxDepth = 2, maxModules = 24}
                    result @?= SourceReexported (symbol "A" "foo") "C" "foo :: Int\nfoo = 42"
                , testCase "stops short of the definition when the depth is too small" do
                    result <- lookupChain ReexportLimits {maxDepth = 1, maxModules = 24}
                    result @?= FunctionNotFound (symbol "A" "foo")
                , testCase "does not follow re-exports at depth 0" do
                    result <- lookupChain ReexportLimits {maxDepth = 0, maxModules = 24}
                    result @?= FunctionNotFound (symbol "A" "foo")
                , testCase "finds the definition when the module budget covers the chain" do
                    result <- lookupChain ReexportLimits {maxDepth = 5, maxModules = 2}
                    result @?= SourceReexported (symbol "A" "foo") "C" "foo :: Int\nfoo = 42"
                , testCase "stops short of the definition when the module budget runs out" do
                    result <- lookupChain ReexportLimits {maxDepth = 5, maxModules = 1}
                    result @?= FunctionNotFound (symbol "A" "foo")
                ]
            , testCase "returns FunctionNotFound when no re-export defines the symbol" do
                result <-
                    runTest
                        (NextFindModule (Just "reex-1.0") : cycle [NextFindModule Nothing])
                        withReexportTarball
                        noFetch
                        $ lookupModuleSource noProjectDirs defaultReexportLimits (symbol "Data.Reex" "unpack")
                result @?= FunctionNotFound (symbol "Data.Reex" "unpack")
            , testCase "finds a tarball in the legacy ~/.cabal cache location" do
                result <-
                    runTest [NextFindModule (Just "aeson-2.2.5.0")] withLegacyTarball noFetch
                        $ lookupModuleSource noProjectDirs defaultReexportLimits (wholeModule "Data.Aeson")
                result @?= SourceFound (wholeModule "Data.Aeson") moduleSource
            ]
        , testGroup
            "project modules"
            [ testCase "resolves every component's source dirs against the package dir" do
                projectSourceDirs [projectCabalFile (Path.absolute @"/")]
                    @?= ProjectSourceDirs [Path.absolute @"/p/src", Path.absolute @"/p/test"]
            , testCase "reads a module from the project's source dirs" do
                result <-
                    runTestAt [] projectFiles noFetch
                        $ \root -> lookupModuleSource (projectDirs root) defaultReexportLimits (wholeModule "Proj.Types")
                result @?= SourceFound (wholeModule "Proj.Types") projectTypesSource
            , testCase "reads a module from a non-library component's source dirs" do
                result <-
                    runTestAt [] projectFiles noFetch
                        $ \root -> lookupModuleSource (projectDirs root) defaultReexportLimits (wholeModule "Proj.Helpers")
                result @?= SourceFound (wholeModule "Proj.Helpers") projectHelpersSource
            , testCase "slices a symbol from a project module" do
                result <-
                    runTestAt [] projectFiles noFetch
                        $ \root -> lookupModuleSource (projectDirs root) defaultReexportLimits (symbol "Proj.Types" "greeting")
                result
                    @?= SourceFound
                        (symbol "Proj.Types" "greeting")
                        "-- | A greeting.\ngreeting :: Text\ngreeting = \"hi\""
            , testCase "follows a re-export to another project module" do
                result <-
                    runTestAt [] projectFiles noFetch
                        $ \root -> lookupModuleSource (projectDirs root) defaultReexportLimits (symbol "Proj" "greeting")
                result
                    @?= SourceReexported
                        (symbol "Proj" "greeting")
                        "Proj.Types"
                        "-- | A greeting.\ngreeting :: Text\ngreeting = \"hi\""
            , testCase "follows a re-export from a project module into a package" do
                result <-
                    runTestAt
                        [NextFindModule (Just "aeson-2.2.5.0")]
                        (projectFiles <> withTarball)
                        noFetch
                        $ \root -> lookupModuleSource (projectDirs root) defaultReexportLimits (symbol "Proj" "encode")
                result
                    @?= SourceReexported
                        (symbol "Proj" "encode")
                        "Data.Aeson"
                        "-- | Encode a value as JSON.\nencode :: Value -> ByteString\nencode = undefined"
            , testCase "falls back to installed packages for a module not in the project" do
                result <-
                    runTestAt
                        [NextFindModule (Just "aeson-2.2.5.0")]
                        (projectFiles <> withTarball)
                        noFetch
                        $ \root -> lookupModuleSource (projectDirs root) defaultReexportLimits (wholeModule "Data.Aeson")
                result @?= SourceFound (wholeModule "Data.Aeson") moduleSource
            ]
        ]


--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

-- | Source of the fixture module, carried verbatim in the fixture tarball.
moduleSource :: Text
moduleSource =
    T.unlines
        [ "module Data.Aeson where"
        , ""
        , "-- | Encode a value as JSON."
        , "encode :: Value -> ByteString"
        , "encode = undefined"
        ]


-- | The cabal cache path the fixture package resolves to under @HOME=\/h@.
tarballPath :: Path.Relative
tarballPath =
    Path.rel @"h/.cache/cabal/packages"
        </> Path.rel @"hackage.haskell.org/aeson/2.2.5.0/aeson-2.2.5.0.tar.gz"


-- | A gzipped tar holding the fixture module under a @src\/@ layout.
tarballBytes :: LByteString
tarballBytes = mkTarball "aeson-2.2.5.0/src/Data/Aeson.hs" moduleSource


-- | A filesystem in which the fixture tarball is already cached.
withTarball :: Map Path.Relative LByteString
withTarball = Map.singleton tarballPath tarballBytes


-- | The legacy (pre-XDG) cabal cache path under @HOME=\/h@.
legacyTarballPath :: Path.Relative
legacyTarballPath =
    Path.rel @"h/.cabal/packages" </> Path.rel @"hackage.haskell.org/aeson/2.2.5.0/aeson-2.2.5.0.tar.gz"


-- | A filesystem in which the fixture tarball lives only in the legacy cache.
withLegacyTarball :: Map Path.Relative LByteString
withLegacyTarball = Map.singleton legacyTarballPath tarballBytes


-- | A project package with a library under @src@ and a test suite under @test@.
projectCabalFile :: Path.Absolute -> CabalFile
projectCabalFile root =
    CabalFile (root </> Path.rel @"p/proj.cabal")
        . fromMaybe (error "projectCabalFile: unparseable")
        . parseGenericPackageDescriptionMaybe
        . encodeUtf8
        $ T.unlines
            [ "cabal-version: 3.0"
            , "name: proj"
            , "version: 0.1"
            , "library"
            , "  hs-source-dirs: src"
            , "  exposed-modules: Proj, Proj.Types"
            , "test-suite spec"
            , "  type: exitcode-stdio-1.0"
            , "  main-is: Main.hs"
            , "  hs-source-dirs: test"
            , "  other-modules: Proj.Helpers"
            ]


projectDirs :: Path.Absolute -> ProjectSourceDirs
projectDirs root = projectSourceDirs [projectCabalFile root]


noProjectDirs :: ProjectSourceDirs
noProjectDirs = ProjectSourceDirs []


projectTypesSource :: Text
projectTypesSource =
    T.unlines
        [ "module Proj.Types where"
        , ""
        , "-- | A greeting."
        , "greeting :: Text"
        , "greeting = \"hi\""
        ]


projectHelpersSource :: Text
projectHelpersSource = T.unlines ["module Proj.Helpers where", "", "helper :: Int", "helper = 1"]


-- | The source files of 'projectCabalFile': @Proj@ re-exports @greeting@ from
-- @Proj.Types@ and @encode@ from the installed @Data.Aeson@.
projectFiles :: Map Path.Relative LByteString
projectFiles =
    Map.fromList
        [
            ( Path.rel @"p/src/Proj.hs"
            , encodeUtf8 @Text
                "module Proj (greeting, encode) where\n\nimport Proj.Types (greeting)\nimport Data.Aeson (encode)\n"
            )
        , (Path.rel @"p/src/Proj/Types.hs", encodeUtf8 projectTypesSource)
        , (Path.rel @"p/test/Proj/Helpers.hs", encodeUtf8 projectHelpersSource)
        ]


-- | A package in which @A@ re-exports @foo@ from @B@, which re-exports it from
-- @C@, which defines it.
withChainTarball :: Map Path.Relative LByteString
withChainTarball =
    Map.singleton
        (Path.rel @"h/.cache/cabal/packages" </> Path.rel @"hackage.haskell.org/chain/1.0/chain-1.0.tar.gz")
        $ mkTarballWith
            [ ("chain-1.0/src/A.hs", T.unlines ["module A (foo) where", "", "import B (foo)"])
            , ("chain-1.0/src/B.hs", T.unlines ["module B (foo) where", "", "import C"])
            , ("chain-1.0/src/C.hs", T.unlines ["module C where", "", "foo :: Int", "foo = 42"])
            ]


-- | Look up @A#foo@ in the 'withChainTarball' package under the given limits.
lookupChain :: ReexportLimits -> IO ModuleSourceResult
lookupChain limits =
    runTest
        (replicate 3 (NextFindModule (Just "chain-1.0")) <> cycle [NextFindModule Nothing])
        withChainTarball
        noFetch
        $ lookupModuleSource noProjectDirs limits (symbol "A" "foo")


-- | A package whose @Data.Reex@ re-exports @pack@ (and claims to re-export
-- @unpack@) from @Data.Reex.Internal@, which only defines @pack@.
withReexportTarball :: Map Path.Relative LByteString
withReexportTarball =
    Map.singleton
        (Path.rel @"h/.cache/cabal/packages" </> Path.rel @"hackage.haskell.org/reex/1.0/reex-1.0.tar.gz")
        $ mkTarballWith
            [
                ( "reex-1.0/src/Data/Reex.hs"
                , T.unlines
                    [ "module Data.Reex (Text, pack, unpack) where"
                    , ""
                    , "import Data.Reex.Internal (Text, pack, unpack)"
                    ]
                )
            ,
                ( "reex-1.0/src/Data/Reex/Internal.hs"
                , T.unlines
                    [ "module Data.Reex.Internal where"
                    , ""
                    , "-- | Pack a string."
                    , "pack :: String -> Text"
                    , "pack = undefined"
                    ]
                )
            ]


mkTarball :: FilePath -> Text -> LByteString
mkTarball entryPath content = mkTarballWith [(entryPath, content)]


mkTarballWith :: [(FilePath, Text)] -> LByteString
mkTarballWith entries =
    GZip.compress
        (Tar.write [Tar.fileEntry (tarPath p) (BSL.fromStrict (encodeUtf8 c)) | (p, c) <- entries])
  where
    tarPath p = either (error . toText) id (Tar.toTarPath False p)


wholeModule :: ModuleName -> SourceQuery
wholeModule m = SourceQuery {moduleName = m, function = Nothing}


symbol :: ModuleName -> Text -> SourceQuery
symbol m s = SourceQuery {moduleName = m, function = Just s}


--------------------------------------------------------------------------------
-- Harness
--------------------------------------------------------------------------------

-- | The scripted response to a faked Hackage fetch: 'noFetch' reports the
-- package as a clean 404 (absent from the index, so no tarball). A successful
-- fetch is modelled by returning 'Success' with the tarball bytes directly —
-- 'PackageStore.add' is the one that persists it into the fake filesystem — and
-- a failed fetch, by returning 'Failure' directly.
noFetch :: Eff es Result
noFetch = pure NotFound


type FetchEffects =
    '[ PackageStore
     , Env
     , Input Build.Session
     , Log
     , Concurrent
     , FileSystem
     , IOE
     ]


type TestEffects = GhcPkg : Hackage : FetchEffects


runTest
    :: [GhcPkgScript]
    -> Map Path.Relative LByteString
    -> Eff FetchEffects Result
    -> Eff TestEffects a
    -> IO a
runTest pkgScript initialFs onFetch action =
    runTestAt pkgScript initialFs onFetch (const action)


-- | Run against a real temporary directory seeded with @initialFs@ (paths
-- relative to it), which doubles as the test's @$HOME@ (at @h/@) and, for
-- project modules, the parent of the project package (at @p/@). The action
-- receives the directory's path.
--
-- 'Effectful.FileSystem' only has a real-IO interpreter, so the package cache
-- and project sources have to exist on disk. @$HOME@ is process-global; see
-- 'test_SourceLookup'.
runTestAt
    :: [GhcPkgScript]
    -> Map Path.Relative LByteString
    -> Eff FetchEffects Result
    -> (Path.Absolute -> Eff TestEffects a)
    -> IO a
runTestAt pkgScript initialFs onFetch action =
    withProjectFiles (BSL.toStrict <$> initialFs) \root ->
        withHome (root </> Path.rel @"h")
            . runConcurrent
            . Log.runNoOp
            . Input.withConst (def :: Build.Session)
            . Env.runConst []
            . PackageStore.run
            . runHackageWith onFetch
            . runGhcPkgScripted pkgScript
            $ action root


-- | A scripted 'Hackage' interpreter: every 'fetchPackage' yields the given
-- action's result.
runHackageWith :: Eff es Result -> Eff (Hackage : es) a -> Eff es a
runHackageWith onFetch = interpret_ \case
    FetchPackage _ -> onFetch
