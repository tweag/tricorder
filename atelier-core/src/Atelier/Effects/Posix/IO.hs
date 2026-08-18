-- |
--
-- GHC's 'System.IO.openFile' and 'System.IO.withFile' participate in an
-- advisory file-locking protocol built on @flock(2)@:
--
--   * Write\/append mode acquires an exclusive lock (@LOCK_EX@).
--   * Read mode acquires a shared lock (@LOCK_SH@).
--
-- Because these locks are advisory, processes that do not call @flock@ can
-- always read or write the file freely. GHC's own runtime, however, refuses
-- to open a file for reading while another GHC process holds an exclusive
-- lock on it — even if the underlying read would be perfectly safe - and
-- throws @resource busy (file is locked)@.
--
-- This is a problem when a long-lived daemon holds a file open in append mode
-- and a short-lived client process wants to read that file. Using 'readFdAll',
-- the client opens the file via @open(2)@ without ever calling @flock@,
-- matching the behaviour of standard Unix tools like @cat@ and @tail@.
module Atelier.Effects.Posix.IO
    ( readFdAll
    , readFdFrom
    )
where

import Foreign.Marshal.Alloc (allocaBytes)
import Foreign.Ptr (castPtr)
import System.IO (SeekMode (..))
import System.Posix.Types (Fd, FileOffset)

import Data.ByteString qualified as BS
import Data.ByteString.Builder qualified as Builder
import Data.ByteString.Lazy qualified as LBS
import System.Posix.IO qualified as Posix


-- | Read the entire contents of a file descriptor into a lazy 'LBS.ByteString'
-- without acquiring any file lock.
--
-- The file is read in chunks via @read(2)@ (@'Posix.fdReadBuf'@) until EOF.
-- The caller retains ownership of the 'Fd' and is responsible for closing it;
-- this function does not close the descriptor after reading.
--
-- Typical use via 'Control.Exception.bracket':
--
-- @
-- result <- bracket
--     (Posix.openFd path Posix.ReadOnly Posix.defaultFileFlags)
--     Posix.closeFd
--     readFdAll
-- @
readFdAll :: Fd -> IO LBS.ByteString
readFdAll fd = Builder.toLazyByteString <$> go mempty
  where
    chunkSize = 65536 :: Int
    go acc = do
        chunk <- allocaBytes chunkSize \ptr -> do
            n <- Posix.fdReadBuf fd (castPtr ptr) (fromIntegral chunkSize)
            BS.packCStringLen (castPtr ptr, fromIntegral n)
        if BS.null chunk
            then
                return acc
            else
                go (acc <> Builder.byteString chunk)


-- | Seek to @offset@ and read the remainder of a file descriptor into a lazy
-- 'LBS.ByteString' without acquiring any file lock.
readFdFrom :: FileOffset -> Fd -> IO LBS.ByteString
readFdFrom offset fd = do
    _ <- Posix.fdSeek fd AbsoluteSeek offset
    readFdAll fd
