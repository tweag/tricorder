module Tricorder.Session
    ( Session (..)
    , load
    , display
    )
where

import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Input (Input)
import Atelier.Effects.Log (Log)
import Data.Default (Default (..))
import Effectful.Reader.Static (Reader)
import Text.Regex.TDFA.Pattern (showPattern)

import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log qualified as Log
import Data.Text qualified as T
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime.ProjectRoot (ProjectRoot)
import Tricorder.Session.CabalFile (CabalFile)
import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate (hasPlaceholder, targetPlaceholder)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.GenerateWithHpack (GenerateWithHpack (..))
import Tricorder.Session.Hooks (Hooks)
import Tricorder.Session.IdleTimeout (IdleTimeout (..))
import Tricorder.Session.Repl (resolveRepl)
import Tricorder.Session.ReplBuildDir (ReplBuildDir (..))
import Tricorder.Session.Stage.Test.Config (TestConfig (..))
import Tricorder.Session.Target (definesCustomPrelude)
import Tricorder.Session.TestTarget (getTestTarget)
import Tricorder.Session.Util (displayList, indent)
import Tricorder.Session.WatchDirs (WatchDirs (..))
import Tricorder.Session.WatchExclusionPatterns
    ( WatchExclusionPatterns (..)
    , resolveWatchExclusionPatterns
    )

import Tricorder.Config qualified as Tricorder
import Tricorder.Session.Hooks qualified as Hooks
import Tricorder.Session.Stage.Build.Session qualified as Build (Session)
import Tricorder.Session.Stage.Build.Session qualified as Build.Session
import Tricorder.Session.Stage.Eval.Session qualified as Eval (Session)
import Tricorder.Session.Stage.Eval.Session qualified as Eval.Session
import Tricorder.Session.Stage.Test.Session qualified as Test (Session)
import Tricorder.Session.Stage.Test.Session qualified as Test.Session
import Tricorder.Session.WatchDirs qualified as WatchDirs


data Session = Session
    { buildSession :: Build.Session
    , testSession :: Test.Session
    , evalSession :: Eval.Session
    , watchDirs :: WatchDirs
    , watchExclusionPatterns :: WatchExclusionPatterns
    , replBuildDir :: ReplBuildDir
    , generateWithHpack :: GenerateWithHpack
    , hooks :: Hooks
    , idleTimeout :: IdleTimeout
    }
    deriving stock (Eq)


instance Default Session where
    def =
        Session
            { buildSession = def
            , testSession = def
            , evalSession = def
            , watchDirs = def
            , watchExclusionPatterns = def
            , replBuildDir = def
            , generateWithHpack = def
            , hooks = def
            , idleTimeout = def
            }


load
    :: ( FileSystem :> es
       , Input (Either Text Tricorder.Config) :> es
       , Input [CabalFile] :> es
       , Log :> es
       , Reader ProjectRoot :> es
       )
    => Eff es (Either Text Session)
load = do
    cfg <- Input.input

    case cfg of
        Left err -> do
            Log.err $ "Failed to parse config: " <> err
            pure $ Left $ "Failed to parse Tricorder config: " <> err
        Right (Tricorder.Config cfgFile) -> Right <$> mkSession (fromMaybe def cfgFile)


mkSession
    :: (FileSystem :> es, Input [CabalFile] :> es, Log :> es, Reader ProjectRoot :> es)
    => Config -> Eff es Session
mkSession cfgFile = do
    projectRoot <- Reader.ask @ProjectRoot
    projectFiles <- Input.input
    warnDeprecatedConfig cfgFile
    Log.debug "Warned about deprecated config stuff"

    watchExclusionPatterns <-
        case resolveWatchExclusionPatterns cfgFile.watchExclusionPatterns of
            Left err -> do
                Log.err
                    $ T.intercalate
                        "\n"
                        [ "Failed to parse watch exclusion patterns:"
                        , err
                        , "Defaulting to no exclusion patterns."
                        ]
                pure $ WatchExclusionPatterns []
            Right pts -> pure pts

    repl <- resolveRepl projectRoot
    buildSession <- Build.Session.resolve cfgFile repl projectFiles
    testSession <- Test.Session.resolve repl buildSession.targets cfgFile
    let evalSession = Eval.Session.resolve repl cfgFile
        effectiveTargets = buildSession.targets <> (getTestTarget <$> testSession.targets)
        watchDirs = WatchDirs.resolve projectRoot projectFiles cfgFile effectiveTargets

    when (not (null effectiveTargets) && all (definesCustomPrelude projectFiles) effectiveTargets)
        $ Log.warn
            "Every resolved target exposes a custom Prelude module. GHCi may \
            \fail to start because the first target's Prelude will be loaded \
            \before its package is ready. Consider adding a target that does \
            \not define its own Prelude, or set an explicit command in your \
            \tricorder configuration."

    warnMissingTargetPlaceholder "test" cfgFile.test.commandConfig.commandTemplate
    warnMissingTargetPlaceholder "eval" cfgFile.eval.commandTemplate

    warnIgnoredextraAutoArguments "build" cfgFile.build.commandTemplate cfgFile.build.extraAutoArguments
    warnIgnoredextraAutoArguments
        "test"
        cfgFile.test.commandConfig.commandTemplate
        cfgFile.test.commandConfig.extraAutoArguments
    warnIgnoredextraAutoArguments "eval" cfgFile.eval.commandTemplate cfgFile.eval.extraAutoArguments

    pure
        $ Session
            { buildSession
            , testSession
            , evalSession
            , watchDirs
            , watchExclusionPatterns
            , replBuildDir = ReplBuildDir cfgFile.replBuildDir
            , generateWithHpack = GenerateWithHpack cfgFile.generateWithHpack
            , hooks = fromMaybe def cfgFile.hooks
            , idleTimeout = IdleTimeout $ fromIntegral cfgFile.idleTimeoutSeconds
            }


-- | Warn once per session load for each deprecated top-level config key
-- still in use, regardless of whether its replacement also takes
-- precedence.
warnDeprecatedConfig :: (Log :> es) => Config -> Eff es ()
warnDeprecatedConfig cfgFile = do
    whenJust cfgFile.command
        $ const
        $ Log.warn "session.command is deprecated; use session.build.command_template instead."
    unless (null cfgFile.targets)
        $ Log.warn "session.targets is deprecated; use session.build.targets instead."
    whenJust cfgFile.testTargets
        $ const
        $ Log.warn "session.test_targets is deprecated; use session.test.targets instead."


-- | Warn when a section's @extra_auto_arguments@ is set alongside a custom
-- @command_template@, since 'Tricorder.Session.Config.extraAutoArguments'
-- would otherwise be silently ignored.
warnIgnoredextraAutoArguments :: (Log :> es) => Text -> Maybe Text -> [Text] -> Eff es ()
warnIgnoredextraAutoArguments section customTemplate extraAutoArguments =
    when (isJust customTemplate && not (null extraAutoArguments))
        $ Log.warn
        $ "session."
            <> section
            <> ".command_template is set; session."
            <> section
            <> ".extra_auto_arguments is ignored (it only applies to Tricorder's \
               \automatically resolved command)."


-- | Warn when a custom @test@\/@eval@ @command_template@ has no @{target}@
-- placeholder — without it, every invocation (one per test target or
-- module) silently runs the exact same command. @build@ isn't checked this
-- way: a missing @{targets}@ there mirrors past custom-@command@ behavior,
-- more likely deliberate than an oversight.
warnMissingTargetPlaceholder :: (Log :> es) => Text -> Maybe Text -> Eff es ()
warnMissingTargetPlaceholder section customTemplate =
    case customTemplate of
        Just tpl
            | not (hasPlaceholder targetPlaceholder tpl) ->
                Log.warn
                    $ "session."
                        <> section
                        <> ".command_template has no {target} placeholder — every "
                        <> section
                        <> " invocation will run the same command."
        _ -> pure ()


display :: Session -> Text
display session =
    T.intercalate
        "\n"
        [ "Loaded session"
        , "Build configuration:"
        , indent $ Build.Session.display session.buildSession
        , "Test configuration:"
        , indent $ Test.Session.display session.testSession
        , "Eval comments configuration:"
        , indent $ Eval.Session.display session.evalSession
        , "Watch dirs:"
        , indent $ displayList toText session.watchDirs.getWatchDirs
        , "Watch exclusion patterns:"
        , indent
            $ displayList
                (toText . showPattern . fst)
                session.watchExclusionPatterns.getWatchExclusionPatterns
        , "Repl build dir: " <> toText session.replBuildDir.getReplBuildDir
        , "Generate with hpack: " <> show session.generateWithHpack.getGenerateWithHpack
        , "Hooks:"
        , indent $ Hooks.display session.hooks
        ]
