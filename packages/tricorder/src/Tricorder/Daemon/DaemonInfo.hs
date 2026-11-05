module Tricorder.Daemon.DaemonInfo
    ( DaemonInfo (..)
    , load
    , asInput
    )
where

import Atelier.Effects.Input (Input)
import Atelier.Types.JSON.QuietSnake
    ( QuietSnake (..)
    )
import Data.Aeson (ToJSON)
import Effectful.Reader.Static (Reader, ask)

import Atelier.Effects.Input qualified as Input

import Tricorder.Runtime.LogPath (LogPath (..))
import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Runtime.SocketPath (SocketPath (..))
import Tricorder.Session (Session (..))


data DaemonInfo = DaemonInfo
    { session :: Session
    , sockPath :: SocketPath
    , logFile :: LogPath
    , projectRoot :: ProjectRoot
    }
    deriving stock (Eq, Generic)
    deriving (ToJSON) via QuietSnake DaemonInfo


load
    :: ( Input Session :> es
       , Reader LogPath :> es
       , Reader ProjectRoot :> es
       , Reader SocketPath :> es
       )
    => Eff es DaemonInfo
load = do
    session <- Input.input
    projectRoot <- ask
    sockPath <- ask
    logFile <- ask
    pure
        $ DaemonInfo
            { session
            , sockPath
            , logFile
            , projectRoot
            }


asInput
    :: ( Input Session :> es
       , Reader LogPath :> es
       , Reader ProjectRoot :> es
       , Reader SocketPath :> es
       )
    => Eff (Input DaemonInfo : es) a -> Eff es a
asInput = Input.withEff load
