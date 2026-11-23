module Tricorder.Logging.Severity.Config (asInput) where

import Atelier.Effects.Console (Console)
import Atelier.Effects.Env (Env)
import Atelier.Effects.Input (Input)
import Effectful.Reader.Static (Reader)

import Atelier.Effects.Console qualified as Console
import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log.Config qualified as Log
import Atelier.Effects.Log.Severity qualified as Severity
import Effectful.Reader.Static qualified as Reader

import Tricorder.Config.LoadedConfig (LoadedConfig (..))

import Tricorder.Config.LoadedConfig qualified as LoadedConfig


asInput
    :: ( Console :> es
       , Env :> es
       , Input LoadedConfig :> es
       )
    => Eff (Reader Severity.Config : es) a -> Eff es a
asInput act = do
    mSev <- Severity.minimumSeverityFromEnv
    severity <- case mSev of
        Just sev -> pure $ Severity.Config sev
        Nothing -> LoadedConfig.asNestedInput @"session.logging" @Log.Config do
            logConfigRes <- Input.input
            case logConfigRes of
                Left err -> do
                    Console.putTextLn $ "[WARN] failed to parse log config: " <> err
                    pure $ Severity.Config Severity.INFO
                Right cfg ->
                    pure $ Severity.Config cfg.minimumSeverity
    Reader.runReader severity act
