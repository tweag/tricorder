module Tricorder.Runtime.LogPath
    ( LogPath (..)
    , envName
    , asReader
    )
where

import Atelier.Effects.Env (Env)
import Atelier.FileSystem.Path ((</>))
import Data.Aeson (ToJSON)
import Effectful.Reader.Static (Reader)

import Atelier.Effects.Env qualified as Env
import Atelier.FileSystem.Path qualified as Path
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime.Cache (Cache (..))

import Tricorder.Runtime.Cache qualified as Runtime (Cache)


newtype LogPath = LogPath {getLogPath :: Path.Absolute}
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via Path.Absolute


envName :: String
envName = "TRICORDER_LOG_PATH"


asReader :: (Env :> es, Reader Runtime.Cache :> es) => Eff (Reader LogPath : es) a -> Eff es a
asReader act = do
    mLogPath <- Env.lookup envName
    case mLogPath of
        Just logPath
            | Right path <- Path.fromFilePath logPath ->
                Reader.runReader (LogPath path) act
        _ -> do
            Cache cacheDir <- Reader.ask
            Reader.runReader (LogPath $ cacheDir </> Path.rel @"daemon.log") act
