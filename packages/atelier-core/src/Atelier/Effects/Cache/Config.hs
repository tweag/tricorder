-- | Configuration shared by the TTL cache interpreters.
--
-- 'Config' controls how long entries live and how often the background eviction
-- sweep runs. It is re-exported by "Atelier.Effects.Cache" and
-- "Atelier.Effects.Tally".
module Atelier.Effects.Cache.Config
    ( Config (..)
    )
where

import Data.Aeson (FromJSON)
import Data.Default (Default (..))
import Data.Time (NominalDiffTime)

import Atelier.Types.QuietSnake (QuietSnake (..))


-- | Configuration for a TTL-evicting cache
data Config = Config
    { entryTtl :: !NominalDiffTime
    -- ^ Time-to-live for cache entries. After this duration from first insertion, entries are evicted.
    , cleanupInterval :: !NominalDiffTime
    -- ^ How often the background cleanup thread runs to evict expired entries.
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via QuietSnake Config


instance Default Config where
    def =
        Config
            { entryTtl = 12 * 3600 -- 12 hours in seconds
            , cleanupInterval = 3600 -- 1 hour in seconds
            }
