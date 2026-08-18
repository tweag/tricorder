module Tricorder.SourceLookup
    ( -- * Types
      SourceQuery (..)
    , ModuleSourceResult (..)

      -- * Lookup
    , lookupModuleSource
    )
where

import Atelier.Effects.Cache (Cache, cacheInsert, cacheLookup)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Log (Log)
import Data.Aeson (FromJSON, ToJSON)

import Atelier.Effects.Log qualified as Log

import Tricorder.Module (ModuleName (..), PackageId (..))
import Tricorder.SourceLookup.GhcPkg (GhcPkg)
import Tricorder.SourceLookup.Hackage (Hackage)
import Tricorder.SourceLookup.PackageStore (PackageStore)
import Tricorder.SourceLookup.Slice (sliceSymbol)
import Tricorder.SourceLookup.Tarball
    ( TarballOutcome (..)
    , obtainTarball
    , readModuleMember
    )

import Tricorder.SourceLookup.GhcPkg qualified as GhcPkg


-- | The result of a source lookup for a single module.
data ModuleSourceResult
    = -- | Source was found; contains the module (or single-symbol) source text.
      SourceFound SourceQuery Text
    | -- | The module is not provided by any installed package.
      SourceNotFound SourceQuery
    | -- | The package was resolved but no source tarball could be located or
      -- fetched (no index, offline, yanked, or the archive could not be read).
      SourceUnavailable SourceQuery PackageId
    | -- | The module source was found but the requested symbol was not in it.
      FunctionNotFound SourceQuery
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


-- | A query for module source: optionally scoped to a single top-level symbol.
data SourceQuery = SourceQuery
    { moduleName :: ModuleName
    , function :: Maybe Text
    -- ^ The symbol to slice: 'Nothing' is the whole module; @'Just' name@ is a
    -- single top-level declaration — a value binding, or (by initial casing) a
    -- type, class, or constructor.
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, Hashable, ToJSON)


-- ── Lookup logic ───────────────────────────────────────────────────────────

-- | Resolve and return the source for a single module.
--
-- Resolves the module to its project-pinned 'PackageId' via @ghc-pkg@, then
-- serves source from that package's sdist tarball in cabal's global cache,
-- fetching it on demand if absent. A symbol query slices the relevant
-- declaration (with its doc comment) from the module source. Both resolution
-- steps are cached, so the fetch + read cost is paid at most once per
-- (package, query).
lookupModuleSource
    :: ( Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Hackage :> es
       , Log :> es
       , PackageStore :> es
       )
    => SourceQuery
    -> Eff es ModuleSourceResult
lookupModuleSource query = do
    mPkg <- resolvePackage query.moduleName
    case mPkg of
        Nothing -> pure (SourceNotFound query)
        Just p -> do
            mCached <- cacheLookup @(PackageId, SourceQuery) @ModuleSourceResult (p, query)
            case mCached of
                Just result -> do
                    Log.debug $ "Source: " <> unModuleName query.moduleName <> " source hit (cached)"
                    pure result
                Nothing -> serveFromTarball query p


-- | Resolve a module to its package, consulting the module -> package cache first.
resolvePackage
    :: (Cache ModuleName PackageId :> es, GhcPkg :> es, Log :> es)
    => ModuleName
    -> Eff es (Maybe PackageId)
resolvePackage modName = do
    mCachedPkg <- cacheLookup @ModuleName @PackageId modName
    case mCachedPkg of
        Just p -> do
            Log.debug $ "Source: " <> unModuleName modName <> " → " <> unPackageId p <> " (cached)"
            pure (Just p)
        Nothing -> do
            result <- GhcPkg.findModule modName
            Log.debug $ "Source: find-module " <> unModuleName modName <> " → " <> show result
            whenJust result (cacheInsert @ModuleName @PackageId modName)
            pure result


-- | Locate (or fetch) the package's tarball, read the module member, and slice
-- the requested symbol if any. Caches and returns the result.
serveFromTarball
    :: ( Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , FileSystem :> es
       , Hackage :> es
       , Log :> es
       , PackageStore :> es
       )
    => SourceQuery
    -> PackageId
    -> Eff es ModuleSourceResult
serveFromTarball query p =
    obtainTarball p >>= \case
        -- A failed `cabal fetch` is transient (offline, stale index), so return
        -- unavailable WITHOUT caching: a later lookup retries once the network or
        -- index recovers, rather than serving the negative for the whole window.
        TarballFetchFailed -> pure (SourceUnavailable query p)
        -- The package is genuinely absent — a deterministic negative, safe to
        -- cache alongside the read/slice outcomes below.
        TarballAbsent -> cacheResult (SourceUnavailable query p)
        TarballAt tarball -> do
            mModuleSrc <- readModuleMember tarball query.moduleName
            cacheResult $ case mModuleSrc of
                Nothing -> SourceUnavailable query p
                Just moduleSrc -> case query.function of
                    Nothing -> SourceFound query moduleSrc
                    Just symbol -> case sliceSymbol symbol moduleSrc of
                        Just slice -> SourceFound query slice
                        Nothing -> FunctionNotFound query
  where
    -- Cache a deterministic outcome so the fetch + read/slice cost is paid at
    -- most once per (package, query) within the cache window.
    cacheResult result = do
        cacheInsert @(PackageId, SourceQuery) @ModuleSourceResult (p, query) result
        pure result
