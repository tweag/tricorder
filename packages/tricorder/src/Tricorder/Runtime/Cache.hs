module Tricorder.Runtime.Cache
    ( Cache (..)
    , asReader
    )
where

import Atelier.Effects.Env (Env)
import Atelier.Effects.Exit (Exit)
import Atelier.FileSystem.Path ((</>))
import Atelier.FileSystem.Permissions (Permissions (..))
import Data.Aeson (FromJSON, ToJSON)
import Effectful.Exception (trySync)
import Effectful.FileSystem (FileSystem)
import Effectful.Reader.Static (Reader)

import Atelier.Effects.Env qualified as Env
import Atelier.Effects.Exit qualified as Exit
import Atelier.FileSystem.Directory qualified as Directory
import Atelier.FileSystem.Path qualified as Path
import Atelier.FileSystem.Permissions qualified as Permissions
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime.ProjectHash (ProjectHash (..))


newtype Cache = Cache {getCache :: Path.Absolute}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Path.Absolute


envName :: String
envName = "TRICORDER_CACHE_DIR"


asReader
    :: (Env :> es, Exit :> es, FileSystem :> es, Reader ProjectHash :> es)
    => Eff (Reader Cache : es) a -> Eff es a
asReader act = do
    mCachePath <- Env.lookup envName
    case mCachePath of
        Just cachePath
            | Right path <- Path.fromFilePath cachePath ->
                Reader.runReader (Cache path) act
        _ -> do
            ProjectHash projectHash <- Reader.ask
            dir <- Directory.getXdg Directory.XdgCache $ Path.rel @"tricorder" </> projectHash
            mDir <- mkUsable dir
            case mDir of
                Nothing -> Exit.with $ Exit.ExitFailure 255
                Just d -> Reader.runReader (Cache d) act


mkUsable :: (FileSystem :> es) => Path.Absolute -> Eff es (Maybe Path.Absolute)
mkUsable path =
    fmap (either (const Nothing) Just) $ trySync do
        Directory.createIfMissing True path
        permissions <- Permissions.get path
        unless (Permissions.writable permissions) do
            Permissions.set path $ permissions {writable = True}
        pure path
