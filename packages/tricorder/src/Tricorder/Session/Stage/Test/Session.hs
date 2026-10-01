module Tricorder.Session.Stage.Test.Session
    ( TestSession (..)
    , ResolvedTestOptions (..)
    , resolve
    , defaultTestTemplate
    , show
    )
where

import Data.Default (Default (..))
import Prelude hiding (show)

import Data.Text qualified as T
import Prelude qualified as P

import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), targetPlaceholder)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage.Test.Config (Options (..), OutputMode (..), TestConfig (..))
import Tricorder.Session.Target (Target)
import Tricorder.Session.TestTarget (TestTarget (..))
import Tricorder.Session.Util (indent, showList)

import Tricorder.Session.CommandTemplate qualified as CommandTemplate
import Tricorder.Session.Stage qualified as Stage
import Tricorder.Session.TestTarget qualified as TestTarget


data TestSession = TestSession
    { commandTemplate :: CommandTemplate 'Stage.Test
    , targets :: [TestTarget]
    , options :: ResolvedTestOptions
    }
    deriving stock (Eq)


instance Default TestSession where
    def =
        TestSession
            { commandTemplate = def
            , targets = []
            , options = def
            }


data ResolvedTestOptions = ResolvedTestOptions
    { outputMode :: OutputMode
    }
    deriving stock (Eq)


instance Default ResolvedTestOptions where
    def = ResolvedTestOptions ReplOutput


resolve :: Repl -> [Target] -> Config -> TestSession
resolve repl buildTargets cfg =
    TestSession
        { commandTemplate =
            CommandTemplate
                { repl
                , template
                , arguments =
                    maybe
                        cfg.test.commandConfig.extraAutoArguments
                        (const [])
                        cfg.test.commandConfig.commandTemplate
                , placeholder = targetPlaceholder
                }
        , targets = TestTarget.resolve cfg buildTargets
        , options =
            ResolvedTestOptions
                { outputMode = fromMaybe detectedOutputMode cfg.test.options.outputMode
                }
        }
  where
    template = fromMaybe (defaultTestTemplate repl) cfg.test.commandConfig.commandTemplate
    detectedOutputMode
        | "stack repl" `T.isPrefixOf` template
            || "stack ghci" `T.isPrefixOf` template
            || "cabal repl" `T.isPrefixOf` template =
            ReplOutput
        | otherwise = StdoutOutput


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
        , indent $ showList TestTarget.render cfg.targets
        , "Options:"
        , indent $ showTestOptions cfg.options
        ]
  where
    showTestOptions opts =
        T.intercalate
            "\n"
            [ "Output mode: " <> P.show opts.outputMode
            ]
