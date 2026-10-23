module Tricorder.Logging (runLogging) where

import Atelier.Effects.Env (Env)
import Atelier.Effects.File (BufferMode (..), File)
import Atelier.Effects.Input (Input)
import Atelier.Effects.Log (Log, Severity (..))
import Effectful (IOE)
import Effectful.Reader.Static (Reader, asks)

import Atelier.Effects.File qualified as File
import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log qualified as Log

import Tricorder.Config.LoadedConfig (LoadedConfig)
import Tricorder.Runtime (LogPath (..))

import Tricorder.Config.LoadedConfig qualified as LoadedConfig


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
    File.with path AppendMode \h -> do
        File.hSetBuffering h LineBuffering
        (maybeErr, sev) <- getMinimumSeverity
        Log.runToHandle h sev do
            whenJust maybeErr \err -> Log.err err
            act


getMinimumSeverity
    :: ( Env :> es
       , Input LoadedConfig :> es
       )
    => Eff es (Maybe Text, Severity)
getMinimumSeverity = do
    mSev <- Log.minimumSeverityFromEnv
    case mSev of
        Just sev -> pure (Nothing, sev)
        Nothing -> LoadedConfig.asNestedInput @"session.logging" @Log.Config do
            logConfigRes <- Input.input
            case logConfigRes of
                Left err -> do
                    pure (Just $ "failed to parse log config: " <> err, Log.INFO)
                Right cfg ->
                    pure (Nothing, cfg.minimumSeverity)
