{-# LANGUAGE UndecidableInstances #-}

-- |
-- Module      : Atelier.FileSystem.SymbolicLink
-- Description : File system operations on symbolic links using the path types
--               from "Atelier.FileSystem.Path".
-- Copyright   : (c) <Tweag> 2026
-- License     : MIT
-- Maintainer  : <victor.bakke@tweag.io>
--
-- Functions on symbolic links from "Effectful.FileSystem" lifted for use with
-- "Atelier.FileSystem.Path" paths.
module Atelier.FileSystem.SymbolicLink
    ( -- * Actions on symbolic links
      Actions
    , create
    , remove
    , exists
    , getTarget
    )
where

import Effectful (Effect)
import Effectful.FileSystem (FileSystem)
import Prelude hiding (Any (..))

import Effectful.FileSystem qualified as FileSystem
import System.FilePath qualified as Path

import Atelier.FileSystem.Path.Internal
    ( Absolute (..)
    , Any (..)
    , Relative (..)
    , SafePath (..)
    , UnsafePath (..)
    )


class Actions (es :: [Effect]) path where
    -- | Lifted 'Effectful.FileSystem.createFileLink'.
    create :: path -> path -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.removeFile'.
    remove :: path -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.pathIsSymbolicLink'.
    exists :: path -> Eff es Bool


    -- | Lifted 'Effectful.FileSystem.getSymbolicLinkTarget'.
    getTarget :: path -> Eff es Any


instance (FileSystem :> es, UnsafePath path) => Actions es (SafePath path) where
    create = FileSystem.createFileLink `on` (unsafeFromPath . getSafePath)
    remove = FileSystem.removeFile . unsafeFromPath . getSafePath
    exists = FileSystem.pathIsSymbolicLink . unsafeFromPath . getSafePath
    getTarget = getSymbolicTarget . unsafeFromPath . getSafePath


deriving via (SafePath Absolute) instance (FileSystem :> es) => Actions es Absolute


deriving via (SafePath Relative) instance (FileSystem :> es) => Actions es Relative


deriving via (SafePath Any) instance (FileSystem :> es) => Actions es Any


getSymbolicTarget :: (FileSystem :> es) => FilePath -> Eff es Any
getSymbolicTarget path = do
    target <- FileSystem.getSymbolicLinkTarget path
    pure
        $ if Path.isRelative target
            then Relative $ UnsafeMkRelative path
            else Absolute $ UnsafeMkAbsolute path
