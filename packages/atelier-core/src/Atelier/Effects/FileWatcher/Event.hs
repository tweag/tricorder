module Atelier.Effects.FileWatcher.Event
    ( Event (..)
    , merge
    , fromFS
    , collapse
    )
where

import Data.List qualified as List
import System.FSNotify qualified as FSN

import Atelier.FileSystem.Path qualified as Path


-- | The kind of filesystem change that triggered a watch callback.
data Event
    = -- | A new file was created.
      Added
    | -- | An existing file was modified.
      Modified
    | -- | A file was deleted.
      Removed
    deriving stock (Eq, Show)


instance Semigroup Event where
    (<>) = merge


-- | Merge two 'Event's for the same path within a debounce window.
--
-- Rules (old, new) → result:
--
-- * @(_, Removed)@ → @Removed@: deletion always wins.
-- * @(Removed, Added)@ → @Added@: explicit re-creation after deletion.
-- * @(Added, _)@ → @Added@: a create-then-write is still a creation.
-- * Otherwise → the newer event.
merge :: Event -> Event -> Event
merge _ Removed = Removed
merge Removed Added = Modified
merge Added _ = Added
merge _ event = event


fromFS :: FSN.Event -> Event
fromFS = \case
    FSN.Added {} -> Added
    FSN.Modified {} -> Modified
    FSN.ModifiedAttributes {} -> Modified
    FSN.CloseWrite {} -> Modified
    FSN.Removed {} -> Removed
    FSN.WatchedDirectoryRemoved {} -> Removed
    FSN.Unknown {} -> Modified


-- | Collapse a batch of events so that each path appears once, with the events
-- it saw merged (see 'merge'). Paths are ordered by their most recent event.
collapse :: [(Path.Any, Event)] -> [(Path.Any, Event)]
collapse = foldl' step []
  where
    step acc (fp, event) =
        case List.partition ((== fp) . fst) acc of
            ([], rest) -> rest <> [(fp, event)]
            ((_, old) : _, rest) -> rest <> [(fp, merge old event)]
