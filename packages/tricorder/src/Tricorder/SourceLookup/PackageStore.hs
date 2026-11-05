module Tricorder.SourceLookup.PackageStore
    ( PackageStore (..)
    , add
    , getPath
    , run
    )
where

import Atelier.Effects.Env (Env)
import Atelier.FileSystem.Path ((</>))
import Effectful (Effect)
import Effectful.Dispatch.Dynamic (interpretWith_)
import Effectful.Exception (trySync)
import Effectful.FileSystem (FileSystem)
import Effectful.NonDet (NonDet, OnEmptyPolicy (..), emptyEff, plusEff, runNonDet)
import Effectful.TH (makeEffect)
import Tricorder.SourceLookup.PackageId (PackageId (..), splitPackageId)

import Atelier.Effects.Env qualified as Env
import Atelier.FileSystem.Directory qualified as Directory
import Atelier.FileSystem.File qualified as File
import Atelier.FileSystem.Path qualified as Path
import Data.Map.Strict qualified as Map


data PackageStore :: Effect where
    Add :: PackageId -> ByteString -> PackageStore m (Either Text Path.Absolute)
    GetPath :: PackageId -> PackageStore m (Maybe Path.Absolute)


makeEffect ''PackageStore


run :: (Env :> es, FileSystem :> es) => Eff (PackageStore : es) a -> Eff es a
run act = do
    storeBaseDir <- findStoreBaseDir
    let packageDir = storeBaseDir </> Path.rel @"packages" </> hackageRepo
    Directory.createIfMissing True packageDir
    interpretWith_ act \case
        Add packageId bytes -> do
            let mPath = packagePath packageDir packageId
            case mPath of
                Nothing -> pure $ Left $ "Could not create a valid store path for package: " <> show packageId
                Just path -> do
                    exists <- Path.exists path
                    unless exists do
                        Directory.createIfMissing True (Path.takeDirectory path)
                        File.write path bytes
                    pure $ Right path
        GetPath packageId -> do
            let mPath = packagePath packageDir packageId
            case mPath of
                Nothing -> pure Nothing
                Just path -> do
                    exists <- Path.exists path
                    if exists
                        then pure $ Just path
                        else pure Nothing


packagePath :: Path.Absolute -> PackageId -> Maybe Path.Absolute
packagePath packageDir packageId =
    mkPackagePath
        <$> mkPath packageName
        <*> mkPath packageVersion
        <*> mkPath (packageId.unPackageId <> ".tar.gz")
  where
    mkPackagePath pn pv fn = packageDir </> pn </> pv </> fn
    (packageName, packageVersion) = splitPackageId packageId
    mkPath = rightToMaybe . Path.fromFilePath . toString


hackageRepo :: Path.Relative
hackageRepo = Path.rel @"hackage.haskell.org"


findStoreBaseDir :: (Env :> es, FileSystem :> es) => Eff es Path.Absolute
findStoreBaseDir = do
    env <- Map.fromList <$> Env.all
    fmap (fromMaybe tempFallback . rightToMaybe)
        $ runNonDet OnEmptyKeep
        $ findCabalDirCandidate env
            `plusEff` findXdgCandidate
            `plusEff` findHomeCandidate
            `plusEff` findFallback


findCabalDirCandidate
    :: (FileSystem :> es, NonDet :> es)
    => Map String String -> Eff es Path.Absolute
findCabalDirCandidate env =
    case Map.lookup "CABAL_DIR" env of
        Nothing -> emptyEff
        Just cabalDir -> getDir =<< toPath cabalDir


findXdgCandidate
    :: (FileSystem :> es, NonDet :> es)
    => Eff es Path.Absolute
findXdgCandidate = do
    trySync (Directory.getXdg Directory.XdgCache (Path.rel @"cabal")) >>= \case
        Left _ -> emptyEff
        Right dir -> getDir dir


findHomeCandidate :: (FileSystem :> es, NonDet :> es) => Eff es Path.Absolute
findHomeCandidate = do
    trySync Directory.getHome >>= \case
        Left _ -> emptyEff
        Right home -> do
            let cacheCandidate = home </> Path.rel @".cache" </> Path.rel @"cabal"
                homeCandidate = home </> Path.rel @".cabal"
            getDir cacheCandidate
                `plusEff` getDir homeCandidate


findFallback :: (FileSystem :> es, NonDet :> es) => Eff es Path.Absolute
findFallback = findXdgFallback `plusEff` findHomeFallback


findXdgFallback :: (FileSystem :> es, NonDet :> es) => Eff es Path.Absolute
findXdgFallback = do
    trySync (Directory.getXdg Directory.XdgCache $ Path.rel @"cabal") >>= \case
        Left _ -> emptyEff
        Right dir -> pure dir


findHomeFallback :: (FileSystem :> es, NonDet :> es) => Eff es Path.Absolute
findHomeFallback = do
    trySync Directory.getHome >>= \case
        Left _ -> emptyEff
        Right home -> pure $ home </> Path.rel @".cabal"


tempFallback :: Path.Absolute
tempFallback = Path.absolute @"/tmp/tricorder/packages"


getDir :: (FileSystem :> es, NonDet :> es) => Path.Absolute -> Eff es Path.Absolute
getDir fp = do
    exists <- Directory.exists fp
    if exists
        then pure fp
        else emptyEff


toPath :: (NonDet :> es) => FilePath -> Eff es Path.Absolute
toPath fp =
    case Path.fromFilePath fp of
        Left _ -> emptyEff
        Right d -> pure d
