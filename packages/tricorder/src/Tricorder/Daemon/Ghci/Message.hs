module Tricorder.Daemon.Ghci.Message (Message (..)) where

import Tricorder.Build.DiagnosticLocation (DiagnosticLocation)
import Tricorder.Daemon.Ghci.Position (Position)
import Tricorder.Daemon.Ghci.Severity (Severity)


-- | Payload for a compiler diagnostic (error or warning).
data Message = Message
    { severity :: Severity
    , file :: DiagnosticLocation
    , startPos :: Position
    , endPos :: Position
    -- ^ equals 'startPos' when no span
    , messageLines :: [Text]
    -- ^ raw lines (with any ANSI), header first
    }
    deriving stock (Eq, Show)
