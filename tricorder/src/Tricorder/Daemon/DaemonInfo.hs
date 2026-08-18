module Tricorder.Daemon.DaemonInfo
    ( DaemonInfo (..)
    , load
    , runInput
    )
where

import Atelier.Effects.Input (Input, input, runInputEff)
import Data.Aeson (FromJSON (..), ToJSON (..))
import Effectful.Reader.Static (Reader, ask)
import GHC.Generics (Generically (..))
import System.FilePath (makeRelative)

import Tricorder.Runtime (LogPath (..), ProjectRoot (..), SocketPath (..))
import Tricorder.Session (Session (..))
import Tricorder.Session.Target (Target)
import Tricorder.Session.WatchDirs (WatchDirs (..))


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
    session <- input
    ProjectRoot projectRoot <- ask
    SocketPath sockPath <- ask
    LogPath logFile <- ask
    pure
        $ DaemonInfo
            { targets = session.targets
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
runInput = runInputEff load
