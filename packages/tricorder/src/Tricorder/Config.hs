module Tricorder.Config
    ( Config (..)
    , asInput
    )
where

import Atelier.Effects.Input (Input)
import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Atelier.Types.JSON.WithDefaults (WithDefaults (..))
import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))

import Atelier.Effects.Input qualified as Input
import Data.Aeson qualified as Aeson
import Data.Yaml qualified as Yaml

import Tricorder.Config.LoadedConfig (LoadedConfig (..))

import Tricorder.Session.Config qualified as Session (Config)


data Config = Config
    { session :: Maybe Session.Config
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via QuietSnake Config
    deriving (FromJSON) via WithDefaults (QuietSnake Config)


instance Default Config where
    def =
        Config
            { session = def
            }


asInput
    :: (Input LoadedConfig :> es)
    => Eff (Input (Either Text Config) : es) a -> Eff es a
asInput = Input.withEff do
    LoadedConfig bs <- Input.input
    case Yaml.decodeEither' bs of
        Right Aeson.Null -> pure $ Right def
        _ -> pure $ first (toText . Yaml.prettyPrintParseException) $ Yaml.decodeEither' bs
