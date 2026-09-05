module Tricorder.Logging (runLogging) where

import Atelier.Effects.File (BufferMode (..), File)
import Atelier.Effects.Log (Log, Severity (..), runLogToHandle)
import Effectful (IOE)
import Effectful.Reader.Static (Reader, asks)

import Atelier.Effects.File qualified as File

import Tricorder.Runtime (LogPath (..))


runLogging :: (File :> es, IOE :> es, Reader LogPath :> es) => Eff (Log : es) a -> Eff es a
runLogging act = do
    path <- asks @LogPath (.getLogPath)
    File.withFile path AppendMode \h -> do
        File.hSetBuffering h LineBuffering
        runLogToHandle h INFO act
