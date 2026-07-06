module Tricorder.GhcPkg.Types
    ( ModuleName (..)
    , PackageId (..)
    , SourceQuery (..)
    ) where

import Data.Aeson (FromJSON, ToJSON)


-- | A dotted Haskell module name, e.g. @"Data.Map.Strict"@.
newtype ModuleName = ModuleName {unModuleName :: Text}
    deriving newtype (Eq, FromJSON, Hashable, IsString, Ord, Show, ToJSON)


-- | A @ghc-pkg@ package identifier, e.g. @"containers-0.6.8"@.
newtype PackageId = PackageId {unPackageId :: Text}
    deriving newtype (Eq, FromJSON, Hashable, IsString, Ord, Show, ToJSON)


-- | A query for module source: optionally scoped to a single top-level symbol.
data SourceQuery = SourceQuery
    { moduleName :: ModuleName
    , function :: Maybe Text
    -- ^ The symbol to slice: 'Nothing' is the whole module; @'Just' name@ is a
    -- single top-level declaration — a value binding, or (by initial casing) a
    -- type, class, or constructor.
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, Hashable, ToJSON)
