module Tricorder.Daemon.Ghci.Path
    ( isLocationLess
    , pathSuffixesAsModuleName
    )
where

import System.FilePath (dropExtension, normalise, splitDirectories)

import Data.List qualified as List
import Data.Text qualified as T


-- | Whether a diagnostic file is a GHCi location-less pseudo-file — a fully
-- @\<…\>@-bracketed marker such as @\<no location info\>@ or @\<interactive\>@
-- rather than a real source path. These carry no source span but can still
-- represent genuine build-level failures, so callers treat them specially
-- (kept rather than dropped, cleared every cycle rather than retained).
--
-- We require both the opening @\<@ and a closing @\>@ so a real (if exotic)
-- path that merely starts with @\<@, e.g. @\<generated\>/Foo.hs@, is not
-- mistaken for a marker.
isLocationLess :: FilePath -> Bool
isLocationLess f = "<" `List.isPrefixOf` f && ">" `List.isSuffixOf` f


-- | Candidate dotted module names for a file path.
--
-- We can't convert dotted target names to paths without cabal's
-- source-dirs, so callers check the other direction: any uppercase-segment
-- suffix of the path (with @/@ → @.@, extension dropped) is a candidate.
-- E.g. @./tricorder/src/Tricorder/Version.hs@ yields candidates
-- @"Tricorder.Version"@ and @"Version"@.
pathSuffixesAsModuleName :: FilePath -> [Text]
pathSuffixesAsModuleName fp =
    let segments = filter (not . null) (splitDirectories (dropExtension (normalise fp)))
        upperSegments = dropWhile (not . startsUpper) segments
        suffixes = takeWhile (not . null) (iterate (drop 1) upperSegments)
    in  [T.intercalate "." (map toText s) | s <- suffixes]
  where
    startsUpper (c : _) = c >= 'A' && c <= 'Z'
    startsUpper _ = False
