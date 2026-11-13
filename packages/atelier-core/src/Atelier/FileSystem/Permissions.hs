{-# LANGUAGE UndecidableInstances #-}

-- |
-- Module      : Atelier.FileSystem.Permissions
-- Description : File system operations on permissions using the path types
--               from "Atelier.FileSystem.Path".
-- Copyright   : (c) <Tweag> 2026
-- License     : MIT
-- Maintainer  : <victor.bakke@tweag.io>
-- Portability : non-portable (requires POSIX)
--
-- Permission functions from "Effectful.FileSystem" tailored for use with
-- "Atelier.FileSystem.Path" paths.
module Atelier.FileSystem.Permissions
    ( Actions
    , get
    , set
    , copy

      -- ** Reexports
    , Reexports.Permissions (..)
    , Reexports.emptyPermissions
    , Reexports.setOwnerReadable
    , Reexports.setOwnerWritable
    , Reexports.setOwnerExecutable
    , Reexports.setOwnerSearchable
    )
where

import Effectful (Effect)
import Effectful.FileSystem (FileSystem, Permissions)
import Prelude hiding (Any (..))

import Effectful.FileSystem qualified as FileSystem
import Effectful.FileSystem qualified as Reexports

import Atelier.FileSystem.Path.Internal (Absolute, Any, Relative, SafePath (..), UnsafePath (..))


class Actions (es :: [Effect]) path where
    -- | Lifted 'Effectful.FileSystem.getPermissions'.
    get :: path -> Eff es Permissions


    -- | Lifted 'Effectful.FileSystem.setPermissions'.
    set :: path -> Permissions -> Eff es ()


    -- | Lifted 'Effectful.FileSystem.copyPermissions'.
    copy :: path -> path -> Eff es ()


instance (FileSystem :> es, UnsafePath path) => Actions es (SafePath path) where
    get (SafePath path) = FileSystem.getPermissions $ unsafeFromPath path
    set (SafePath path) permissions = FileSystem.setPermissions (unsafeFromPath path) permissions
    copy (SafePath from) (SafePath to) = FileSystem.copyPermissions (unsafeFromPath from) (unsafeFromPath to)


deriving via SafePath Absolute instance (FileSystem :> es) => Actions es Absolute


deriving via SafePath Relative instance (FileSystem :> es) => Actions es Relative


deriving via SafePath Any instance (FileSystem :> es) => Actions es Any
