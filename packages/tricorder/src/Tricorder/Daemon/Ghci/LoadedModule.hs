module Tricorder.Daemon.Ghci.LoadedModule
    ( LoadedModule (..)
    )
where

import Atelier.FileSystem.Path qualified as Path


-- | A module currently loaded in the GHCi session.
data LoadedModule = LoadedModule
    { relPath :: Path.Relative
    -- ^ Path relative to the project root (e.g. @"./src/Foo.hs"@).
    , moduleName :: Text
    }
    deriving stock (Eq, Show)
