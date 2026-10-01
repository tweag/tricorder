module Tricorder.Session.Stage.Test.Session
    ( TestSession (..)
    , resolve
    , defaultTestTemplate
    , show
    )
where

import Data.Default (Default (..))
import Prelude hiding (show)

import Data.Text qualified as T

import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), targetPlaceholder)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Target (Target)
import Tricorder.Session.TestTarget (TestTarget (..), resolveTestTargets)
import Tricorder.Session.Util (indent, showList)

import Tricorder.Session.CommandTemplate qualified as CommandTemplate
import Tricorder.Session.Stage qualified as Stage
import Tricorder.Session.TestTarget qualified as TestTarget


data TestSession = TestSession
    { commandTemplate :: CommandTemplate 'Stage.Test
    , targets :: [TestTarget]
    }
    deriving stock (Eq)


instance Default TestSession where
    def =
        TestSession
            { commandTemplate = def
            , targets = []
            }


resolve :: Repl -> [Target] -> Config -> TestSession
resolve repl buildTargets cfg =
    TestSession
        { commandTemplate =
            CommandTemplate
                { repl
                , template
                , arguments = maybe cfg.test.extraAutoArguments (const []) cfg.test.commandTemplate
                , placeholder = targetPlaceholder
                }
        , targets = resolveTestTargets cfg buildTargets
        }
  where
    template = fromMaybe (defaultTestTemplate repl) cfg.test.commandTemplate


defaultTestTemplate :: Repl -> Text
defaultTestTemplate = \case
    Stack -> "stack ghci {target}"
    StackMulti -> "stack ghci {target}"
    Cabal -> "cabal repl {target}"
    Unknown -> "cabal repl {target}"


show :: TestSession -> Text
show cfg =
    T.intercalate
        "\n"
        [ "Command template:"
        , indent $ CommandTemplate.show cfg.commandTemplate
        , "Test targets:"
        , indent $ showList TestTarget.renderTestTarget cfg.targets
        ]
