module Tricorder.Daemon.Ghci.Loading (Loading (..)) where

import Atelier.FileSystem.Path qualified as Path


-- | Payload for a @[N of M] Compiling Mod ( file, ... )@ line.
data Loading = Loading
    { index :: Int
    -- ^ N (this module's index in the compilation sequence)
    , total :: Int
    -- ^ M (total modules to compile)
    , moduleName :: Text
    , sourceFile :: Path.Any
    }
    deriving stock (Eq, Show)
