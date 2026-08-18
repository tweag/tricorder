-- | Effect and smart constructors for watching file system paths.
--
-- == Overview
--
-- Build a list of 'Watch' values describing what to observe, then pass them
-- to 'watchFilePaths'. The effect registers the OS-level watchers needed to
-- cover the list (deduplication by path prefix) and fires the callback at most
-- once per raw filesystem event for a path.
--
-- == Examples
--
-- Watch a source directory for Haskell files, ignoring build artefacts:
--
-- @
-- watchFilePaths [dirExt "src" ".hs" \`excluding\` containing "dist-newstyle"] callback
-- @
--
-- Watch source and test directories together:
--
-- @
-- watchFilePaths (map (\`dirExt\` ".hs") ["src", "test"]) callback
-- @
--
-- Watch cabal-related files anywhere under a project root:
--
-- @
-- watchFilePaths [dirWhere projectRoot isCabalFile] callback
--   where
--     isCabalFile f = takeExtension f == ".cabal"
--                  || takeFileName f \`elem\` ["cabal.project", "package.yaml"]
-- @
--
-- Combine source and cabal watches with a single callback that dispatches on
-- the path, with automatic debouncing:
--
-- @
-- watchFilePathsDebounced (sourceWatches ++ cabalWatches) (markDirty . changeKindFor)
-- @
module Atelier.Effects.FileWatcher
    ( -- * Watch specification
      Watch

      -- ** Constructors
    , dir
    , dirExt
    , dirWhere

      -- ** Combinators
    , excluding
    , containing

      -- * File events
    , FileEvent (..)
    , mergeFileEvent

      -- * Effect
    , FileWatcher
    , watchFilePaths
    , watchFilePathsDebounced

      -- * Interpreters
    , runFileWatcherIO
    , runFileWatcherScripted

      -- * Internals (exported for testing)
    , deduplicateDirs
    , matchesAny
    )
where

import Control.Concurrent (threadDelay)
import Control.Concurrent.STM (retry)
import Data.List (nub)
import Effectful (Effect, IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift, localUnliftIO, reinterpret)
import Effectful.State.Static.Shared (evalState, get, put)
import Effectful.TH (makeEffect)
import System.Directory (makeAbsolute)
import System.FSNotify (eventPath, watchTree, withManager)
import System.FilePath (takeExtension)

import Data.Text qualified as T
import System.FSNotify qualified as FSN

import Atelier.Effects.Conc (concStrat)
import Atelier.Effects.Debounce (Debounce, debouncedWith)


-- | The kind of filesystem change that triggered a watch callback.
data FileEvent
    = -- | A new file was created.
      Added
    | -- | An existing file was modified.
      Modified
    | -- | A file was deleted.
      Removed
    deriving stock (Eq, Show)


-- | Merge two 'FileEvent's for the same path within a debounce window.
--
-- Rules (old, new) → result:
--
-- * @(_, Removed)@ → @Removed@: deletion always wins.
-- * @(Removed, Added)@ → @Added@: explicit re-creation after deletion.
-- * @(Added, _)@ → @Added@: a create-then-write is still a creation.
-- * Otherwise → the newer event.
mergeFileEvent :: FileEvent -> FileEvent -> FileEvent
mergeFileEvent _ Removed = Removed
mergeFileEvent Removed Added = Added
mergeFileEvent Added _ = Added
mergeFileEvent _ event = event


-- | Specification of a directory to watch recursively, with a file predicate.
data Watch = Watch FilePath (FilePath -> Bool)


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
dirExt p ext = dirWhere p (\f -> toText (takeExtension f) == ext)


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


data FileWatcher :: Effect where
    -- | Watch the given directories for changes, calling the callback with
    -- each matching file path and the kind of change that occurred. Registers
    -- the minimal set of OS watchers needed to cover all entries (deduplication
    -- by path prefix). The callback is invoked at most once per raw filesystem
    -- event regardless of how many entries match. Never returns.
    WatchFilePaths :: [Watch] -> (FilePath -> FileEvent -> m a) -> FileWatcher m Void


makeEffect ''FileWatcher


-- | Like 'watchFilePaths' but automatically debounces by path.
-- Rapid successive events for the same file coalesce into a single callback.
-- Uses a 100ms settle window.
watchFilePathsDebounced
    :: (Debounce FilePath :> es, FileWatcher :> es)
    => [Watch]
    -> (FilePath -> FileEvent -> Eff es ())
    -> Eff es Void
watchFilePathsDebounced watches callback =
    watchFilePaths watches \path event ->
        debouncedWith 100 mergeFileEvent path event (callback path)


-- | Production interpreter backed by fsnotify.
runFileWatcherIO :: (IOE :> es) => Eff (FileWatcher : es) a -> Eff es a
runFileWatcherIO eff = interpretWith eff \env -> \case
    WatchFilePaths watches callback ->
        localUnliftIO env concStrat \unliftIO -> do
            absWatches <- forM watches \(Watch p predicate) ->
                (\absP -> Watch absP predicate) <$> makeAbsolute p
            withManager \mgr -> do
                let dedupedDirs = deduplicateDirs [p | Watch p _ <- absWatches]
                for_ dedupedDirs \d ->
                    watchTree mgr d (matchesAny absWatches . eventPath) \fsEvent ->
                        void $ unliftIO $ callback (eventPath fsEvent) (toFileEvent fsEvent)
                forever $ threadDelay 1_000_000


-- | Scripted interpreter for testing.
-- Delivers all scripted events to the callback in order, then blocks
-- indefinitely — matching the blocking semantics of 'runFileWatcherIO'.
-- The 'Watch' specification is ignored; the caller controls what events are fed in.
runFileWatcherScripted :: (Concurrent :> es) => [(FilePath, FileEvent)] -> Eff (FileWatcher : es) a -> Eff es a
runFileWatcherScripted events = reinterpret (evalState events) \env -> \case
    WatchFilePaths _ callback ->
        localSeqUnlift env \unlift -> do
            events' <- get
            put []
            for_ events' \(path, fileEvent) -> unlift $ callback path fileEvent
            atomically retry


-- Helpers

toFileEvent :: FSN.Event -> FileEvent
toFileEvent = \case
    FSN.Added {} -> Added
    FSN.Modified {} -> Modified
    FSN.ModifiedAttributes {} -> Modified
    FSN.CloseWrite {} -> Modified
    FSN.Removed {} -> Removed
    FSN.WatchedDirectoryRemoved {} -> Removed
    FSN.Unknown {} -> Modified


-- | Remove dirs that are proper subdirectories of another dir in the list.
deduplicateDirs :: [FilePath] -> [FilePath]
deduplicateDirs dirs = filter notRedundant (nub dirs)
  where
    notRedundant d = not $ any (\d' -> d' /= d && isStrictAncestor d' d) dirs


-- | @isStrictAncestor parent child@ is true iff @parent@ is a proper ancestor
-- of @child@ in the filesystem hierarchy.
isStrictAncestor :: FilePath -> FilePath -> Bool
isStrictAncestor parent child = (parent <> "/") `isPrefixOf` child


-- | Check whether a file path matches at least one 'Watch' entry.
matchesAny :: [Watch] -> FilePath -> Bool
matchesAny watches path = any matches watches
  where
    matches (Watch d predicate) = (d == path || isStrictAncestor d path) && predicate path
