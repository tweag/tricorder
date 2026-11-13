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
    )
where

import Data.Text qualified as T

import Atelier.FileSystem.Path qualified as Path


-- | Specification of a directory to watch recursively, with a file predicate.
data Watch = Watch Path.Absolute (Path.Absolute -> Bool)


path :: Watch -> Path.Absolute
path (Watch p _) = p


-- | Watch all files in a directory recursively.
dir :: Path.Absolute -> Watch
dir p = Watch p (const True)


-- | Watch files matching a predicate in a directory recursively.
--
-- @
-- dirWhere "src" (\f -> takeExtension f == ".hs")
-- @
dirWhere :: Path.Absolute -> (Path.Absolute -> Bool) -> Watch
dirWhere = Watch


-- | Watch files with a specific extension in a directory recursively.
--
-- @
-- dirExt "src" ".hs"
-- @
dirExt :: Path.Absolute -> Text -> Watch
dirExt p ext = dirWhere p (\f -> toText (Path.takeExtension f) == ext)


-- | Narrow a 'Watch' to exclude files matching a predicate.
--
-- @
-- dirExt "src" ".hs" \`excluding\` containing "dist-newstyle"
-- @
excluding :: Watch -> (Path.Absolute -> Bool) -> Watch
excluding (Watch p predicate) excl = Watch p (\f -> predicate f && not (excl f))


-- | Predicate: the file path contains the given fragment.
--
-- Intended for use with 'excluding':
--
-- @
-- dir "src" \`excluding\` containing "dist-newstyle"
-- @
containing :: Text -> Path.Absolute -> Bool
containing fragment f = fragment `T.isInfixOf` toText (Path.toFilePath f)


matches :: Path.Absolute -> Watch -> Bool
matches filePath (Watch d predicate) =
    (d == filePath || Path.isPrefixOf d filePath) && predicate filePath
