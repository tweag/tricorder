-- | Locate, fetch, and read a package's source from its Hackage sdist tarball
-- in cabal's global package cache.
module Tricorder.SourceLookup.Tarball
    ( -- * High-level
      TarballOutcome (..)
    , obtainTarball
    , readModuleMember

      -- * Pure helpers (exposed for testing)
    , tarballPath
    , cabalPackagesDirs
    , matchesModule
    , extractModule
    )
where

import Atelier.Effects.FileSystem (FileSystem, readFileLbs)
import Atelier.Effects.Log (Log)
import Data.Char (isUpper)
import Effectful.Exception (trySync)
import System.FilePath (splitDirectories, (</>))
import Tricorder.SourceLookup.SourceQuery (ModuleName (..))

import Atelier.Effects.Log qualified as Log
import Codec.Archive.Tar qualified as Tar
import Codec.Compression.GZip qualified as GZip
import Data.ByteString.Lazy qualified as BSL
import Data.List qualified as List
import Data.Text qualified as T

import Tricorder.SourceLookup.Hackage (Hackage)
import Tricorder.SourceLookup.PackageId (PackageId (..), splitPackageId)
import Tricorder.SourceLookup.PackageStore (PackageStore)

import Tricorder.SourceLookup.Hackage qualified as Hackage
import Tricorder.SourceLookup.PackageStore qualified as PackageStore


-- ── High-level ─────────────────────────────────────────────────────────────

-- | The result of locating (and, if needed, fetching) a package's tarball.
data TarballOutcome
    = TarballAt FilePath
    | -- | No tarball, though the lookup completed cleanly (absent from every
      -- configured repository, or yanked).
      TarballAbsent
    | -- | The on-demand @cabal fetch@ itself failed (offline, stale index, …).
      TarballFetchFailed
    deriving stock (Eq, Show)


obtainTarball
    :: (Hackage :> es, Log :> es, PackageStore :> es)
    => PackageId
    -> Eff es TarballOutcome
obtainTarball pkgId = do
    found <- PackageStore.getPath pkgId
    case found of
        Just path -> pure (TarballAt path)
        Nothing -> do
            res <- Hackage.fetchPackage pkgId
            case res of
                Hackage.NotFound -> do
                    Log.warn $ "Package not found: " <> unPackageId pkgId
                    pure TarballAbsent
                Hackage.Failure err -> do
                    Log.err $ "Hackage fetch error: " <> err
                    pure $ TarballFetchFailed
                Hackage.Success bytes -> do
                    Log.info $ "Storing tarball for " <> unPackageId pkgId
                    path <- PackageStore.add pkgId bytes
                    Log.info $ "Tarball stored at " <> toText path
                    pure $ TarballAt path


-- | Read a single module's source from a tarball, in-process. 'Nothing' when
-- the member is absent or the archive cannot be read (any decompression or
-- parse error is caught, never propagated).
readModuleMember :: (FileSystem :> es) => FilePath -> ModuleName -> Eff es (Maybe Text)
readModuleMember tarball modName = do
    raw <- readFileLbs tarball
    -- 'force' drives the lazy gunzip + tar parse to completion inside 'trySync',
    -- so a corrupt archive yields 'Nothing' instead of a deferred exception.
    result <- trySync (pure $! force (extractModule modName raw))
    pure (either (const Nothing) id result)


-- ── Locate ─────────────────────────────────────────────────────────────────

-- | Candidate cabal package-cache directories to search, most-preferred first.
--
-- Honors @CABAL_DIR@; otherwise searches the XDG cache and both the modern
-- @~\/.cache\/cabal@ and the legacy pre-XDG @~\/.cabal@ layouts, since which one
-- cabal uses depends on its version and on whether @~\/.cabal@ already exists.
--
-- Only absolute candidates are produced: when @HOME@ (and the cabal vars) are
-- unset — as in a stripped daemon environment — the result is empty rather than
-- a path resolved relative to the working directory.
cabalPackagesDirs :: [(String, String)] -> [FilePath]
cabalPackagesDirs env =
    case List.lookup "CABAL_DIR" env of
        Just dir | not (null dir) -> [dir </> "packages"]
        _ -> xdgCandidate <> homeCandidates
  where
    xdgCandidate = case List.lookup "XDG_CACHE_HOME" env of
        Just x | not (null x) -> [x </> "cabal" </> "packages"]
        _ -> []
    homeCandidates = case List.lookup "HOME" env of
        Just h
            | not (null h) ->
                [ h </> ".cache" </> "cabal" </> "packages"
                , h </> ".cabal" </> "packages"
                ]
        _ -> []


-- ── Pure helpers ───────────────────────────────────────────────────────────

-- | The cache path of a package's tarball under one repository subdir:
-- @\<base\>\/\<repo\>\/\<pkg\>\/\<ver\>\/\<pkg\>-\<ver\>.tar.gz@.
tarballPath :: FilePath -> FilePath -> PackageId -> FilePath
tarballPath base repo pkgId =
    let (name, ver) = splitPackageId pkgId
    in  base </> repo </> toString name </> toString ver </> toString (name <> "-" <> ver <> ".tar.gz")


-- | Whether a tarball entry path is the source file for @modName@. Matches the
-- module's dotted-to-slashed path plus a Haskell source extension as a suffix,
-- which resolves @src\/@, @lib\/@, and flat layouts uniformly
-- (@\<pkg\>-\<ver\>\/src\/Data\/Aeson.hs@ etc.) and covers preprocessed sources
-- (@.hsc@, @.lhs@, @.chs@).
--
-- The path component immediately before the match must be a source root (e.g.
-- @src@, the package dir), not another module component — otherwise module
-- @Lens@ would spuriously match the file for @Control.Lens@.
matchesModule :: ModuleName -> FilePath -> Bool
matchesModule modName path = any matchesWithExtension sourceExtensions
  where
    slashed = T.map dotToSlash (unModuleName modName)
    txt = toText path
    matchesWithExtension ext = case T.stripSuffix ("/" <> slashed <> ext) txt of
        Just before -> not (endsWithModuleComponent before)
        Nothing -> False
    endsWithModuleComponent before = case T.uncons (T.takeWhileEnd (/= '/') before) of
        Just (c, _) -> isUpper c
        Nothing -> False
    dotToSlash '.' = '/'
    dotToSlash c = c


-- | Source-file extensions whose base name equals the final module component.
sourceExtensions :: [Text]
sourceExtensions = [".hs", ".lhs", ".hsc", ".chs"]


-- | Extract @modName@'s source text from a gzipped tarball. 'Nothing' when no
-- member matches.
extractModule :: ModuleName -> LByteString -> Maybe Text
extractModule modName tarGz =
    decodeUtf8 . BSL.toStrict <$> extractMember (matchesModule modName) tarGz


-- | The bytes of the best regular-file entry whose path satisfies the
-- predicate: a library path in preference to a same-named copy under a
-- @test@\/@bench@\/@example@ tree, then the shallowest path. This keeps a
-- package's test module from shadowing the library module of the same name.
extractMember :: (FilePath -> Bool) -> LByteString -> Maybe LByteString
extractMember matches tarGz =
    snd <$> viaNonEmpty head (List.sortOn rank candidates)
  where
    entries = Tar.read (GZip.decompress tarGz)
    candidates = Tar.foldEntries step [] (const []) entries
    step entry acc = case Tar.entryContent entry of
        Tar.NormalFile bytes _
            | matches path -> (path, bytes) : acc
          where
            path = Tar.entryPath entry
        _ -> acc
    rank (path, _) = (isNonLibraryPath path, length (splitDirectories path))


-- | Whether a path lies under a non-library source tree (tests, benchmarks,
-- examples), which we deprioritise when the same module appears more than once.
isNonLibraryPath :: FilePath -> Bool
isNonLibraryPath path = any (`elem` nonLibraryDirs) (splitDirectories path)
  where
    nonLibraryDirs :: [FilePath]
    nonLibraryDirs =
        [ "test"
        , "tests"
        , "bench"
        , "benchmark"
        , "benchmarks"
        , "example"
        , "examples"
        , "spec"
        , "specs"
        ]
