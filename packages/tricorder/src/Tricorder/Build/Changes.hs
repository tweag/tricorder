module Tricorder.Build.Changes
    ( ChangeKind (..)
    , ProjectChangeDetected (..)
    , SourceChangeDetected (..)
    )
where

import Atelier.Effects.FileWatcher.Event qualified as FileWatcher (Event)
import Atelier.FileSystem.Path qualified as Path


-- | Classifies what kind of file change triggered a dirty signal.
-- 'ProjectChange' takes priority over 'SourceChange': if both fire before the
-- next build starts, the session will be fully restarted rather than reloaded.
data ChangeKind = SourceChange | ProjectChange deriving stock (Eq, Ord, Show)


data ProjectChangeDetected = ProjectChangeDetected Path.Any FileWatcher.Event
    deriving stock (Eq, Show)


data SourceChangeDetected = SourceChangeDetected Path.Any FileWatcher.Event
    deriving stock (Eq, Show)
