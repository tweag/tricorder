module Tricorder.Session.Stage.Test.Session
    ( Session (..)
    , ResolvedTestOptions (..)
    , resolve
    , defaultTestTemplate
    , display
    )
where

import Atelier.Effects.Log (Log)
import Atelier.Time (Millisecond)
import Data.Default (Default (..))

import Atelier.Effects.Log qualified as Log
import Atelier.Time qualified as Time
import Data.Text qualified as T

import Tricorder.Build.ByteSize (ByteSize)
import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), targetPlaceholder)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage.Test.Config (Options (..), OutputMode (..), TestConfig (..))
import Tricorder.Session.Target (Target)
import Tricorder.Session.TestTarget (TestTarget (..))
import Tricorder.Session.Util (displayList, indent)

import Tricorder.Build.ByteSize qualified as ByteSize
import Tricorder.Daemon.Ghci.Config qualified as Ghci (Config)
import Tricorder.Daemon.Ghci.Config qualified as Ghci.Config
import Tricorder.Daemon.Ghci.Config.File qualified as Ghci.Config.File
import Tricorder.Session.CommandTemplate qualified as CommandTemplate
import Tricorder.Session.Stage qualified as Stage
import Tricorder.Session.TestTarget qualified as TestTarget


data Session = Session
    { commandTemplate :: CommandTemplate 'Stage.Test
    , targets :: [TestTarget]
    , options :: ResolvedTestOptions
    , ghci :: Ghci.Config
    }
    deriving stock (Eq)


instance Default Session where
    def =
        Session
            { commandTemplate = def
            , targets = []
            , options = def
            , ghci = def
            }


data ResolvedTestOptions = ResolvedTestOptions
    { outputMode :: OutputMode
    , timeout :: Millisecond
    , memoryLimit :: Maybe ByteSize
    }
    deriving stock (Eq)


instance Default ResolvedTestOptions where
    def =
        ResolvedTestOptions
            { outputMode = ReplOutput
            , timeout = 10
            , memoryLimit = Nothing
            }


resolve :: (Log :> es) => Repl -> [Target] -> Config -> Eff es Session
resolve repl buildTargets cfg = Log.withNamespace "session.test" do
    memoryLimit <- case cfg.test.options.memoryLimit of
        Nothing -> pure Nothing
        Just limit -> case ByteSize.fromText limit of
            Nothing -> do
                Log.warn $ "Unable to parse options.memory_limit: " <> limit
                Log.info "Continuing with no memory limit."
                pure Nothing
            Just parsedLimit ->
                pure $ Just parsedLimit
    pure
        $ Session
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
                    , timeout = maybe 10 Time.getAsRawUnit cfg.test.options.timeoutMs
                    , memoryLimit
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


display :: Session -> Text
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
            , "Timeout: " <> show opts.timeout
            , "Memory limit: " <> maybe "<unlimited>" show opts.memoryLimit
            ]
