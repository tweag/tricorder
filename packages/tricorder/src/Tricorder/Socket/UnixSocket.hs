module Tricorder.Socket.UnixSocket
    ( -- * Effect
      UnixSocket
    , bind
    , accept
    , withConnection

      -- * Interpreters
    , runIO
    , runScripted
    , SocketScript (..)
    )
where

import Atelier.Effects.File (BufferMode (..), File, Handle)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift, reinterpret)
import Effectful.Exception (finally)
import Effectful.State.Static.Shared (evalState, get, put)
import Effectful.TH (makeEffect)
import Network.Socket
    ( Family (..)
    , SockAddr (..)
    , Socket
    , SocketType (..)
    )
import System.IO (hSetEncoding, utf8)

import Atelier.Effects.File qualified as File
import Network.Socket qualified as Net
import Network.Socket qualified as Socket


data UnixSocket :: Effect where
    -- | Create, bind, and listen on a Unix socket at the given path.
    Bind :: FilePath -> UnixSocket m Socket
    -- | Accept the next incoming connection and return a line-buffered 'Handle'.
    Accept :: Socket -> UnixSocket m Handle
    -- | Connect to a Unix socket and run the callback with the resulting handle.
    -- The handle is closed when the callback returns.
    WithConnection :: FilePath -> (Handle -> m a) -> UnixSocket m a


makeEffect ''UnixSocket


-- | Production interpreter backed by real Unix sockets.
--
-- Socket creation and encoding setup require raw IO (no @File@ equivalent),
-- but the handle-level reads, writes, buffering and closing go through the
-- 'File' effect.
runIO :: (File :> es, IOE :> es) => Eff (UnixSocket : es) a -> Eff es a
runIO eff = interpretWith eff \env -> \case
    Bind path -> liftIO do
        sock <- Socket.socket AF_UNIX Stream Socket.defaultProtocol
        Socket.bind sock (SockAddrUnix path)
        Socket.listen sock 5
        pure sock
    Accept sock -> do
        h <- liftIO do
            (conn, _) <- Socket.accept sock
            h <- Socket.socketToHandle conn ReadWriteMode
            hSetEncoding h utf8
            pure h
        File.hSetBuffering h LineBuffering
        pure h
    WithConnection sockPath callback ->
        localSeqUnlift env \unlift -> do
            h <- liftIO do
                sock <- Socket.socket AF_UNIX Stream Socket.defaultProtocol
                Net.connect sock (SockAddrUnix sockPath)
                h <- Socket.socketToHandle sock ReadWriteMode
                hSetEncoding h utf8
                pure h
            File.hSetBuffering h LineBuffering
            unlift (callback h) `finally` File.hClose h


-- | Script element for the test interpreter.
data SocketScript
    = -- | Return this 'Handle' for the next 'acceptHandle' call.
      NextAccept Handle
    | -- | Return this 'Bool' for the next 'socketFileExists' call.
      NextFileCheck Bool
    | -- | Use this 'Handle' for the next 'withConnection' call.
      NextConnect Handle
    | -- | Return this text for the next 'readLine' call.
      NextReadLine Text


-- | Scripted interpreter for testing.
--
-- 'bindSocket' creates a real (unbound) socket so that the returned 'Socket'
-- is a valid value, but does not actually bind to the filesystem.
-- 'acceptHandle' pops the next 'NextAccept' entry from the queue and sets
-- line buffering on it. 'removeSocketFile' is always a no-op.
-- 'socketFileExists' pops the next 'NextFileCheck' entry.
-- 'withConnection' pops the next 'NextConnect' entry and passes it to the callback.
runScripted
    :: (File :> es, IOE :> es) => [SocketScript] -> Eff (UnixSocket : es) a -> Eff es a
runScripted script = reinterpret (evalState script) \env -> \case
    Bind _ ->
        liftIO $ Net.socket AF_UNIX Stream Socket.defaultProtocol
    Accept _ ->
        get >>= \case
            NextAccept h : rest -> do
                put rest
                File.hSetBuffering h LineBuffering
                pure h
            _ -> error "UnixSocketScripted: expected NextAccept but queue was empty or mismatched"
    WithConnection _ callback ->
        get >>= \case
            NextConnect h : rest -> do
                put rest
                localSeqUnlift env \unlift -> unlift (callback h)
            _ -> error "UnixSocketScripted: expected NextConnect but queue was empty or mismatched"
