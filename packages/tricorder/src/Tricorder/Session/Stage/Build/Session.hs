module Tricorder.Session.Stage.Build.Session
    ( BuildSession (..)
    , resolve
    , show
    )
where

import Atelier.Effects.FileSystem (FileSystem)
import Data.Default (Default (..))
import Effectful.Reader.Static (Reader)
import Prelude hiding (show)

import Data.Text qualified as T
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.CabalFile (CabalFile)
import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate (CommandTemplate)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Repl (Repl)
import Tricorder.Session.Target (Target, resolveTargets)
import Tricorder.Session.Util (indent, showList)

import Tricorder.Session.CommandTemplate qualified as CommandTemplate
import Tricorder.Session.Stage qualified as Stage
import Tricorder.Session.Stage.Build.Command qualified as BuildCommand
import Tricorder.Session.Target qualified as Target


data BuildSession = BuildSession
    { commandTemplate :: CommandTemplate 'Stage.Build
    , targets :: [Target]
    }
    deriving stock (Eq)


instance Default BuildSession where
    def = BuildSession def []


resolve
    :: (FileSystem :> es, Reader ProjectRoot :> es)
    => Config -> Repl -> [CabalFile] -> Eff es BuildSession
resolve config repl projectFiles = do
    projectRoot <- Reader.ask
    (commandTemplate, targets) <- BuildCommand.resolve projectRoot config repl effectiveTargets
    pure
        $ BuildSession
            { commandTemplate
            , targets
            }
  where
    rawBuildTargets = fromMaybe config.targets config.build.targets
    effectiveTargets = resolveTargets projectFiles rawBuildTargets


show :: BuildSession -> Text
show cfg =
    T.intercalate
        "\n"
        [ "Command template:"
        , indent $ CommandTemplate.show cfg.commandTemplate
        , "Targets:"
        , indent $ showList Target.renderTarget cfg.targets
        ]
