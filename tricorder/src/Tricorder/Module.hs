module Tricorder.Module
    ( ModuleName (..)
    , PackageId (..)
    , splitPackageId
    ) where

import Data.Aeson (FromJSON, ToJSON)

import Data.Text qualified as T


-- | A dotted Haskell module name, e.g. @"Data.Map.Strict"@.
newtype ModuleName = ModuleName {unModuleName :: Text}
    deriving newtype (Eq, FromJSON, Hashable, IsString, Ord, Show, ToJSON)


-- | A @ghc-pkg@ package identifier, e.g. @"containers-0.6.8"@.
newtype PackageId = PackageId {unPackageId :: Text}
    deriving newtype (Eq, FromJSON, Hashable, IsString, Ord, Show, ToJSON)


-- | Split a 'PackageId' into its package name and version. The version is the
-- final hyphen-delimited component (versions are dot-, not hyphen-separated),
-- so @"list-t-1.0.5.7"@ → @("list-t", "1.0.5.7")@.
splitPackageId :: PackageId -> (Text, Text)
splitPackageId (PackageId pid) =
    case reverse (T.splitOn "-" pid) of
        (ver : nameParts@(_ : _)) -> (T.intercalate "-" (reverse nameParts), ver)
        _ -> (pid, "")
