{-# LANGUAGE AllowAmbiguousTypes #-}

module Tricorder.Config.LoadedConfig
    ( LoadedConfig (..)
    , asInput
    , asNestedInput
    , decodeNestedValue
    , configFileName
    )
where

import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Input (Input)
import Data.Aeson (FromJSON)
import Effectful.Reader.Static (Reader)
import GHC.TypeLits (KnownSymbol, Symbol, symbolVal)
import System.FilePath ((</>))

import Atelier.Effects.FileSystem qualified as FileSystem
import Atelier.Effects.Input qualified as Input
import Data.Aeson qualified as Aeson
import Data.Aeson.KeyMap qualified as KM
import Data.List qualified as List
import Data.Text qualified as T
import Data.Yaml qualified as Yaml
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime (ProjectRoot (..))


newtype LoadedConfig = LoadedConfig {getLoadedConfig :: ByteString}


asInput
    :: (FileSystem :> es, Reader ProjectRoot :> es)
    => Eff (Input LoadedConfig : es) a -> Eff es a
asInput = Input.withEff do
    ProjectRoot projectRoot <- Reader.ask
    let configFilePath = projectRoot </> configFileName
    exists <- FileSystem.doesFileExist configFilePath
    if exists
        then do
            bs <- FileSystem.readFileBs configFilePath
            pure $ LoadedConfig bs
        else pure $ LoadedConfig ""


asNestedInput
    :: forall (key :: Symbol) r es a
     . ( FromJSON r
       , Input LoadedConfig :> es
       , KnownSymbol key
       )
    => Eff (Input (Either Text r) : es) a -> Eff es a
asNestedInput = Input.withEff do
    loadedConfig <- Input.input
    pure $ decodeNestedValue @key loadedConfig


configFileName :: FilePath
configFileName = ".tricorder.yaml"


decodeNestedValue
    :: forall (key :: Symbol) r. (FromJSON r, KnownSymbol key) => LoadedConfig -> Either Text r
decodeNestedValue (LoadedConfig root) =
    go [] props
        =<< first
            (toText . Yaml.prettyPrintParseException)
            (Yaml.decodeEither' root)
  where
    props = T.splitOn "." $ toText $ symbolVal $ Proxy @key

    go :: [Text] -> [Text] -> Aeson.Value -> Either Text r
    go prev (p : ps) (Aeson.Object m) =
        maybe
            (Left $ "missing property '" <> p <> "' at " <> formatPrev prev)
            (go (p : prev) ps)
            $ KM.lookup (fromString $ toString p) m
    go prev (_ : _) _ =
        Left $ "expected property to be an object: " <> formatPrev prev
    go prev [] x =
        first (\e -> "parse error for property " <> formatPrev prev <> ": " <> e)
            $ fromJSON x

    fromJSON x = case Aeson.fromJSON x of
        Aeson.Success a -> Right a
        Aeson.Error err -> Left $ toText err

    formatPrev prev
        | List.null prev = "<root object>"
        | otherwise = T.intercalate "." $ List.reverse prev
