module Tricorder.Session.Stage.Eval.Command
    ( render
    )
where

import Tricorder.Session.Command.RenderedCommand (RenderedCommand (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), renderText)
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Target (Target)


-- | Render the @eval@ command for a single source file's short-lived
-- session: the module being evaluated is substituted as the one target.
render :: CommandTemplate 'Eval -> [Target] -> RenderedCommand 'Eval
render commandTemplate targets = RenderedCommand $ renderText commandTemplate targets
