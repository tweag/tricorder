module Tricorder.Session.Stage.Test.Session
    ( TestSession (..)
    , ResolvedTestOptions (..)
    , resolve
    , defaultTestTemplate
    , display
    )
where

import Data.Default (Default (..))

import Data.Text qualified as T

import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), targetPlaceholder)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage.Test.Config (Options (..), OutputMode (..), TestConfig (..))
import Tricorder.Session.Target (Target)
import Tricorder.Session.TestTarget (TestTarget (..))
import Tricorder.Session.Util (displayList, indent)

import Tricorder.Daemon.Ghci.Config qualified as Ghci (Config)
import Tricorder.Daemon.Ghci.Config qualified as Ghci.Config
import Tricorder.Daemon.Ghci.Config.File qualified as Ghci.Config.File
import Tricorder.Session.CommandTemplate qualified as CommandTemplate
import Tricorder.Session.Stage qualified as Stage
import Tricorder.Session.TestTarget qualified as TestTarget


data TestSession = TestSession
    { commandTemplate :: CommandTemplate 'Stage.Test
    , targets :: [TestTarget]
    , options :: ResolvedTestOptions
    , ghci :: Ghci.Config
    }
    deriving stock (Eq)


instance Default TestSession where
    def =
        TestSession
            { commandTemplate = def
            , targets = []
            , options = def
            , ghci = def
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
        , ghci = maybe def Ghci.Config.File.toConfig cfg.test.commandConfig.ghci
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


display :: TestSession -> Text
display cfg =
    T.intercalate
        "\n"
        [ "Command template:"
        , indent $ CommandTemplate.display cfg.commandTemplate
        , "Test targets:"
        , indent $ displayList TestTarget.render cfg.targets
        , "Options:"
        , indent $ showTestOptions cfg.options
        , "GHCi config:"
        , indent $ Ghci.Config.display cfg.ghci
        ]
  where
    showTestOptions opts =
        T.intercalate
            "\n"
            [ "Output mode: " <> show opts.outputMode
            ]
