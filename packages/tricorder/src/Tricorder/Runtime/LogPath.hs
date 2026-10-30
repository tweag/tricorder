module Tricorder.Runtime.LogPath (LogPath (..), envName, asReader) where

import Atelier.Effects.Env (Env)
import Effectful.Reader.Static (Reader)

import Atelier.Effects.Env qualified as Env
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime.Directory qualified as Runtime (Directory)
import Tricorder.Runtime.Directory qualified as Runtime.Directory


newtype LogPath = LogPath {getLogPath :: FilePath}


envName :: String
envName = "TRICORDER_LOG_PATH"


asReader :: (Env :> es, Reader Runtime.Directory :> es) => Eff (Reader LogPath : es) a -> Eff es a
asReader act = do
    mLogPath <- Env.lookup envName
    case mLogPath of
        Just logPath -> Reader.runReader (LogPath logPath) act
        Nothing -> Runtime.Directory.asReaderFor "daemon.log" LogPath act
