module Unit.Tricorder.SourceLookupSpec (spec_SourceLookup) where

import Atelier.Effects.Cache (Cache, runCacheForever)
import Atelier.Effects.Env (Env, runEnvConst)
import Atelier.Effects.FileSystem (FileSystem (..))
import Atelier.Effects.Log (Log, runLogNoOp)
import Atelier.Effects.Process (Process, runProcessReadWith)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.Reader.Static (Reader, runReader)
import Effectful.State.Static.Shared (State, evalState, gets, modify)
import System.Exit (ExitCode (..))
import System.FilePath ((</>))
import Test.Hspec

import Codec.Archive.Tar qualified as Tar
import Codec.Archive.Tar.Entry qualified as Tar
import Codec.Compression.GZip qualified as GZip
import Data.ByteString.Lazy qualified as BSL
import Data.IORef qualified as IORef
import Data.List qualified as List
import Data.Map.Strict qualified as Map
import Data.Text qualified as T

import Tricorder.Effects.GhcPkg (GhcPkg, GhcPkgScript (..), runGhcPkgScripted)
import Tricorder.GhcPkg.Types (ModuleName, PackageId, SourceQuery (..))
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.SourceLookup (ModuleSourceResult (..), lookupModuleSource)


spec_SourceLookup :: Spec
spec_SourceLookup = describe "lookupModuleSource" do
    it "reads the whole module from a cached tarball" do
        result <-
            runTest [NextFindModule (Just "aeson-2.2.5.0")] withTarball noFetch
                $ lookupModuleSource (wholeModule "Data.Aeson")
        result `shouldBe` SourceFound (wholeModule "Data.Aeson") moduleSource

    it "slices a symbol (with its doc block) from a cached tarball" do
        result <-
            runTest [NextFindModule (Just "aeson-2.2.5.0")] withTarball noFetch
                $ lookupModuleSource (symbol "Data.Aeson" "encode")
        result
            `shouldBe` SourceFound
                (symbol "Data.Aeson" "encode")
                "-- | Encode a value as JSON.\nencode :: Value -> ByteString\nencode = undefined"

    it "returns FunctionNotFound for a symbol absent from the module" do
        result <-
            runTest [NextFindModule (Just "aeson-2.2.5.0")] withTarball noFetch
                $ lookupModuleSource (symbol "Data.Aeson" "nope")
        result `shouldBe` FunctionNotFound (symbol "Data.Aeson" "nope")

    it "returns SourceNotFound when the module is in no package" do
        result <-
            runTest [NextFindModule Nothing] Map.empty noFetch
                $ lookupModuleSource (wholeModule "Data.Unknown")
        result `shouldBe` SourceNotFound (wholeModule "Data.Unknown")

    it "fetches on a cache miss, then reads the now-present tarball" do
        result <-
            runTest [NextFindModule (Just "aeson-2.2.5.0")] Map.empty (fetchProduces tarballPath tarballBytes)
                $ lookupModuleSource (wholeModule "Data.Aeson")
        result `shouldBe` SourceFound (wholeModule "Data.Aeson") moduleSource

    it "returns SourceUnavailable when the fetch produces no tarball" do
        result <-
            runTest [NextFindModule (Just "aeson-2.2.5.0")] Map.empty noFetch
                $ lookupModuleSource (wholeModule "Data.Aeson")
        result `shouldBe` SourceUnavailable (wholeModule "Data.Aeson") "aeson-2.2.5.0"

    it "caches the result so a second lookup needs no further resolution" do
        -- Only one NextFindModule is scripted; the second lookup must be served
        -- entirely from cache (module→package and package→source).
        (r1, r2) <-
            runTest [NextFindModule (Just "aeson-2.2.5.0")] withTarball noFetch $ do
                r1 <- lookupModuleSource (wholeModule "Data.Aeson")
                r2 <- lookupModuleSource (wholeModule "Data.Aeson")
                pure (r1, r2)
        r1 `shouldBe` SourceFound (wholeModule "Data.Aeson") moduleSource
        r2 `shouldBe` SourceFound (wholeModule "Data.Aeson") moduleSource

    it "caches an unavailable result and does not re-fetch on a repeat lookup" do
        -- The tarball is absent and every fetch fails, so the first lookup is
        -- SourceUnavailable. A repeat lookup must be served from cache — no
        -- second `cabal fetch` on the (network) request path.
        fetchCount <- IORef.newIORef (0 :: Int)
        let countingFetch = do
                liftIO (IORef.modifyIORef' fetchCount (+ 1))
                noFetch
        (r1, r2) <-
            runTest [NextFindModule (Just "aeson-2.2.5.0")] Map.empty countingFetch $ do
                r1 <- lookupModuleSource (wholeModule "Data.Aeson")
                r2 <- lookupModuleSource (wholeModule "Data.Aeson")
                pure (r1, r2)
        r1 `shouldBe` SourceUnavailable (wholeModule "Data.Aeson") "aeson-2.2.5.0"
        r2 `shouldBe` SourceUnavailable (wholeModule "Data.Aeson") "aeson-2.2.5.0"
        fetches <- IORef.readIORef fetchCount
        fetches `shouldBe` 1

    it "re-fetches after a failed fetch rather than caching the failure" do
        -- A failed `cabal fetch` (offline, stale index) is transient, so the
        -- resulting SourceUnavailable must NOT be cached: a repeat lookup has to
        -- retry the fetch, or a brief network blip pins unavailability for the
        -- whole cache window.
        fetchCount <- IORef.newIORef (0 :: Int)
        let failingFetch = do
                liftIO (IORef.modifyIORef' fetchCount (+ 1))
                pure (ExitFailure 1, "")
        (r1, r2) <-
            runTest [NextFindModule (Just "aeson-2.2.5.0")] Map.empty failingFetch $ do
                r1 <- lookupModuleSource (wholeModule "Data.Aeson")
                r2 <- lookupModuleSource (wholeModule "Data.Aeson")
                pure (r1, r2)
        r1 `shouldBe` SourceUnavailable (wholeModule "Data.Aeson") "aeson-2.2.5.0"
        r2 `shouldBe` SourceUnavailable (wholeModule "Data.Aeson") "aeson-2.2.5.0"
        fetches <- IORef.readIORef fetchCount
        fetches `shouldBe` 2

    it "finds a tarball in the legacy ~/.cabal cache location" do
        result <-
            runTest [NextFindModule (Just "aeson-2.2.5.0")] withLegacyTarball noFetch
                $ lookupModuleSource (wholeModule "Data.Aeson")
        result `shouldBe` SourceFound (wholeModule "Data.Aeson") moduleSource


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
tarballPath :: FilePath
tarballPath =
    "/h/.cache/cabal/packages" </> "hackage.haskell.org/aeson/2.2.5.0/aeson-2.2.5.0.tar.gz"


-- | A gzipped tar holding the fixture module under a @src\/@ layout.
tarballBytes :: LByteString
tarballBytes = mkTarball "aeson-2.2.5.0/src/Data/Aeson.hs" moduleSource


-- | A filesystem in which the fixture tarball is already cached.
withTarball :: Map FilePath LByteString
withTarball = Map.singleton tarballPath tarballBytes


-- | The legacy (pre-XDG) cabal cache path under @HOME=\/h@.
legacyTarballPath :: FilePath
legacyTarballPath =
    "/h/.cabal/packages" </> "hackage.haskell.org/aeson/2.2.5.0/aeson-2.2.5.0.tar.gz"


-- | A filesystem in which the fixture tarball lives only in the legacy cache.
withLegacyTarball :: Map FilePath LByteString
withLegacyTarball = Map.singleton legacyTarballPath tarballBytes


mkTarball :: FilePath -> Text -> LByteString
mkTarball entryPath content =
    GZip.compress (Tar.write [Tar.fileEntry tarPath (BSL.fromStrict (encodeUtf8 content))])
  where
    tarPath = either (error . toText) id (Tar.toTarPath False entryPath)


wholeModule :: ModuleName -> SourceQuery
wholeModule m = SourceQuery {moduleName = m, function = Nothing}


symbol :: ModuleName -> Text -> SourceQuery
symbol m s = SourceQuery {moduleName = m, function = Just s}


--------------------------------------------------------------------------------
-- Harness
--------------------------------------------------------------------------------

-- | The action a faked @cabal fetch@ runs: 'noFetch' leaves the filesystem
-- untouched (modelling a failed fetch); 'fetchProduces' inserts a file.
noFetch :: Eff es (ExitCode, LByteString)
noFetch = pure (ExitSuccess, "")


fetchProduces
    :: (State (Map FilePath LByteString) :> es)
    => FilePath -> LByteString -> Eff es (ExitCode, LByteString)
fetchProduces path bytes = do
    modify (Map.insert path bytes)
    pure (ExitSuccess, "")


runTest
    :: [GhcPkgScript]
    -> Map FilePath LByteString
    -> Eff '[FileSystem, State (Map FilePath LByteString), Log, Concurrent, IOE] (ExitCode, LByteString)
    -> Eff
        '[ Cache ModuleName PackageId
         , Cache (PackageId, SourceQuery) ModuleSourceResult
         , GhcPkg
         , Env
         , Reader ProjectRoot
         , Process
         , FileSystem
         , State (Map FilePath LByteString)
         , Log
         , Concurrent
         , IOE
         ]
        a
    -> IO a
runTest pkgScript initialFs onFetch action =
    runEff
        . runConcurrent
        . runLogNoOp
        . evalState initialFs
        . runFileSystemFake
        . runProcessReadWith onFetch
        . runReader (ProjectRoot "/proj")
        . runEnvConst [("HOME", "/h")]
        . runGhcPkgScripted pkgScript
        . runCacheForever @(PackageId, SourceQuery) @ModuleSourceResult
        . runCacheForever @ModuleName @PackageId
        $ action


-- | A 'FileSystem' backed by an in-memory map, with directory semantics good
-- enough for the cabal-cache layout: 'doesPathExist' treats a key as living
-- under any of its path prefixes, and 'listDirectory' returns immediate child
-- names (so a repo subdir like @hackage.haskell.org@ is discoverable).
runFileSystemFake
    :: (State (Map FilePath LByteString) :> es)
    => Eff (FileSystem : es) a -> Eff es a
runFileSystemFake = interpret_ \case
    DoesFileExist p -> gets (Map.member p)
    DoesPathExist p -> gets (any (isUnder p) . Map.keys)
    ListDirectory p -> gets (ordNub . mapMaybe (childName p) . Map.keys)
    ReadFileLbsFrom p _ -> gets (fromMaybe "" . Map.lookup p)
    _ -> error "runFileSystemFake: unexpected operation"
  where
    isUnder p k = p == k || (p <> "/") `List.isPrefixOf` k
    childName p k = case List.stripPrefix (p <> "/") k of
        Just rest | not (null rest) -> Just (takeWhile (/= '/') rest)
        _ -> Nothing
