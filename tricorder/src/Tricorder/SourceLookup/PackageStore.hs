module Tricorder.SourceLookup.PackageStore
    ( PackageStore (..)
    , add
    , getPath
    , run
    ) where

import Atelier.Effects.Env (Env, getEnvironment)
import Atelier.Effects.FileSystem (FileSystem)
import Effectful (Effect)
import Effectful.Dispatch.Dynamic (interpretWith_)
import Effectful.NonDet (NonDet, OnEmptyPolicy (..), emptyEff, plusEff, runNonDet)
import Effectful.TH (makeEffect)
import System.FilePath (takeDirectory, (</>))

import Atelier.Effects.FileSystem qualified as FileSystem
import Data.Map.Strict qualified as Map

import Tricorder.Module (PackageId, splitPackageId, unPackageId)


data PackageStore :: Effect where
    Add :: PackageId -> ByteString -> PackageStore m FilePath
    GetPath :: PackageId -> PackageStore m (Maybe FilePath)


makeEffect ''PackageStore


run :: (Env :> es, FileSystem :> es) => Eff (PackageStore : es) a -> Eff es a
run act = do
    storeBaseDir <- findStoreBaseDir
    let packageDir = storeBaseDir </> "packages" </> hackageRepo
    FileSystem.createDirectoryIfMissing True packageDir
    interpretWith_ act \case
        Add packageId bytes -> do
            let path = packagePath packageDir packageId
            exists <- FileSystem.doesPathExist path
            unless exists do
                FileSystem.createDirectoryIfMissing True (takeDirectory path)
                FileSystem.writeFileBS path bytes
            pure path
        GetPath packageId -> do
            let path = packagePath packageDir packageId
            exists <- FileSystem.doesPathExist path
            if exists then
                pure $ Just path
            else
                pure Nothing


packagePath :: FilePath -> PackageId -> FilePath
packagePath packageDir packageId =
    packageDir
        </> toString packageName
        </> toString packageVersion
        </> toString (unPackageId packageId <> ".tar.gz")
  where
    (packageName, packageVersion) = splitPackageId packageId


hackageRepo :: FilePath
hackageRepo = "hackage.haskell.org"


findStoreBaseDir :: (Env :> es, FileSystem :> es) => Eff es FilePath
findStoreBaseDir = do
    env <- Map.fromList <$> getEnvironment
    fmap (fromMaybe tempFallback . rightToMaybe)
        $ runNonDet OnEmptyKeep
        $ findCabalDirCandidate env
            `plusEff` findXdgCandidate env
            `plusEff` findHomeCandidate env
            `plusEff` findFallback env


findCabalDirCandidate
    :: (FileSystem :> es, NonDet :> es)
    => Map String String -> Eff es FilePath
findCabalDirCandidate env =
    case Map.lookup "CABAL_DIR" env of
        Nothing -> emptyEff
        Just cabalDir -> getDir cabalDir


findXdgCandidate
    :: (FileSystem :> es, NonDet :> es)
    => Map String String -> Eff es FilePath
findXdgCandidate env =
    case Map.lookup "XDG_CACHE_HOME" env of
        Nothing -> emptyEff
        Just cacheHome -> getDir $ cacheHome </> "cabal"


findHomeCandidate
    :: (FileSystem :> es, NonDet :> es)
    => Map String String -> Eff es FilePath
findHomeCandidate env =
    case Map.lookup "HOME" env of
        Nothing -> emptyEff
        Just home -> do
            let cacheCandidate = home </> ".cache" </> "cabal"
                homeCandidate = home </> ".cabal"
            getDir cacheCandidate
                `plusEff` getDir homeCandidate


findFallback :: (NonDet :> es) => Map String String -> Eff es FilePath
findFallback env =
    findXdgFallback env
        `plusEff` findHomeFallback env


findXdgFallback :: (NonDet :> es) => Map String String -> Eff es FilePath
findXdgFallback env =
    case Map.lookup "XDG_CACHE_HOME" env of
        Nothing -> emptyEff
        Just cacheHome -> pure $ cacheHome </> "cabal"


findHomeFallback :: (NonDet :> es) => Map String String -> Eff es FilePath
findHomeFallback env =
    case Map.lookup "HOME" env of
        Nothing -> emptyEff
        Just home ->
            pure $ home </> ".cabal"


tempFallback :: FilePath
tempFallback = "/tmp/tricorder/packages"


getDir :: (FileSystem :> es, NonDet :> es) => FilePath -> Eff es FilePath
getDir fp = do
    exists <- FileSystem.doesDirectoryExist fp
    if exists then
        pure fp
    else
        emptyEff
