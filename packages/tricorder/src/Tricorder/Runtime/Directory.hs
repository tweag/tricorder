module Tricorder.Runtime.Directory
    ( Directory (..)
    , asReader
    , asReaderFor
    )
where

import Atelier.Effects.FileSystem (FileSystem)
import Effectful.Reader.Static (Reader)
import System.FilePath ((</>))

import Atelier.Effects.FileSystem qualified as FileSystem
import Atelier.FileSystem.Path qualified as Path
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime.ProjectHash (ProjectHash (..))


newtype Directory = Directory {getDirectory :: FilePath}


asReader
    :: (FileSystem :> es, Reader ProjectHash :> es)
    => Eff (Reader Directory : es) a -> Eff es a
asReader act = do
    ProjectHash projectDirHash <- Reader.ask
    dir <- FileSystem.getXdgRuntimeDir
    let dir' = dir </> "tricorder" </> Path.toFilePath projectDirHash
    FileSystem.createDirectoryIfMissing True dir'
    Reader.runReader (Directory dir') act


asReaderFor
    :: (Reader Directory :> es)
    => FilePath
    -- ^ Path segment to append to runtime dir.
    -> (FilePath -> a)
    -- ^ Constructor for the resulting type.
    -> Eff (Reader a : es) b
    -> Eff es b
asReaderFor path mk act = do
    Directory dir <- Reader.ask
    Reader.runReader (mk $ dir </> path) act
