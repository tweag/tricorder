module Tricorder.Session.Stage.Build.Command
    ( render
    , resolve
    )
where

import Atelier.Effects.FileSystem (FileSystem)
import System.FilePath ((</>))

import Atelier.Effects.FileSystem qualified as FileSystem
import Data.List qualified as List

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..))
import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), renderText, targetsPlaceholder)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Target (Target (..))


-- | Render the @build@ command: every target goes into the one invocation
-- that covers all of them.
render :: CommandTemplate 'Build -> [Target] -> ResolvedCommand 'Build
render commandTemplate targets = ResolvedCommand $ renderText commandTemplate targets


resolve
    :: (FileSystem :> es)
    => ProjectRoot
    -> Config
    -> Repl
    -> [Target]
    -> Eff es (CommandTemplate 'Build, [Target])
resolve projectRoot cfg repl effectiveTargets = do
    template <- case customTemplate of
        Just tpl -> pure tpl
        Nothing -> defaultBuildTemplate projectRoot repl cfg.replBuildDir
    pure
        ( CommandTemplate
            { repl
            , template
            , arguments = maybe cfg.build.extraAutoArguments (const []) customTemplate
            , placeholder = targetsPlaceholder
            }
        , if not (null effectiveTargets)
            then effectiveTargets
            else [Bare "all"]
        )
  where
    customTemplate = cfg.build.commandTemplate <|> cfg.command


-- | Whether the project has a @cabal.project@ or any @*.cabal@ file. Used
-- only to pick the automatically resolved template's flags — it has no
-- bearing on 'Repl', which is 'Cabal' either way.
isCabalProject :: (FileSystem :> es) => ProjectRoot -> Eff es Bool
isCabalProject (ProjectRoot projectRoot) = do
    hasCabalProject <- FileSystem.doesFileExist $ projectRoot </> "cabal.project"
    hasCabalFiles <- any (".cabal" `List.isSuffixOf`) <$> FileSystem.listDirectory projectRoot
    pure $ hasCabalProject || hasCabalFiles


-- | Tricorder's automatically resolved @build@ template for a resolved
-- 'Repl'. Cabal projects additionally probe the filesystem to decide whether
-- @--enable-multi-repl@ applies.
defaultBuildTemplate :: (FileSystem :> es) => ProjectRoot -> Repl -> FilePath -> Eff es Text
defaultBuildTemplate projectRoot repl replBuildDir = case repl of
    Stack -> pure "stack ghci {targets}"
    StackMulti -> pure "stack ghci {targets}"
    Unknown -> pure "cabal repl {targets}"
    Cabal -> do
        isProject <- isCabalProject projectRoot
        pure
            $ if isProject
                then "cabal repl --enable-multi-repl --builddir " <> toText replBuildDir <> " {targets}"
                else "cabal repl --builddir " <> toText replBuildDir <> " {targets}"
