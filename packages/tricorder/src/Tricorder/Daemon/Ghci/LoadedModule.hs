module Tricorder.Daemon.Ghci.LoadedModule
    ( LoadedModule (..)
    )
where


-- | A module currently loaded in the GHCi session.
data LoadedModule = LoadedModule
    { relPath :: FilePath
    -- ^ Path relative to the project root (e.g. @"./src/Foo.hs"@).
    , moduleName :: Text
    }
    deriving stock (Eq, Show)
