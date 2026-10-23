module Tricorder.Session.Stage.Test.Config
    ( TestConfig (..)
    , Options (..)
    , OutputMode (..)
    )
where

import Atelier.Time (AsRawUnit, Millisecond)
import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON (..), ToJSON, Value (..))
import Data.Aeson.Types (ToJSON (..))
import Data.Default (Default (..))
import GHC.Generics (Generically (..))

import Tricorder.Session.CommandConfig (CommandConfig)

import Tricorder.Session.Stage qualified as Stage


data TestConfig = TestConfig
    { commandConfig :: CommandConfig 'Stage.Test
    , options :: Options
    }
    deriving stock (Eq, Generic, Show)


instance Default TestConfig where
    def =
        TestConfig
            { commandConfig = def
            , options = def
            }


instance ToJSON TestConfig where
    toJSON cfg = case (toJSON cfg.commandConfig, toJSON cfg.options) of
        (Object a, Object b) -> Object (a <> b)
        (a, _) -> a


instance FromJSON TestConfig where
    parseJSON v = TestConfig <$> parseJSON v <*> parseJSON v


data Options = Options
    { outputMode :: Maybe OutputMode
    , timeoutMs :: Maybe (AsRawUnit Millisecond)
    , memoryLimit :: Maybe Text
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake Options


instance Default Options where
    def =
        Options
            { outputMode = Nothing
            , timeoutMs = Nothing
            , memoryLimit = Nothing
            }


data OutputMode = ReplOutput | StdoutOutput
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically OutputMode
