module Tricorder.Session.Stage.Eval.Command
    ( render
    , resolve
    )
where

import Tricorder.Session.Command.RenderedCommand (RenderedCommand (..))
import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), renderText, targetPlaceholder)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Repl (Repl)
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Stage.Test.Session (defaultTestTemplate)
import Tricorder.Session.Target (Target)


-- | Render the @eval@ command for a single source file's short-lived
-- session: the module being evaluated is substituted as the one target.
render :: CommandTemplate 'Eval -> [Target] -> RenderedCommand 'Eval
render commandTemplate targets = RenderedCommand $ renderText commandTemplate targets


resolve :: Repl -> Config -> CommandTemplate 'Eval
resolve repl cfg =
    CommandTemplate
        { repl
        , template = fromMaybe (defaultEvalTemplate repl) cfg.eval.commandTemplate
        , arguments = maybe cfg.eval.extraAutoArguments (const []) cfg.eval.commandTemplate
        , placeholder = targetPlaceholder
        }


defaultEvalTemplate :: Repl -> Text
defaultEvalTemplate = defaultTestTemplate
