module Tricorder.SourceLookup
    ( ModuleSourceResult (..)
    , ReexportLimits (..)
    , defaultReexportLimits
    , lookupModuleSource
    , ProjectSourceDirs (..)
    , projectSourceDirs
    )
where

import Atelier.Effects.Cache (Cache, cacheInsert, cacheLookup)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, readFileLbs)
import Atelier.Effects.Input (Input, input)
import Atelier.Effects.Log (Log)
import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generically (..))
import System.FilePath (normalise, takeDirectory, (</>))
import Tricorder.SourceLookup.SourceQuery (ModuleName (..), SourceQuery (..))

import Atelier.Effects.Log qualified as Log
import Data.Set qualified as Set
import Data.Text qualified as T

import Tricorder.Session.CabalFile (CabalFile (..))
import Tricorder.Session.Repl (Repl)
import Tricorder.Session.WatchDirs (allSourceDirs)
import Tricorder.SourceLookup.GhcPkg (GhcPkg)
import Tricorder.SourceLookup.Hackage (Hackage)
import Tricorder.SourceLookup.PackageId (PackageId (..))
import Tricorder.SourceLookup.PackageStore (PackageStore)
import Tricorder.SourceLookup.Reexport (declaresMember, exportsByName, reexportCandidates)
import Tricorder.SourceLookup.Slice (sliceSymbol)
import Tricorder.SourceLookup.Tarball
    ( TarballOutcome (..)
    , obtainTarball
    , readModuleMember
    , sourceExtensions
    )

import Tricorder.SourceLookup.GhcPkg qualified as GhcPkg


-- | The result of a source lookup for a single module.
data ModuleSourceResult
    = -- | Source was found; contains the module (or single-symbol) source text.
      SourceFound SourceQuery Text
    | -- | The module is neither in the project nor in any installed package.
      SourceNotFound SourceQuery
    | -- | The package was resolved but no source tarball could be located or
      -- fetched (no index, offline, yanked, or the archive could not be read).
      SourceUnavailable SourceQuery PackageId
    | -- | The symbol is not defined in the queried module but re-exported by
      -- it; contains the module that defines it and the symbol's source there.
      SourceReexported SourceQuery ModuleName Text
    | -- | The module source was found but the requested symbol was not in it.
      FunctionNotFound SourceQuery
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically ModuleSourceResult


-- | Bounds on the re-export search for a symbol the queried module does not
-- define itself (see 'followReexports').
data ReexportLimits = ReexportLimits
    { maxDepth :: Word
    -- ^ Most re-export hops to follow; @0@ disables following re-exports.
    , maxModules :: Word
    -- ^ Most modules to read during the search.
    }
    deriving stock (Eq, Show)


-- | Enough for the deepest chains seen in practice (@Prelude#Maybe@ takes 3
-- hops through @ghc-internal@) while keeping a miss cheap.
defaultReexportLimits :: ReexportLimits
defaultReexportLimits = ReexportLimits {maxDepth = 5, maxModules = 24}


-- | The directories holding the project's own modules: the @hs-source-dirs@ of
-- every component of every project package, resolved against the package dir.
newtype ProjectSourceDirs = ProjectSourceDirs [FilePath]
    deriving stock (Eq, Show)


projectSourceDirs :: [CabalFile] -> ProjectSourceDirs
projectSourceDirs cabalFiles =
    ProjectSourceDirs
        $ ordNub
            [ normalise (takeDirectory cabalFile.projectFilePath </> dir)
            | cabalFile <- cabalFiles
            , dir <- orRoot (allSourceDirs cabalFile.projectPackageDescription)
            ]
  where
    -- A component without @hs-source-dirs@ keeps its sources in the package dir.
    orRoot [] = ["."]
    orRoot dirs = dirs


-- | Where a module's source was found.
data Origin
    = -- | A source file under one of the project's @hs-source-dirs@.
      InProject
    | -- | The sdist tarball of an installed package.
      InPackage PackageId


-- ── Lookup logic ───────────────────────────────────────────────────────────

-- | Resolve and return the source for a single module.
--
-- A module defined in the project itself is read straight from its source
-- file. Otherwise the module is resolved to its project-pinned 'PackageId' via
-- @ghc-pkg@, and source is served from that package's sdist tarball in cabal's
-- global cache, fetching it on demand if absent. A symbol query slices the
-- relevant declaration (with its doc comment) from the module source. Both
-- package resolution steps are cached, so the fetch + read cost is paid at most
-- once per (package, query); project sources are always read fresh.
--
-- A symbol the module does not define itself is searched for in the modules it
-- may re-export it from (see 'followReexports').
lookupModuleSource
    :: ( Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Hackage :> es
       , Input Repl :> es
       , Log :> es
       , PackageStore :> es
       )
    => ProjectSourceDirs
    -> ReexportLimits
    -> SourceQuery
    -> Eff es ModuleSourceResult
lookupModuleSource dirs limits query = do
    (mOrigin, result) <- lookupLocal dirs InProject query
    case (result, mOrigin, query.function) of
        (FunctionNotFound _, Just origin, Just symbol) ->
            fromMaybe result <$> followReexports dirs limits query symbol origin
        _ -> pure result


-- | Look up a query in the module's own source, without following re-exports.
--
-- @parent@ is where the module was reached from. Reached from the project (or
-- queried directly), the project's own sources are searched first. Reached from
-- a package they are skipped, since a package cannot import project modules,
-- and when @ghc-pkg@ cannot place the module (e.g. a hidden @other-modules@
-- entry) the parent package is used instead. Also returns where the module was
-- found, if anywhere.
lookupLocal
    :: ( Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Hackage :> es
       , Input Repl :> es
       , Log :> es
       , PackageStore :> es
       )
    => ProjectSourceDirs
    -> Origin
    -> SourceQuery
    -> Eff es (Maybe Origin, ModuleSourceResult)
lookupLocal dirs parent query = do
    mFile <- case parent of
        InProject -> findProjectModule dirs query.moduleName
        InPackage _ -> pure Nothing
    case mFile of
        Just path -> do
            Log.debug $ "Source: " <> unModuleName query.moduleName <> " → " <> toText path
            src <- decodeUtf8 . toStrict <$> readFileLbs path
            pure (Just InProject, fromModuleSource query src)
        Nothing -> do
            mPkg <- (<|> fallback) <$> resolvePackage query.moduleName
            case mPkg of
                Nothing -> pure (Nothing, SourceNotFound query)
                Just p -> do
                    mCached <- cacheLookup @(PackageId, SourceQuery) @ModuleSourceResult (p, query)
                    (Just (InPackage p),) <$> case mCached of
                        Just result -> do
                            Log.debug $ "Source: " <> unModuleName query.moduleName <> " source hit (cached)"
                            pure result
                        Nothing -> serveFromTarball query p
  where
    fallback = case parent of
        InProject -> Nothing
        InPackage p -> Just p


-- | Find the source file of a module defined in the project: the first
-- candidate path, in source dir then extension order, that exists.
findProjectModule
    :: (FileSystem :> es)
    => ProjectSourceDirs -> ModuleName -> Eff es (Maybe FilePath)
findProjectModule (ProjectSourceDirs dirs) modName =
    firstExisting [dir </> relPath <> toString ext | dir <- dirs, ext <- sourceExtensions]
  where
    relPath = toString $ T.replace "." "/" (unModuleName modName)
    firstExisting [] = pure Nothing
    firstExisting (path : rest) = ifM (doesFileExist path) (pure (Just path)) (firstExisting rest)


-- | The result of a query against the source of the module it names.
fromModuleSource :: SourceQuery -> Text -> ModuleSourceResult
fromModuleSource query moduleSrc = case query.function of
    Nothing -> SourceFound query moduleSrc
    Just symbol -> case sliceSymbol symbol moduleSrc of
        Just slice -> SourceFound query slice
        Nothing -> FunctionNotFound query


-- | Search the modules a symbol may be re-exported from (see
-- 'reexportCandidates'), starting at the queried module found at @origin@,
-- for the module that defines it.
--
-- The search is best-first: once a module's export list names the symbol (see
-- 'exportsByName'), its leads — and theirs, down the chain — are followed
-- depth-first, ahead of the remaining weaker candidates, which are searched
-- breadth-first. A hub like @GHC.Internal.Base@ re-exports through @module M@
-- entries that never name the symbol, so strength must be inherited for its
-- leads to be reached before the budget is spent. It is bounded in depth and in
-- the number of modules read, so a symbol that is genuinely absent costs only a
-- handful of lookups. It stops early at a module that declares the symbol as a
-- member of a local type or class (see 'declaresMember'): that module defines
-- it, so following other imports could only find an unrelated namesake.
followReexports
    :: ( Cache (PackageId, SourceQuery) ModuleSourceResult :> es
       , Cache ModuleName PackageId :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Hackage :> es
       , Input Repl :> es
       , Log :> es
       , PackageStore :> es
       )
    => ProjectSourceDirs
    -> ReexportLimits
    -> SourceQuery
    -> Text
    -> Origin
    -> Eff es (Maybe ModuleSourceResult)
followReexports dirs limits query symbol origin
    | limits.maxDepth <= 0 = pure Nothing
    | otherwise =
        candidatesIn origin query.moduleName >>= \case
            Nothing -> pure Nothing
            -- The queried module's candidates are one hop away.
            Just (_, roots) ->
                go
                    (Set.singleton query.moduleName)
                    limits.maxModules
                    [(m, mo, 1, False) | (m, mo) <- roots]
  where
    go _ _ [] = pure Nothing
    go seen budget ((m, parent, depth, onLead) : queue)
        | budget <= 0 = pure Nothing
        | m `Set.member` seen = go seen budget queue
        | otherwise = do
            Log.debug $ "Source: following re-export of " <> symbol <> " to " <> unModuleName m
            (mOrigin, result) <- lookupLocal dirs parent SourceQuery {moduleName = m, function = Just symbol}
            let seen' = Set.insert m seen
            case (result, mOrigin) of
                (SourceFound _ src, _) -> pure (Just (SourceReexported query m src))
                (FunctionNotFound _, Just mo)
                    | depth < limits.maxDepth ->
                        candidatesIn mo m >>= \case
                            Nothing -> pure Nothing
                            Just (namesIt, next) ->
                                -- A lead stays strong all the way down its chain.
                                let strong = onLead || namesIt
                                    leads = [(n, no, depth + 1, strong) | (n, no) <- next]
                                in  go seen' (budget - 1) (if strong then leads <> queue else queue <> leads)
                _ -> go seen' (budget - 1) queue

    -- The modules that may re-export the symbol to module @m@ (reached from
    -- @mo@), each paired with where @m@ was found as the parent to resolve it
    -- from, and whether @m@ names the symbol in its exports. 'Nothing' when @m@
    -- itself declares the symbol as a member of a local type or class.
    candidatesIn mo m =
        lookupLocal dirs mo SourceQuery {moduleName = m, function = Nothing} <&> \case
            (Just mo', SourceFound _ src)
                | declaresMember symbol src -> Nothing
                | otherwise -> Just (exportsByName symbol src, map (,mo') (reexportCandidates symbol src))
            _ -> Just (False, [])


-- | Resolve a module to its package, consulting the module -> package cache first.
resolvePackage
    :: ( Cache ModuleName PackageId :> es
       , GhcPkg :> es
       , Input Repl :> es
       , Log :> es
       )
    => ModuleName
    -> Eff es (Maybe PackageId)
resolvePackage modName = do
    mCachedPkg <- cacheLookup @ModuleName @PackageId modName
    case mCachedPkg of
        Just p -> do
            Log.debug $ "Source: " <> unModuleName modName <> " → " <> unPackageId p <> " (cached)"
            pure (Just p)
        Nothing -> do
            repl <- input
            result <- GhcPkg.findModule repl modName
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
            cacheResult $ maybe (SourceUnavailable query p) (fromModuleSource query) mModuleSrc
  where
    -- Cache a deterministic outcome so the fetch + read/slice cost is paid at
    -- most once per (package, query) within the cache window.
    cacheResult result = do
        cacheInsert @(PackageId, SourceQuery) @ModuleSourceResult (p, query) result
        pure result
