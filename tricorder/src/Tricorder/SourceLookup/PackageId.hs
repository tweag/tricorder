module Tricorder.SourceLookup.PackageId
    ( PackageId (..)
    , splitPackageId
    )
where

import Data.Aeson (FromJSON, ToJSON)

import Data.Text qualified as T


-- | A @ghc-pkg@ package identifier, e.g. @"containers-0.6.8"@.
newtype PackageId = PackageId {unPackageId :: Text}
    deriving stock (Eq, Ord, Show)
    deriving (FromJSON, Hashable, IsString, ToJSON) via Text


-- | Split a 'PackageId' into its package name and version. The version is the
-- final hyphen-delimited component (versions are dot-, not hyphen-separated),
-- so @"list-t-1.0.5.7"@ → @("list-t", "1.0.5.7")@.
splitPackageId :: PackageId -> (Text, Text)
splitPackageId (PackageId pid) =
    case reverse (T.splitOn "-" pid) of
        (ver : nameParts@(_ : _)) -> (T.intercalate "-" (reverse nameParts), ver)
        _ -> (pid, "")
