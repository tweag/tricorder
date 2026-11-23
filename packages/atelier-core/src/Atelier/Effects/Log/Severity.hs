module Atelier.Effects.Log.Severity
    ( Severity (..)
    , Config (..)
    , minimumSeverityFromEnv
    )
where

import Data.Aeson (FromJSON, ToJSON)
import Effectful.NonDet (OnEmptyPolicy (..), emptyEff, runNonDet)

import Atelier.Effects.Env (Env)
import Atelier.Types.JSON.ReadShow (ReadShow (..))

import Atelier.Effects.Env qualified as Env


-- | Log severity levels, ordered from least to most severe.
data Severity
    = -- | Verbose diagnostic detail.
      DEBUG
    | -- | Normal operational information.
      INFO
    | -- | Something unexpected, but recoverable.
      WARN
    | -- | A failure that needs attention.
      ERROR
    deriving stock (Bounded, Enum, Eq, Ord, Read, Show)
    deriving (FromJSON) via ReadShow Severity
    deriving (ToJSON) via ReadShow Severity


newtype Config = Config {minimumSeverity :: Severity}


minimumSeverityFromEnv :: (Env :> es) => Eff es (Maybe Severity)
minimumSeverityFromEnv = do
    fmap rightToMaybe
        $ runNonDet OnEmptyKeep
        $ asum
            [ Env.lookup "LOG" >>= readAlt
            , Env.lookup "LOGGING" >>= readAlt
            , Env.lookup "DEBUG" >>= \case
                Nothing -> emptyEff
                Just x
                    | x == "0" -> emptyEff
                    | otherwise -> pure DEBUG
            ]
  where
    readAlt Nothing = emptyEff
    readAlt (Just x) = case readMaybe x of
        Nothing -> emptyEff
        Just x' -> pure x'
