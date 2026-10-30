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
    , logPathEnv
    )
where

import Atelier.Effects.Env (Env)
import Atelier.Effects.FileSystem
    ( FileSystem
    , canonicalizePath
    , createDirectoryIfMissing
    , getCurrentDirectory
    , getXdgRuntimeDir
    , listDirectory
    )
import Atelier.Effects.Posix.Daemons (PidFile (..))
import Effectful.Reader.Static (Reader, ask, runReader)
import Numeric (showHex)
import System.FilePath (takeDirectory, takeExtension, (</>))

import Atelier.Effects.Env qualified as Env
import Effectful.Reader.Static qualified as Reader


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
    cwd <- getCurrentDirectory
    projectRoot <- fromMaybe cwd <$> findProjectRoot cwd
    runReader (ProjectRoot projectRoot) act


findProjectRoot :: (FileSystem :> es) => FilePath -> Eff es (Maybe FilePath)
findProjectRoot dir = do
    files <- listDirectory dir
    let parent = takeDirectory dir
    if any isRootMarker files
        then pure (Just dir)
        else
            if parent == dir
                then pure Nothing
                else findProjectRoot parent


isRootMarker :: FilePath -> Bool
isRootMarker f =
    takeExtension f == ".cabal"
        || f `elem` ["cabal.project", "cabal.project.freeze", "cabal.project.local", "stack.yaml"]


runPidFile :: (Reader RuntimeDir :> es) => Eff (Reader PidFile : es) a -> Eff es a
runPidFile = runRuntimeDirItem "daemon.pid" PidFile


newtype LogPath = LogPath {getLogPath :: FilePath}


logPathEnv :: String
logPathEnv = "TRICORDER_LOG_PATH"


runLogPath :: (Env :> es, Reader RuntimeDir :> es) => Eff (Reader LogPath : es) a -> Eff es a
runLogPath act = do
    mLogPath <- Env.lookup logPathEnv
    case mLogPath of
        Just logPath -> Reader.runReader (LogPath logPath) act
        Nothing -> runRuntimeDirItem "daemon.log" LogPath act


-- | Polynomial hash of a file path, returned as a hex string.
hashPath :: FilePath -> String
hashPath path =
    let n = foldl' (\acc c -> acc * 31 + toInteger (ord c)) (0 :: Integer) path
    in  showHex (abs n `mod` (16 ^ (16 :: Integer))) ""
