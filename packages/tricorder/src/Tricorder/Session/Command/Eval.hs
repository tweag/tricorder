module Tricorder.Session.Command.Eval
    ( renderEval
    , resolveEvalCommand
    )
where

import Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..))
import Tricorder.Session.Command.Test (defaultTestTemplate)
import Tricorder.Session.CommandTemplate (CommandTemplate (..), renderText, targetPlaceholder)
import Tricorder.Session.Config (CommandConfig (..), Config (..))
import Tricorder.Session.Repl (Repl)
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Target (Target)


-- | Render the @eval@ command for a single source file's short-lived
-- session: the module being evaluated is substituted as the one target.
renderEval :: CommandTemplate 'Eval -> [Target] -> ResolvedCommand 'Eval
renderEval commandTemplate targets = ResolvedCommand $ renderText commandTemplate targets


resolveEvalCommand :: Repl -> Config -> CommandTemplate 'Eval
resolveEvalCommand repl cfg =
    CommandTemplate
        { repl
        , template = fromMaybe (defaultEvalTemplate repl) cfg.eval.commandTemplate
        , arguments = maybe cfg.eval.extraAutoArguments (const []) cfg.eval.commandTemplate
        , placeholder = targetPlaceholder
        }


defaultEvalTemplate :: Repl -> Text
defaultEvalTemplate = defaultTestTemplate
