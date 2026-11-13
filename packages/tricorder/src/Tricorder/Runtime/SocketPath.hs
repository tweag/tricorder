module Tricorder.Runtime.SocketPath
    ( SocketPath (..)
    , asReader
    )
where

import Data.Aeson (ToJSON)
import Effectful.Reader.Static (Reader)

import Atelier.FileSystem.Path qualified as Path

import Tricorder.Runtime.Directory qualified as Runtime (Directory)
import Tricorder.Runtime.Directory qualified as Runtime.Directory


newtype SocketPath = SocketPath {getSocketPath :: Path.Absolute}
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via Path.Absolute


asReader
    :: (Reader Runtime.Directory :> es)
    => Eff (Reader SocketPath : es) a
    -> Eff es a
asReader = Runtime.Directory.asReaderFor (Path.relative @"socket.sock") SocketPath
