module Tricorder.Logging (runLogging) where

import Atelier.Config (LoadedConfig, extractNestedConfig)
import Atelier.Effects.Env (Env)
import Atelier.Effects.File (BufferMode (..), File)
import Atelier.Effects.Input (Input, input)
import Atelier.Effects.Log (Log, Severity (..), runLogToHandle)
import Effectful (IOE)
import Effectful.Reader.Static (Reader, asks)

import Atelier.Effects.File qualified as File
import Atelier.Effects.Log qualified as Log

import Tricorder.Runtime (LogPath (..))


runLogging
    :: ( Env :> es
       , File :> es
       , IOE :> es
       , Input LoadedConfig :> es
       , Reader LogPath :> es
       )
    => Eff (Log : es) a -> Eff es a
runLogging act = do
    path <- asks @LogPath (.getLogPath)
    File.withFile path AppendMode \h -> do
        File.hSetBuffering h LineBuffering
        sev <- getMinimumSeverity
        runLogToHandle h sev act


getMinimumSeverity :: (Env :> es, Input LoadedConfig :> es) => Eff es Severity
getMinimumSeverity = do
    mSev <- Log.minimumSeverityFromEnv
    case mSev of
        Just sev -> pure sev
        Nothing -> do
            loadedConfig <- input
            let config = extractNestedConfig @"session.logging" @Log.Config loadedConfig
            pure config.minimumSeverity
