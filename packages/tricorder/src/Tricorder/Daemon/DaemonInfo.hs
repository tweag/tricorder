module Tricorder.Daemon.DaemonInfo
    ( DaemonInfo (..)
    , load
    , runInput
    )
where

import Atelier.Effects.Input (Input)
import Data.Aeson (FromJSON (..), ToJSON (..))
import Effectful.Reader.Static (Reader, ask)
import GHC.Generics (Generically (..))
import System.FilePath (makeRelative)

import Atelier.Effects.Input qualified as Input

import Tricorder.Runtime.LogPath (LogPath (..))
import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Runtime.SocketPath (SocketPath (..))
import Tricorder.Session (Session (..))
import Tricorder.Session.Target (Target)
import Tricorder.Session.WatchDirs (WatchDirs (..))

import Tricorder.Session.Stage.Build.Session qualified as Build.Session


data DaemonInfo = DaemonInfo
    { targets :: [Target]
    , watchDirs :: [FilePath]
    , sockPath :: FilePath
    , logFile :: FilePath
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically DaemonInfo


load
    :: ( Input Session :> es
       , Reader LogPath :> es
       , Reader ProjectRoot :> es
       , Reader SocketPath :> es
       )
    => Eff es DaemonInfo
load = do
    session <- Input.input
    ProjectRoot projectRoot <- ask
    SocketPath sockPath <- ask
    LogPath logFile <- ask
    pure
        $ DaemonInfo
            { targets = Build.Session.targets session.buildSession
            , watchDirs = map (makeRelative projectRoot) session.watchDirs.getWatchDirs
            , sockPath
            , logFile
            }


runInput
    :: ( Input Session :> es
       , Reader LogPath :> es
       , Reader ProjectRoot :> es
       , Reader SocketPath :> es
       )
    => Eff (Input DaemonInfo : es) a -> Eff es a
runInput = Input.withEff load
