module Tricorder.Build.Changes
    ( ChangeKind (..)
    , CabalChangeDetected (..)
    , SourceChangeDetected (..)
    )
where

import Atelier.Effects.FileWatcher (FileEvent)


-- | Classifies what kind of file change triggered a dirty signal.
-- 'CabalChange' takes priority over 'SourceChange': if both fire before the
-- next build starts, the session will be fully restarted rather than reloaded.
data ChangeKind = SourceChange | CabalChange deriving stock (Eq, Ord, Show)


data CabalChangeDetected = CabalChangeDetected FilePath FileEvent
    deriving stock (Eq, Show)


data SourceChangeDetected = SourceChangeDetected FilePath FileEvent
    deriving stock (Eq, Show)
