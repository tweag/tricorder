module Tricorder.Session.Stage.Eval.Session
    ( EvalSession
    , display
    )
where

import Data.Text qualified as T

import Tricorder.Session.CommandTemplate (CommandTemplate)
import Tricorder.Session.Util (indent)

import Tricorder.Session.CommandTemplate qualified as CommandTemplate
import Tricorder.Session.Stage qualified as Stage


type EvalSession = CommandTemplate 'Stage.Eval


display :: EvalSession -> Text
display cfg =
    T.intercalate
        "\n"
        [ "Command template:"
        , indent $ CommandTemplate.display cfg
        ]
