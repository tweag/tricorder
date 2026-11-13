module Tricorder.Build.Changes
    ( ChangeKind (..)
    , CabalChangeDetected (..)
    , SourceChangeDetected (..)
    )
where

import Atelier.Effects.FileWatcher.Event qualified as FileWatcher (Event)
import Atelier.FileSystem.Path qualified as Path


-- | Classifies what kind of file change triggered a dirty signal.
-- 'CabalChange' takes priority over 'SourceChange': if both fire before the
-- next build starts, the session will be fully restarted rather than reloaded.
data ChangeKind = SourceChange | CabalChange deriving stock (Eq, Ord, Show)


data CabalChangeDetected = CabalChangeDetected Path.Any FileWatcher.Event
    deriving stock (Eq, Show)


data SourceChangeDetected = SourceChangeDetected Path.Any FileWatcher.Event
    deriving stock (Eq, Show)
