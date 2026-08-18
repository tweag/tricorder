-- | An effect for filesystem operations: reading files, listing and creating
-- directories, and querying paths.
--
-- 'runFileSystemIO' performs real filesystem IO; 'runFileSystemNoOp' returns
-- inert results; and 'runFileSystemState' simulates a filesystem backed by an
-- in-memory 'Map' for tests. 'followFile' tails a file as it grows.
module Atelier.Effects.FileSystem
    ( FileSystem (..)
    , readFileBs
    , readFileLbsFrom
    , readFileLbs
    , followFile
    , doesFileExist
    , doesPathExist
    , doesDirectoryExist
    , listDirectory
    , createDirectoryIfMissing
    , removeFile
    , writeFileBS
    , writeFileLBS
    , canonicalizePath
    , getCurrentDirectory
    , getXdgRuntimeDir
    , runFileSystemIO
    , runFileSystemNoOp
    , runFileSystemState
    )
where

import Control.Exception (bracket)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.Exception (throwIO)
import Effectful.State.Static.Shared (State, gets, modify)
import Effectful.TH (makeEffect)
import System.Environment (lookupEnv)
import System.IO.Error (userError)
import System.Posix.Types (COff (..), FileOffset)

import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as LBS
import Data.Map.Strict qualified as M
import System.Directory qualified as Dir
import System.Posix.IO qualified as Posix

import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Posix.IO (readFdFrom)
import Atelier.Time (Millisecond)

import Atelier.Effects.Delay qualified as Delay


-- | Effect for filesystem access.
data FileSystem :: Effect where
    -- | Read a file's full contents strictly.
    ReadFileBs :: FilePath -> FileSystem m ByteString
    -- | Read a file from the given byte offset to the end, lazily.
    ReadFileLbsFrom :: FilePath -> FileOffset -> FileSystem m LByteString
    -- | Does a regular file exist at the path?
    DoesFileExist :: FilePath -> FileSystem m Bool
    -- | Does anything (file or directory) exist at the path?
    DoesPathExist :: FilePath -> FileSystem m Bool
    -- | Does a directory exist at the path?
    DoesDirectoryExist :: FilePath -> FileSystem m Bool
    -- | List the entries of a directory.
    ListDirectory :: FilePath -> FileSystem m [FilePath]
    -- | Create a directory. The 'Bool' requests creation of missing parents.
    CreateDirectoryIfMissing :: Bool -> FilePath -> FileSystem m ()
    -- | Delete a file.
    RemoveFile :: FilePath -> FileSystem m ()
    -- | Write a 'ByteString' to a file path.
    WriteFileBS :: FilePath -> ByteString -> FileSystem m ()
    -- | Write a (lazy) 'LByteString' to a file path.
    WriteFileLBS :: FilePath -> LByteString -> FileSystem m ()
    -- | Resolve a path to a canonical, absolute form.
    CanonicalizePath :: FilePath -> FileSystem m FilePath
    -- | The process's current working directory.
    GetCurrentDirectory :: FileSystem m FilePath
    -- | The XDG runtime directory (@$XDG_RUNTIME_DIR@), falling back to @\/tmp@.
    GetXdgRuntimeDir :: FileSystem m FilePath


makeEffect ''FileSystem


-- | Read a file's full contents lazily (equivalent to reading from offset 0).
readFileLbs :: (FileSystem :> es) => FilePath -> Eff es LByteString
readFileLbs path = readFileLbsFrom path 0


-- | Follow a file as it grows, calling @onChunk@ with each new chunk of
-- content. Polls every 200ms. Does not return.
followFile
    :: (Delay :> es, FileSystem :> es)
    => FilePath
    -> (ByteString -> Eff es ())
    -> Eff es a
followFile path onChunk = go 0
  where
    go offset = do
        newContent <- readFileLbsFrom path offset
        if LBS.null newContent then pure () else onChunk (LBS.toStrict newContent)
        Delay.wait (200 :: Millisecond)
        go (offset + fromIntegral (LBS.length newContent))


-- | Interpret 'FileSystem' against the real filesystem.
runFileSystemIO :: (IOE :> es) => Eff (FileSystem : es) a -> Eff es a
runFileSystemIO = interpret_ $ \case
    ReadFileBs path -> liftIO $ BS.readFile path
    ReadFileLbsFrom path offset ->
        liftIO
            $ bracket
                (Posix.openFd path Posix.ReadOnly Posix.defaultFileFlags)
                Posix.closeFd
                (readFdFrom offset)
    DoesFileExist path -> liftIO $ Dir.doesFileExist path
    DoesPathExist path -> liftIO $ Dir.doesPathExist path
    DoesDirectoryExist path -> liftIO $ Dir.doesDirectoryExist path
    ListDirectory path -> liftIO $ Dir.listDirectory path
    CreateDirectoryIfMissing p path -> liftIO $ Dir.createDirectoryIfMissing p path
    RemoveFile path -> liftIO $ Dir.removeFile path
    WriteFileBS path bytes -> liftIO $ BS.writeFile path bytes
    WriteFileLBS path bytes -> liftIO $ LBS.writeFile path bytes
    CanonicalizePath path -> liftIO $ Dir.canonicalizePath path
    GetCurrentDirectory -> liftIO Dir.getCurrentDirectory
    GetXdgRuntimeDir -> liftIO $ fromMaybe "/tmp" <$> lookupEnv "XDG_RUNTIME_DIR"


-- | Interpret 'FileSystem' with inert results: reads return empty, existence
-- checks return 'False', and mutations do nothing. Useful for tests.
runFileSystemNoOp :: Eff (FileSystem : es) a -> Eff es a
runFileSystemNoOp = interpret_ $ \case
    ReadFileBs _ -> pure mempty
    ReadFileLbsFrom _ _ -> pure mempty
    DoesFileExist _ -> pure False
    DoesPathExist _ -> pure False
    DoesDirectoryExist _ -> pure False
    ListDirectory _ -> pure []
    CreateDirectoryIfMissing _ _ -> pure ()
    RemoveFile _ -> pure ()
    WriteFileBS _ _ -> pure ()
    WriteFileLBS _ _ -> pure ()
    CanonicalizePath path -> pure path
    GetCurrentDirectory -> pure "."
    GetXdgRuntimeDir -> pure "/tmp"


-- | Run `FileSystem` effect backed by a `State` effect with a `Map`. The keys
-- of the `Map` are treated as file names. Only the `dirname` of files are
-- counted as existing directories.
runFileSystemState
    :: (State (Map FilePath ByteString) :> es)
    => Eff (FileSystem : es) a -> Eff es a
runFileSystemState = interpret_ \case
    ReadFileBs fp ->
        maybe (throwIO $ userError "No such file") pure
            =<< gets (M.lookup fp)
    ReadFileLbsFrom fp (COff offset) -> do
        contents <-
            maybe (throwIO $ userError "No such file") pure
                =<< gets (M.lookup fp)
        pure
            . toLazy
            . BS.drop (fromIntegral offset)
            $ contents
    DoesFileExist fp -> gets $ M.member fp
    DoesPathExist fp -> gets $ any (\p -> fp `isPrefixOf` p && fp /= p) . M.keys
    DoesDirectoryExist fp -> gets $ any (\p -> fp `isPrefixOf` p) . M.keys
    ListDirectory fp -> gets $ filter (\p -> fp `isPrefixOf` p && fp /= p) . M.keys
    CreateDirectoryIfMissing _ _ -> pure ()
    RemoveFile fp -> modify $ M.delete fp
    WriteFileBS fp bytes -> modify $ M.insert fp bytes
    WriteFileLBS fp bytes -> modify $ M.insert fp $ toStrict bytes
    CanonicalizePath fp -> pure fp
    GetCurrentDirectory -> pure "/"
    GetXdgRuntimeDir -> pure "/tmp"
