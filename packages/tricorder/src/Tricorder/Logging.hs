module Tricorder.Logging (run) where

import Atelier.Effects.Env (Env)
import Atelier.Effects.Handles (BufferMode (..), Handles)
import Atelier.Effects.Input (Input)
import Atelier.Effects.Log (Log, Severity (..))
import Effectful (IOE)
import Effectful.Exception (trySync)
import Effectful.FileSystem (FileSystem)
import Effectful.Reader.Static (Reader)

import Atelier.Effects.Env qualified as Env
import Atelier.Effects.Handles qualified as Handles
import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log qualified as Log
import Atelier.FileSystem.File qualified as File
import Atelier.FileSystem.Path qualified as Path
import Effectful.Reader.Static qualified as Reader

import Tricorder.Config.LoadedConfig (LoadedConfig)
import Tricorder.Runtime.LogPath (LogPath (..))

import Tricorder.Config.LoadedConfig qualified as LoadedConfig


run
    :: ( Env :> es
       , FileSystem :> es
       , Handles :> es
       , IOE :> es
       , Input LoadedConfig :> es
       , Reader LogPath :> es
       )
    => Eff (Log : es) a -> Eff es a
run act = do
    LogPath path <- Reader.ask
    truncateLog path
    Handles.with path AppendMode \h -> do
        Handles.hSetBuffering h LineBuffering
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


noTruncateVarName :: String
noTruncateVarName = "TRICORDER_NO_LOG_TRUNCATE"


truncateLog
    :: (Env :> es, FileSystem :> es)
    => Path.Absolute -> Eff es ()
truncateLog path = do
    doTruncate <- (\x -> x == Nothing || x == Just "0") <$> Env.lookup noTruncateVarName
    when doTruncate do
        void $ trySync $ File.write path ("" :: ByteString)
