module Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..)) where

import Tricorder.Session.Stage (Stage (..))


-- | A fully rendered, ready-to-spawn shell command, tagged with the 'Stage'
-- it was rendered for.
newtype ResolvedCommand (stage :: Stage) = ResolvedCommand {getResolvedCommand :: Text}
    deriving stock (Eq, Show)
