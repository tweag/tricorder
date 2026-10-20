module Tricorder.SourceLookup.ModuleSourceResult (ModuleSourceResult (..)) where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generically (..))

import Tricorder.SourceLookup.PackageId (PackageId)
import Tricorder.SourceLookup.SourceQuery (ModuleName, SourceQuery)


-- | The result of a source lookup for a single module.
data ModuleSourceResult
    = -- | Source was found; contains the module (or single-symbol) source text.
      SourceFound SourceQuery Text
    | -- | The module is neither in the project nor in any installed package.
      SourceNotFound SourceQuery
    | -- | The package was resolved but no source tarball could be located or
      -- fetched (no index, offline, yanked, or the archive could not be read).
      SourceUnavailable SourceQuery PackageId
    | -- | The symbol is not defined in the queried module but re-exported by
      -- it; contains the module that defines it and the symbol's source there.
      SourceReexported SourceQuery ModuleName Text
    | -- | The module source was found but the requested symbol was not in it.
      FunctionNotFound SourceQuery
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically ModuleSourceResult
