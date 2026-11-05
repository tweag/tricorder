module Tricorder.Runtime.SocketPath
    ( SocketPath (..)
    , asReader
    )
where

import Data.Aeson (ToJSON)
import Effectful.Reader.Static (Reader)

import Tricorder.Runtime.Directory qualified as Runtime (Directory)
import Tricorder.Runtime.Directory qualified as Runtime.Directory


newtype SocketPath = SocketPath {getSocketPath :: FilePath}
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via FilePath


asReader
    :: (Reader Runtime.Directory :> es)
    => Eff (Reader SocketPath : es) a
    -> Eff es a
asReader = Runtime.Directory.asReaderFor "socket.sock" SocketPath
