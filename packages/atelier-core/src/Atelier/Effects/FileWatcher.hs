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
    ( -- * Effect
      FileWatcher
    , watchFilePaths
    , watchFilePathsDebounced

      -- * Interpreters
    , runIO
    , runScripted

      -- * Internals (exported for testing)
    , deduplicateDirs
    , matchesAny
    )
where

import Data.List (nub)
import Effectful (Effect, Limit (..), Persistence (..), UnliftStrategy (..))
import Effectful.Concurrent (Concurrent)
import Effectful.Dispatch.Dynamic
    ( interpret
    , localSeqUnlift
    , localUnlift
    , reinterpret
    )
import Effectful.State.Static.Shared (evalState, get, put)
import Effectful.TH (makeEffect)
import System.FSNotify (eventPath)

import Effectful.Concurrent qualified as Concurrent

import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.FSNotify (FSNotify)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.FileWatcher.Event (Event)
import Atelier.Effects.FileWatcher.Watch (Watch)

import Atelier.Effects.Debounce qualified as Debounce
import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.FSNotify qualified as FSNotify
import Atelier.Effects.FileWatcher.Event qualified as Event
import Atelier.Effects.FileWatcher.Watch qualified as Watch
import Atelier.Time qualified as Time


data FileWatcher :: Effect where
    -- | Watch the given directories for changes, calling the callback with
    -- each matching file path and the kind of change that occurred. Registers
    -- the minimal set of OS watchers needed to cover all entries (deduplication
    -- by path prefix). The callback is invoked at most once per raw filesystem
    -- event regardless of how many entries match. Never returns.
    WatchFilePaths :: [Watch] -> (FilePath -> Event -> m a) -> FileWatcher m Void


makeEffect ''FileWatcher


-- | Like 'watchFilePaths' but automatically debounces by path.
-- Rapid successive events for the same file coalesce into a single callback.
-- Uses a 100ms settle window.
watchFilePathsDebounced
    :: (Debounce FilePath :> es, FileWatcher :> es)
    => [Watch]
    -> (FilePath -> Event -> Eff es ())
    -> Eff es Void
watchFilePathsDebounced watches callback =
    watchFilePaths watches \path event ->
        Debounce.withArg 100 (<>) path event (callback path)


-- | Production interpreter backed by fsnotify.
runIO :: (Delay :> es, FSNotify :> es, FileSystem :> es) => Eff (FileWatcher : es) a -> Eff es a
runIO = interpret \env -> \case
    WatchFilePaths watches callback -> do
        absWatches <- forM watches Watch.makeAbsolute
        FSNotify.withManager \mgr -> do
            let dedupedDirs = deduplicateDirs $ Watch.path <$> absWatches
            localUnlift env (ConcUnlift Persistent Unlimited) \unlift ->
                for_ dedupedDirs \d ->
                    FSNotify.watchTree mgr d (matchesAny absWatches . eventPath) \fsEvent ->
                        void $ unlift $ callback (eventPath fsEvent) (Event.fromFS fsEvent)
            -- Park indefinitely to hold the manager open. fsnotify delivers
            -- events on its own threads, so there is nothing to do here, and
            -- waking up is not free: each wake-up ends the RTS idle period
            -- and re-arms idle GC, costing a full major collection. 'forever'
            -- is belt-and-braces in case the delay ever returns early.
            forever
                $ Delay.wait @Time.Microsecond
                $ Time.fromMicroseconds
                $ fromIntegral (maxBound :: Int)


-- | Scripted interpreter for testing.
--
-- Delivers all scripted events to the callback in order, then parks forever,
-- matching the blocking semantics of 'runIO' — 'WatchFilePaths' returns
-- 'Void', so callers must never be resumed. Parks with a delay rather than
-- @atomically retry@ for the same reason as 'runIO': a retry that
-- read no 'TVar' stays parked only while GC sees the thread as reachable, so
-- whether it survives depends on whether the test happens to hold onto the
-- 'ThreadId'.
--
-- The 'Watch' specification is ignored; the caller controls what events are fed in.
runScripted
    :: (Concurrent :> es) => [(FilePath, Event)] -> Eff (FileWatcher : es) a -> Eff es a
runScripted events = reinterpret (evalState events) \env -> \case
    WatchFilePaths _ callback ->
        localSeqUnlift env \unlift -> do
            events' <- get
            put []
            for_ events' \(path, fileEvent) -> unlift $ callback path fileEvent
            forever $ Concurrent.threadDelay maxBound


-- Helpers

-- | Remove dirs that are proper subdirectories of another dir in the list.
deduplicateDirs :: [FilePath] -> [FilePath]
deduplicateDirs dirs = filter notRedundant (nub dirs)
  where
    notRedundant d = not $ any (\d' -> d' /= d && Watch.isStrictAncestor d' d) dirs


-- | Check whether a file path matches at least one 'Watch' entry.
matchesAny :: [Watch] -> FilePath -> Bool
matchesAny watches path = any (Watch.matches path) watches
