{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE UndecidableInstances #-}

module Tricorder.Session.Hooks
    ( Hooks (..)
    , HookPair (..)
    , display
    )
where

import Atelier.Types.JSON.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))

import Data.Text qualified as T

import Tricorder.Session.HaskellHooks (HaskellHooks)
import Tricorder.Session.Hook (Hook)
import Tricorder.Session.Util (indent)

import Tricorder.Session.HaskellHooks qualified as HaskellHooks
import Tricorder.Session.Hook qualified as Hook


data Hooks = Hooks
    { start :: Maybe HookPair
    , reload :: Maybe HookPair
    , haskell :: Maybe HaskellHooks
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via QuietSnake Hooks
    deriving (FromJSON) via WithDefaults (QuietSnake Hooks)


instance Default Hooks where
    def =
        Hooks
            { start = def
            , reload = def
            , haskell = def
            }


display :: Hooks -> Text
display hooks =
    T.intercalate
        "\n"
        [ "start:" <> displayMaybeHook displayHookPair hooks.start
        , "reload:" <> displayMaybeHook displayHookPair hooks.reload
        , "haskell:" <> displayMaybeHook HaskellHooks.display hooks.haskell
        ]
  where
    displayMaybeHook f = maybe " <unset>" (("\n" <>) . indent . f)


data HookPair = HookPair
    { before :: Maybe Hook
    , after :: Maybe Hook
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via QuietSnake HookPair
    deriving (FromJSON) via WithDefaults (QuietSnake HookPair)


instance Default HookPair where
    def =
        HookPair
            { before = Nothing
            , after = Nothing
            }


displayHookPair :: HookPair -> Text
displayHookPair pair =
    T.intercalate
        "\n"
        [ "before: " <> maybe "<unset>" Hook.getHook pair.before
        , "after: " <> maybe "<unset>" Hook.getHook pair.after
        ]
