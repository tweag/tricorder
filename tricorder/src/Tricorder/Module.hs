module Tricorder.Module (ModuleName (..), PackageId (..)) where

import Data.Aeson (FromJSON, ToJSON)


-- | A dotted Haskell module name, e.g. @"Data.Map.Strict"@.
newtype ModuleName = ModuleName {unModuleName :: Text}
    deriving newtype (Eq, FromJSON, Hashable, IsString, Ord, Show, ToJSON)


-- | A @ghc-pkg@ package identifier, e.g. @"containers-0.6.8"@.
newtype PackageId = PackageId {unPackageId :: Text}
    deriving newtype (Eq, FromJSON, Hashable, IsString, Ord, Show, ToJSON)
