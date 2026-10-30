module Tricorder.Runtime.SocketPath
    ( SocketPath (..)
    , asReader
    )
where

import Effectful.Reader.Static (Reader)

import Tricorder.Runtime.Directory qualified as Runtime (Directory)
import Tricorder.Runtime.Directory qualified as Runtime.Directory


newtype SocketPath = SocketPath {getSocketPath :: FilePath}


asReader
    :: (Reader Runtime.Directory :> es)
    => Eff (Reader SocketPath : es) a
    -> Eff es a
asReader = Runtime.Directory.asReaderFor "socket.sock" SocketPath
