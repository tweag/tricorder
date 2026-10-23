module Atelier.Effects.FileWatcher.Watch
    ( -- * Watch specification
      Watch
    , path

      -- ** Constructors
    , dir
    , dirExt
    , dirWhere

      -- ** Combinators
    , excluding
    , containing

      -- ** Check
    , matches

      -- ** Utils
    , isStrictAncestor
    , makeAbsolute
    )
where

import Data.Text qualified as T
import System.FilePath qualified as Path

import Atelier.Effects.FileSystem (FileSystem)

import Atelier.Effects.FileSystem qualified as FileSystem


-- | Specification of a directory to watch recursively, with a file predicate.
data Watch = Watch FilePath (FilePath -> Bool)


path :: Watch -> FilePath
path (Watch p _) = p


-- | Watch all files in a directory recursively.
dir :: FilePath -> Watch
dir p = Watch p (const True)


-- | Watch files matching a predicate in a directory recursively.
--
-- @
-- dirWhere "src" (\f -> takeExtension f == ".hs")
-- @
dirWhere :: FilePath -> (FilePath -> Bool) -> Watch
dirWhere = Watch


-- | Watch files with a specific extension in a directory recursively.
--
-- @
-- dirExt "src" ".hs"
-- @
dirExt :: FilePath -> Text -> Watch
dirExt p ext = dirWhere p (\f -> toText (Path.takeExtension f) == ext)


-- | Narrow a 'Watch' to exclude files matching a predicate.
--
-- @
-- dirExt "src" ".hs" \`excluding\` containing "dist-newstyle"
-- @
excluding :: Watch -> (FilePath -> Bool) -> Watch
excluding (Watch p predicate) excl = Watch p (\f -> predicate f && not (excl f))


-- | Predicate: the file path contains the given fragment.
--
-- Intended for use with 'excluding':
--
-- @
-- dir "src" \`excluding\` containing "dist-newstyle"
-- @
containing :: Text -> FilePath -> Bool
containing fragment f = fragment `T.isInfixOf` toText f


matches :: FilePath -> Watch -> Bool
matches filePath (Watch d predicate) =
    (d == filePath || isStrictAncestor d filePath) && predicate filePath


-- | @isStrictAncestor parent child@ is true iff @parent@ is a proper ancestor
-- of @child@ in the filesystem hierarchy.
isStrictAncestor :: FilePath -> FilePath -> Bool
isStrictAncestor parent child = (parent <> "/") `isPrefixOf` child


makeAbsolute :: (FileSystem :> es) => Watch -> Eff es Watch
makeAbsolute (Watch p predicate) = flip Watch predicate <$> FileSystem.makeAbsolute p
