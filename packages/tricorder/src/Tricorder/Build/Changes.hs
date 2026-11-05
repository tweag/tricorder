module Tricorder.Build.Changes
    ( ChangeKind (..)
    , ProjectChangeDetected (..)
    , SourceChangeDetected (..)
    )
where

import Atelier.Effects.FileWatcher.Event qualified as FileWatcher (Event)


-- | Classifies what kind of file change triggered a dirty signal.
-- 'ProjectChange' takes priority over 'SourceChange': if both fire before the
-- next build starts, the session will be fully restarted rather than reloaded.
data ChangeKind = SourceChange | ProjectChange deriving stock (Eq, Ord, Show)


data ProjectChangeDetected = ProjectChangeDetected FilePath FileWatcher.Event
    deriving stock (Eq, Show)


data SourceChangeDetected = SourceChangeDetected FilePath FileWatcher.Event
    deriving stock (Eq, Show)
