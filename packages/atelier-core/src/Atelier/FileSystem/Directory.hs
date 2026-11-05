{-# LANGUAGE UndecidableInstances #-}

-- |
-- Module      : Atelier.FileSystem.Directory
-- Description : File system operations on directories using the path types
--               from "Atelier.FileSystem.Path".
-- Copyright   : (c) <Tweag> 2026
-- License     : MIT
-- Maintainer  : <victor.bakke@tweag.io>
--
-- Functions on directories from "Effectful.FileSystem" lifted for use with
-- "Atelier.FileSystem.Path" paths.
module Atelier.FileSystem.Directory
    ( -- * Actions on directories
      Actions
    , exists
    , create
    , createIfMissing
    , remove
    , removeRecursive
    , rename
    , list
    , getContents

      -- * Pre-defined directories
    , getHome
    , XdgDirectory (..)
    , getXdg
    , XdgDirectoryList (..)
    , getXdgList
    , getAppUserData
    , getUserDocuments
    , getTemporary

      -- * Current working directory
    , getCurrent
    , setCurrent
    , withCurrent
    )
where

import Effectful.FileSystem (FileSystem, XdgDirectory, XdgDirectoryList)
import Prelude hiding (Any (..))

import Effectful.FileSystem qualified as FileSystem

import Atelier.FileSystem.Path.Internal
    ( Absolute (..)
    , Any (..)
    , Relative (..)
    , SafePath (..)
    , UnsafePath (..)
    )


class Actions es path where
    -- | Lifted 'Effectful.FileSystem.doesDirectoryExist'.
    exists :: path -> Eff es Bool


    -- | Lifted 'Effectful.FileSystem.createDirectory'.
    create :: path -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.createDirectoryIfMissing'.
    createIfMissing :: Bool -> path -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.removeDirectory'.
    remove :: path -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.removeDirectoryRecursive'.
    removeRecursive :: path -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.renameDirectory'.
    rename :: path -> path -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.listDirectory'.
    list :: path -> Eff es [Relative]


    -- | Lifted 'Effectful.FileSystem.getDirectoryContents'.
    getContents :: path -> Eff es [Relative]


    -- | Lifted 'Effectful.FileSystem.setCurrentDirectory'.
    setCurrent :: path -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.withCurrentDirectory'.
    withCurrent :: path -> Eff es a -> Eff es a


instance (FileSystem :> es, UnsafePath path) => Actions es (SafePath path) where
    create = FileSystem.createDirectory . unsafeFromPath . getSafePath
    createIfMissing createParents = FileSystem.createDirectoryIfMissing createParents . unsafeFromPath . getSafePath
    remove = FileSystem.removeDirectory . unsafeFromPath . getSafePath
    removeRecursive = FileSystem.removeDirectoryRecursive . unsafeFromPath . getSafePath
    rename = FileSystem.renameDirectory `on` (unsafeFromPath . getSafePath)
    list = fmap (fmap UnsafeMkRelative) . FileSystem.listDirectory . unsafeFromPath . getSafePath
    getContents = fmap (fmap UnsafeMkRelative) . FileSystem.getDirectoryContents . unsafeFromPath . getSafePath
    setCurrent = FileSystem.setCurrentDirectory . unsafeFromPath . getSafePath
    withCurrent = FileSystem.withCurrentDirectory . unsafeFromPath . getSafePath
    exists = FileSystem.doesDirectoryExist . unsafeFromPath . getSafePath


deriving via (SafePath Absolute) instance (FileSystem :> es) => Actions es Absolute


deriving via (SafePath Relative) instance (FileSystem :> es) => Actions es Relative


deriving via (SafePath Any) instance (FileSystem :> es) => Actions es Any


-- | Lifted 'Effectful.FileSystem.getHomeDirectory'.
getHome :: (FileSystem :> es) => Eff es Absolute
getHome = UnsafeMkAbsolute <$> FileSystem.getHomeDirectory


-- | Lifted 'Effectful.FileSystem.getXdgDirectory'.
getXdg :: (FileSystem :> es) => XdgDirectory -> Relative -> Eff es Absolute
getXdg xdgDirectory (UnsafeMkRelative path) =
    UnsafeMkAbsolute <$> FileSystem.getXdgDirectory xdgDirectory path


-- | Lifted 'Effectful.FileSystem.getXdgDirectoryList'.
getXdgList :: (FileSystem :> es) => XdgDirectoryList -> Eff es [Absolute]
getXdgList = fmap (fmap UnsafeMkAbsolute) . FileSystem.getXdgDirectoryList


-- | Lifted 'Effectful.FileSystem.getAppUserDataDirectory'.
getAppUserData :: (FileSystem :> es) => Relative -> Eff es Absolute
getAppUserData = fmap UnsafeMkAbsolute . FileSystem.getAppUserDataDirectory . unsafeGetRelative


-- | Lifted 'Effectful.FileSystem.getUserDocumentsDirectory'.
getUserDocuments :: (FileSystem :> es) => Eff es Absolute
getUserDocuments = UnsafeMkAbsolute <$> FileSystem.getUserDocumentsDirectory


-- | Lifted 'Effectful.FileSystem.getTemporaryDirectory'.
getTemporary :: (FileSystem :> es) => Eff es Absolute
getTemporary = UnsafeMkAbsolute <$> FileSystem.getTemporaryDirectory


-- | Lifted 'Effectful.FileSystem.getCurrentDirectory'.
getCurrent :: (FileSystem :> es) => Eff es Absolute
getCurrent = UnsafeMkAbsolute <$> FileSystem.getCurrentDirectory
