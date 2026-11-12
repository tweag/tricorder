{-# LANGUAGE UndecidableInstances #-}

-- |
-- Module      : Atelier.FileSystem.File
-- Description : File system operations on files using the path types from
--               "Atelier.FileSystem.Path".
-- Copyright   : (c) <Tweag> 2026
-- License     : MIT
-- Maintainer  : <victor.bakke@tweag.io>
--
-- Functions on files from "Effectful.FileSystem" lifted for use with
-- "Atelier.FileSystem.Path" paths.
module Atelier.FileSystem.File
    ( -- * Actions on files
      Actions
    , exists
    , remove
    , rename
    , copy
    , copyWithMetadata
    , getSize

      -- * Timestamps
    , getAccessTime
    , setAccessTime
    , getModificationTime
    , setModificationTime

      -- * File contents
    , ReadFile (..)
    , WriteFile (..)
    )
where

import Data.Time (UTCTime)
import Effectful.Dispatch.Static (StaticRep, getStaticRep, unsafeEff_)
import Effectful.FileSystem (FileSystem)
import Prelude hiding (Any (..))

import Data.ByteString.Char8 qualified as B8
import Data.ByteString.Lazy.Char8 qualified as BL8
import Data.Text.IO qualified as Text.IO
import Effectful.FileSystem qualified as FileSystem
import System.IO qualified as IO

import Atelier.FileSystem.Path.Internal
    ( Absolute (..)
    , Any (..)
    , Relative (..)
    , SafePath (..)
    , UnsafePath (..)
    , unsafeFromPath
    )


class Actions es path where
    -- | Lifted 'Effectful.FileSystem.doesFileExist'.
    exists :: path -> Eff es Bool


    -- | Lifted 'Effectful.FileSystem.removeFile'.
    remove :: path -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.renameFile'.
    rename :: path -> path -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.copyFile'.
    copy :: path -> path -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.copyFileWithMetadata'.
    copyWithMetadata :: path -> path -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.getFileSize'.
    getSize :: path -> Eff es Integer


    -- | Lifted 'Effectful.FileSystem.getAccessTime'.
    getAccessTime :: path -> Eff es UTCTime


    -- | Lifted 'Effectful.FileSystem.setAccessTime'.
    setAccessTime :: path -> UTCTime -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.getModificationTime'.
    getModificationTime :: path -> Eff es UTCTime


    -- | Lifted 'Effectful.FileSystem.setModificationTime'.
    setModificationTime :: path -> UTCTime -> Eff es ()


instance (FileSystem :> es) => Actions es Absolute where
    exists = FileSystem.doesFileExist . unsafeGetAbsolute
    remove = FileSystem.removeFile . unsafeGetAbsolute
    rename = FileSystem.renameFile `on` unsafeGetAbsolute
    copy = FileSystem.copyFile `on` unsafeGetAbsolute
    copyWithMetadata = FileSystem.copyFileWithMetadata `on` unsafeGetAbsolute
    getSize = FileSystem.getFileSize . unsafeGetAbsolute
    getAccessTime = FileSystem.getAccessTime . unsafeGetAbsolute
    setAccessTime = FileSystem.setAccessTime . unsafeGetAbsolute
    getModificationTime = FileSystem.getModificationTime . unsafeGetAbsolute
    setModificationTime = FileSystem.setModificationTime . unsafeGetAbsolute


instance (FileSystem :> es) => Actions es Relative where
    exists = FileSystem.doesFileExist . unsafeGetRelative
    remove = FileSystem.removeFile . unsafeGetRelative
    rename = FileSystem.renameFile `on` unsafeGetRelative
    copy = FileSystem.copyFile `on` unsafeGetRelative
    copyWithMetadata = FileSystem.copyFileWithMetadata `on` unsafeGetRelative
    getSize = FileSystem.getFileSize . unsafeGetRelative
    getAccessTime = FileSystem.getAccessTime . unsafeGetRelative
    setAccessTime = FileSystem.setAccessTime . unsafeGetRelative
    getModificationTime = FileSystem.getModificationTime . unsafeGetRelative
    setModificationTime = FileSystem.setModificationTime . unsafeGetRelative


class ReadFile es output path where
    -- | 'IO.writeFile' for various formats and 'Absolute' and 'Relative'
    -- paths.
    read :: path -> Eff es output


instance (FileSystem :> es, UnsafePath path) => ReadFile es LByteString (SafePath path) where
    read (SafePath path) = do
        _ :: StaticRep FileSystem <- getStaticRep
        unsafeEff_ $ BL8.readFile $ unsafeFromPath path


instance (FileSystem :> es, UnsafePath path) => ReadFile es ByteString (SafePath path) where
    read (SafePath path) = do
        _ :: StaticRep FileSystem <- getStaticRep
        unsafeEff_ $ B8.readFile $ unsafeFromPath path


instance (FileSystem :> es, UnsafePath path) => ReadFile es String (SafePath path) where
    read (SafePath path) = do
        _ :: StaticRep FileSystem <- getStaticRep
        unsafeEff_ $ IO.readFile $ unsafeFromPath path


instance (FileSystem :> es, UnsafePath path) => ReadFile es Text (SafePath path) where
    read (SafePath path) = do
        _ :: StaticRep FileSystem <- getStaticRep
        unsafeEff_ $ Text.IO.readFile $ unsafeFromPath path


deriving via (SafePath Absolute) instance (FileSystem :> es) => ReadFile es LByteString Absolute


deriving via (SafePath Absolute) instance (FileSystem :> es) => ReadFile es ByteString Absolute


deriving via (SafePath Absolute) instance (FileSystem :> es) => ReadFile es Text Absolute


deriving via (SafePath Absolute) instance (FileSystem :> es) => ReadFile es String Absolute


deriving via (SafePath Relative) instance (FileSystem :> es) => ReadFile es LByteString Relative


deriving via (SafePath Relative) instance (FileSystem :> es) => ReadFile es ByteString Relative


deriving via (SafePath Relative) instance (FileSystem :> es) => ReadFile es Text Relative


deriving via (SafePath Relative) instance (FileSystem :> es) => ReadFile es String Relative


deriving via (SafePath Any) instance (FileSystem :> es) => ReadFile es LByteString Any


deriving via (SafePath Any) instance (FileSystem :> es) => ReadFile es ByteString Any


deriving via (SafePath Any) instance (FileSystem :> es) => ReadFile es Text Any


deriving via (SafePath Any) instance (FileSystem :> es) => ReadFile es String Any


class WriteFile es input path where
    -- | 'IO.writeFile' for various input types and "Atelier.FileSystem.Path"
    -- paths.
    write :: path -> input -> Eff es ()


instance (FileSystem :> es, UnsafePath path) => WriteFile es LByteString (SafePath path) where
    write (SafePath path) input = do
        _ :: StaticRep FileSystem <- getStaticRep
        unsafeEff_ $ BL8.writeFile (unsafeFromPath path) input


instance (FileSystem :> es, UnsafePath path) => WriteFile es ByteString (SafePath path) where
    write (SafePath path) input = do
        _ :: StaticRep FileSystem <- getStaticRep
        unsafeEff_ $ B8.writeFile (unsafeFromPath path) input


instance (FileSystem :> es, UnsafePath path) => WriteFile es String (SafePath path) where
    write (SafePath path) input = do
        _ :: StaticRep FileSystem <- getStaticRep
        unsafeEff_ $ IO.writeFile (unsafeFromPath path) input


instance (FileSystem :> es, UnsafePath path) => WriteFile es Text (SafePath path) where
    write (SafePath path) input = do
        _ :: StaticRep FileSystem <- getStaticRep
        unsafeEff_ $ Text.IO.writeFile (unsafeFromPath path) input


deriving via (SafePath Absolute) instance (FileSystem :> es) => WriteFile es LByteString Absolute


deriving via (SafePath Absolute) instance (FileSystem :> es) => WriteFile es ByteString Absolute


deriving via (SafePath Absolute) instance (FileSystem :> es) => WriteFile es Text Absolute


deriving via (SafePath Absolute) instance (FileSystem :> es) => WriteFile es String Absolute


deriving via (SafePath Relative) instance (FileSystem :> es) => WriteFile es LByteString Relative


deriving via (SafePath Relative) instance (FileSystem :> es) => WriteFile es ByteString Relative


deriving via (SafePath Relative) instance (FileSystem :> es) => WriteFile es Text Relative


deriving via (SafePath Relative) instance (FileSystem :> es) => WriteFile es String Relative


deriving via (SafePath Any) instance (FileSystem :> es) => WriteFile es LByteString Any


deriving via (SafePath Any) instance (FileSystem :> es) => WriteFile es ByteString Any


deriving via (SafePath Any) instance (FileSystem :> es) => WriteFile es Text Any


deriving via (SafePath Any) instance (FileSystem :> es) => WriteFile es String Any
