module Tricorder.Session.Command.RenderedCommand (RenderedCommand (..)) where

import Tricorder.Session.Stage (Stage (..))


-- | A fully rendered, ready-to-spawn shell command, tagged with the 'Stage'
-- it was rendered for.
newtype RenderedCommand (stage :: Stage) = RenderedCommand {getRenderedCommand :: Text}
    deriving (Eq, Show) via Text
