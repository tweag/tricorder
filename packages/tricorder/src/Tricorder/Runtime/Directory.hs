module Tricorder.Runtime.Directory
    ( Directory (..)
    , asReader
    , asReaderFor
    )
where

import Atelier.Effects.FileSystem (FileSystem)
import Effectful.Reader.Static (Reader)
import Numeric (showHex)
import System.FilePath ((</>))

import Atelier.Effects.FileSystem qualified as FileSystem
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))


newtype Directory = Directory {getDirectory :: FilePath}


asReader
    :: ( FileSystem :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Reader Directory : es) a -> Eff es a
asReader act = do
    ProjectRoot projectRoot <- Reader.ask
    dir <- FileSystem.getXdgRuntimeDir
    canonProjectRoot <- FileSystem.canonicalizePath projectRoot
    let projectDirHash = hashPath canonProjectRoot
        dir' = dir </> "tricorder" </> projectDirHash
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


-- | Polynomial hash of a file path, returned as a hex string.
hashPath :: FilePath -> String
hashPath path =
    let n = foldl' (\acc c -> acc * 31 + toInteger (ord c)) (0 :: Integer) path
    in  showHex (abs n `mod` (16 ^ (16 :: Integer))) ""
