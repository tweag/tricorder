module Tricorder.Config
    ( LoadedConfig (..)
    , runLoadedConfig
    , inputLoadedConfig
    , configFileName
    )
where

import Atelier.Config (LoadedConfig (..))
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Input (Input, runInputEff)
import Effectful.Reader.Static (Reader, ask, runReader)
import System.FilePath ((</>))

import Atelier.Effects.FileSystem qualified as FileSystem
import Data.Aeson qualified as Aeson
import Data.Aeson.KeyMap qualified as KM
import Data.Yaml qualified as Yaml

import Tricorder.Runtime (ProjectRoot (..))


-- | Load config from .tricorder.yaml in the project root.
-- Falls back to empty config (all defaults) if the file is absent or cannot be parsed.
loadTricorderConfig :: (FileSystem :> es) => FilePath -> Eff es LoadedConfig
loadTricorderConfig projectRoot = do
    exists <- FileSystem.doesFileExist yamlPath
    if not exists then
        pure $ LoadedConfig (Aeson.Object KM.empty)
    else do
        bs <- FileSystem.readFileBs yamlPath
        pure . LoadedConfig $ case Yaml.decodeEither' @Aeson.Value bs of
            Left _ -> Aeson.Object KM.empty
            Right v -> v
  where
    yamlPath = projectRoot </> configFileName


configFileName :: FilePath
configFileName = ".tricorder.yaml"


runLoadedConfig
    :: ( FileSystem :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Reader LoadedConfig : es) a -> Eff es a
runLoadedConfig act = do
    ProjectRoot projectRoot <- ask
    cfg <- loadTricorderConfig projectRoot
    runReader cfg act


inputLoadedConfig
    :: ( FileSystem :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Input LoadedConfig : es) a -> Eff es a
inputLoadedConfig = runInputEff do
    ProjectRoot projectRoot <- ask
    loadTricorderConfig projectRoot
