module Tricorder.Session.HaskellHooks
    ( HaskellHooks (..)
    , display
    )
where

import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))

import Data.Text qualified as T

import Tricorder.Session.Hook (Hook)

import Tricorder.Session.Hook qualified as Hook


data HaskellHooks = HaskellHooks
    { fileAdded :: Maybe Hook
    , fileModified :: Maybe Hook
    , fileRemoved :: Maybe Hook
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake HaskellHooks


instance Default HaskellHooks where
    def =
        HaskellHooks
            { fileAdded = Nothing
            , fileModified = Nothing
            , fileRemoved = Nothing
            }


display :: HaskellHooks -> Text
display hooks =
    T.intercalate
        "\n"
        [ "file_added: " <> maybe "<unset>" Hook.getHook hooks.fileAdded
        , "file_modified: " <> maybe "<unset>" Hook.getHook hooks.fileModified
        , "file_removed: " <> maybe "<unset>" Hook.getHook hooks.fileRemoved
        ]
