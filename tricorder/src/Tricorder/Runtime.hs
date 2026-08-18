module Tricorder.Runtime
    ( PidFile (..)
    , runPidFile
    , ProjectRoot (..)
    , runProjectRoot
    , RuntimeDir (..)
    , runRuntimeDir
    , runRuntimeDirItem
    , SocketPath (..)
    , runSocketPath
    , LogPath (..)
    , runLogPath
    )
where

import Atelier.Effects.FileSystem
    ( FileSystem
    , canonicalizePath
    , createDirectoryIfMissing
    , getCurrentDirectory
    , getXdgRuntimeDir
    )
import Atelier.Effects.Posix.Daemons (PidFile (..))
import Effectful.Reader.Static (Reader, ask, runReader)
import Numeric (showHex)
import System.FilePath ((</>))


newtype SocketPath = SocketPath {getSocketPath :: FilePath}


runSocketPath
    :: (Reader RuntimeDir :> es)
    => Eff (Reader SocketPath : es) a
    -> Eff es a
runSocketPath = runRuntimeDirItem "socket.sock" SocketPath


newtype RuntimeDir = RuntimeDir {getRuntimeDir :: FilePath}


runRuntimeDir
    :: ( FileSystem :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Reader RuntimeDir : es) a -> Eff es a
runRuntimeDir act = do
    ProjectRoot projectRoot <- ask
    runtimeDir <- getXdgRuntimeDir
    canonProjectRoot <- canonicalizePath projectRoot
    let projectDirHash = hashPath canonProjectRoot
        dir = runtimeDir </> "tricorder" </> projectDirHash
    createDirectoryIfMissing True dir
    runReader (RuntimeDir dir) act


runRuntimeDirItem
    :: (Reader RuntimeDir :> es)
    => FilePath
    -- ^ Path segment to append to runtime dir.
    -> (FilePath -> a)
    -- ^ Constructor for the resulting type.
    -> Eff (Reader a : es) b
    -> Eff es b
runRuntimeDirItem path mk act = do
    RuntimeDir runtimeDir <- ask
    runReader (mk $ runtimeDir </> path) act


newtype ProjectRoot = ProjectRoot {getProjectRoot :: FilePath}


runProjectRoot
    :: (FileSystem :> es, HasCallStack)
    => Eff (Reader ProjectRoot : es) a -> Eff es a
runProjectRoot act = do
    projectRoot <- getCurrentDirectory
    runReader (ProjectRoot projectRoot) act


runPidFile :: (Reader RuntimeDir :> es) => Eff (Reader PidFile : es) a -> Eff es a
runPidFile = runRuntimeDirItem "daemon.pid" PidFile


newtype LogPath = LogPath {getLogPath :: FilePath}


runLogPath :: (Reader RuntimeDir :> es) => Eff (Reader LogPath : es) a -> Eff es a
runLogPath = runRuntimeDirItem "daemon.log" LogPath


-- | Polynomial hash of a file path, returned as a hex string.
hashPath :: FilePath -> String
hashPath path =
    let n = foldl' (\acc c -> acc * 31 + toInteger (ord c)) (0 :: Integer) path
    in  showHex (abs n `mod` (16 ^ (16 :: Integer))) ""
