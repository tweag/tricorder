module Tricorder.Session.Stage.Eval.Session
    ( EvalSession (..)
    , resolve
    , display
    )
where

import Data.Default (Default (..))

import Data.Text qualified as T

import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), targetPlaceholder)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Repl (Repl)
import Tricorder.Session.Stage.Test.Session (defaultTestTemplate)
import Tricorder.Session.Util (indent)

import Tricorder.Daemon.Ghci.Config qualified as Ghci (Config)
import Tricorder.Daemon.Ghci.Config qualified as Ghci.Config
import Tricorder.Daemon.Ghci.Config.File qualified as Ghci.Config.File
import Tricorder.Session.CommandTemplate qualified as CommandTemplate
import Tricorder.Session.Stage qualified as Stage


data EvalSession = EvalSession
    { commandTemplate :: CommandTemplate 'Stage.Eval
    , ghci :: Ghci.Config
    }
    deriving stock (Eq)


instance Default EvalSession where
    def = EvalSession def def


resolve :: Repl -> Config -> EvalSession
resolve repl cfg =
    EvalSession
        { commandTemplate =
            CommandTemplate
                { repl
                , template = fromMaybe (defaultEvalTemplate repl) cfg.eval.commandTemplate
                , arguments = maybe cfg.eval.extraAutoArguments (const []) cfg.eval.commandTemplate
                , placeholder = targetPlaceholder
                }
        , ghci = maybe def Ghci.Config.File.toConfig cfg.eval.ghci
        }


display :: EvalSession -> Text
display cfg =
    T.intercalate
        "\n"
        [ "Command template:"
        , indent $ CommandTemplate.display cfg.commandTemplate
        , "GHCi config:"
        , indent $ Ghci.Config.display cfg.ghci
        ]


defaultEvalTemplate :: Repl -> Text
defaultEvalTemplate = defaultTestTemplate
