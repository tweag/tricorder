module Tricorder.Daemon.Ghci.Loading (Loading (..)) where


-- | Payload for a @[N of M] Compiling Mod ( file, ... )@ line.
data Loading = Loading
    { index :: Int
    -- ^ N (this module's index in the compilation sequence)
    , total :: Int
    -- ^ M (total modules to compile)
    , moduleName :: Text
    , sourceFile :: FilePath
    }
    deriving stock (Eq, Show)
