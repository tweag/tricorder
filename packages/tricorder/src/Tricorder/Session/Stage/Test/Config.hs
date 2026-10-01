module Tricorder.Session.Stage.Test.Config
    ( TestConfig
    )
where

import Tricorder.Session.CommandConfig (CommandConfig)

import Tricorder.Session.Stage qualified as Stage


type TestConfig = CommandConfig 'Stage.Test
