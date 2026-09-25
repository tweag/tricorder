module Tricorder.Session.Command.Build
    ( renderBuild
    , resolveBuildCommand
    )
where

import Atelier.Effects.FileSystem (FileSystem)
import System.FilePath ((</>))

import Atelier.Effects.FileSystem qualified as FileSystem
import Data.List qualified as List

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Command (CommandTemplate (..), renderText, targetsPlaceholder)
import Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..))
import Tricorder.Session.Config (CommandConfig (..), Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Target (Target (..))
import Tricorder.Session.TestTarget (TestTarget (..))


-- | Render the @build@ command: every target is substituted into the one
-- invocation that covers all of them. See 'Tricorder.Session.resolveBuildCommand'
-- for how the target list this is rendered with is resolved.
renderBuild :: CommandTemplate 'Build -> [Target] -> ResolvedCommand 'Build
renderBuild commandTemplate targets = ResolvedCommand $ renderText commandTemplate targets


-- | Resolve the effective build command: a 'CommandTemplate' (user's
-- 'commandTemplate', else the deprecated top-level 'command', else
-- Tricorder's automatically resolved template for the resolved 'Repl'), and
-- the target list to 'renderBuild' it with.
--
-- 'extraAutoArguments' only applies when no custom template is in play
-- (neither 'commandTemplate' nor the deprecated 'command' is set) —
-- see 'Tricorder.Session.Config.CommandConfig'.
--
-- 'effectiveTargets' is the already-resolved build target list (config
-- targets, or every auto-detected component when none are configured — see
-- 'Tricorder.Session.Target.resolveTargets'). When it's empty (no components
-- could be auto-detected at all — e.g. no cabal files found), the returned
-- target list falls back to @"all"@ plus the discovered test targets,
-- mirroring the previous 'Tricorder.Session.Target' auto-detection
-- fallback.
resolveBuildCommand
    :: (FileSystem :> es)
    => ProjectRoot
    -> Config
    -> Repl
    -> [Target]
    -> [TestTarget]
    -> Eff es (CommandTemplate 'Build, [Target])
resolveBuildCommand projectRoot cfg repl effectiveTargets testTargets = do
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
            else Bare "all" : (getTestTarget <$> testTargets)
        )
  where
    customTemplate = cfg.build.commandTemplate <|> cfg.command


-- | Whether the project looks like a multi-package (or at least
-- project-file-having) cabal project: a @cabal.project@ file, or at least
-- one @*.cabal@ file, at the project root. Used only to pick the
-- automatically resolved build template's flags ('defaultBuildTemplate'); it
-- has no bearing on 'Repl', which is 'Cabal' either way.
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
