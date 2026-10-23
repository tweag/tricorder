module Atelier.Effects.FileWatcher.Event
    ( Event (..)
    , merge
    , fromFS
    )
where

import System.FSNotify qualified as FSN


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
merge Removed Added = Added
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
