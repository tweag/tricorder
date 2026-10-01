module Tricorder.Session
    ( Session (..)
    , loadSession
    , inputSession
    , show
    )
where

import Atelier.Config (LoadedConfig, extractConfig)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Input (Input, input, runInputEff)
import Atelier.Effects.Log (Log)
import Data.Default (Default (..))
import Effectful.Reader.Static (Reader, ask)
import Text.Regex.TDFA.Pattern (showPattern)
import Prelude hiding (show)

import Atelier.Effects.Log qualified as Log
import Data.Text qualified as T
import Prelude qualified as P

import Tricorder.Build.ByteSize (ByteSize)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.CabalFile (CabalFile)
import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.CommandTemplate
    ( CommandTemplate (..)
    , hasPlaceholder
    , targetPlaceholder
    )
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.GenerateWithHpack (GenerateWithHpack (..))
import Tricorder.Session.Hooks (Hooks)
import Tricorder.Session.IdleTimeout (IdleTimeout (..))
import Tricorder.Session.Repl (resolveRepl)
import Tricorder.Session.ReplBuildDir (ReplBuildDir (..))
import Tricorder.Session.Stage.Build.Session (BuildSession (..))
import Tricorder.Session.Stage.Test.Config (TestConfig (..))
import Tricorder.Session.Stage.Test.Session (TestSession (..))
import Tricorder.Session.Target (definesCustomPrelude)
import Tricorder.Session.TestTarget (getTestTarget)
import Tricorder.Session.TestTimeout (TestTimeout (..))
import Tricorder.Session.Util (indent, showList)
import Tricorder.Session.WatchDirs (WatchDirs (..))
import Tricorder.Session.WatchExclusionPatterns
    ( WatchExclusionPatterns (..)
    , resolveWatchExclusionPatterns
    )

import Tricorder.Build.ByteSize qualified as ByteSize
import Tricorder.Session.Stage qualified as Stage
import Tricorder.Session.Stage.Build.Session qualified as BuildSession
import Tricorder.Session.Stage.Eval.Command qualified as EvalCommand
import Tricorder.Session.Stage.Eval.Session qualified as EvalSession
import Tricorder.Session.Stage.Test.Session qualified as TestSession
import Tricorder.Session.WatchDirs qualified as WatchDirs


data Session = Session
    { buildSession :: BuildSession
    , testSession :: TestSession
    , evalSession :: CommandTemplate 'Stage.Eval
    , testMemoryLimit :: Maybe ByteSize
    , watchDirs :: WatchDirs
    , watchExclusionPatterns :: WatchExclusionPatterns
    , replBuildDir :: ReplBuildDir
    , testTimeout :: TestTimeout
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
            , testMemoryLimit = Nothing
            , watchDirs = def
            , watchExclusionPatterns = def
            , replBuildDir = def
            , testTimeout = def
            , generateWithHpack = def
            , hooks = def
            , idleTimeout = def
            }


loadSession
    :: ( FileSystem :> es
       , Input LoadedConfig :> es
       , Input [CabalFile] :> es
       , Log :> es
       , Reader ProjectRoot :> es
       )
    => Eff es Session
loadSession = do
    projectRoot <- ask @ProjectRoot
    loadedCfg <- input
    Log.debug "Got config file"
    projectFiles <- input
    Log.debug "Got project files"

    let cfgFile = extractConfig @"session" @Config loadedCfg
        hooks = fromMaybe def cfgFile.hooks

    warnDeprecatedConfig cfgFile
    Log.debug "Warned about deprecated config stuff"

    testMemoryLimit <- case cfgFile.testMemoryLimit of
        Nothing -> pure Nothing
        Just limit -> case ByteSize.fromText limit of
            Nothing -> do
                Log.err $ "Unable to parse test_memory_limit: " <> limit
                pure Nothing
            Just parsedLimit ->
                pure $ Just parsedLimit

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
    buildSession <- BuildSession.resolve cfgFile repl projectFiles
    let testSession = TestSession.resolve repl buildSession.targets cfgFile
        evalSession = EvalCommand.resolve repl cfgFile
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

    warnIgnoredextraAutoArguments
        "build"
        (cfgFile.build.commandTemplate <|> cfgFile.command)
        cfgFile.build.extraAutoArguments
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
            , testMemoryLimit
            , replBuildDir = ReplBuildDir cfgFile.replBuildDir
            , testTimeout = TestTimeout cfgFile.testTimeout
            , generateWithHpack = GenerateWithHpack cfgFile.generateWithHpack
            , hooks
            , idleTimeout = IdleTimeout $ fromIntegral cfgFile.idleTimeoutSeconds
            }


inputSession
    :: ( FileSystem :> es
       , Input LoadedConfig :> es
       , Input [CabalFile] :> es
       , Log :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Input Session : es) a -> Eff es a
inputSession = runInputEff loadSession


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


show :: Session -> Text
show session =
    T.intercalate
        "\n"
        [ "Loaded session"
        , "Build configuration:"
        , indent $ BuildSession.show session.buildSession
        , "Test configuration:"
        , indent $ TestSession.show session.testSession
        , "Eval comments configuration:"
        , indent $ EvalSession.show session.evalSession
        , "Watch dirs:"
        , indent $ showList toText session.watchDirs.getWatchDirs
        , "Watch exclusion patterns:"
        , indent
            $ showList
                (toText . showPattern . fst)
                session.watchExclusionPatterns.getWatchExclusionPatterns
        , "Repl build dir: " <> toText session.replBuildDir.getReplBuildDir
        , -- TODO: Remove " seconds" when TestTimeout is converted to a proper time unit.
          "Test timeout: " <> P.show session.testTimeout.getTestTimeout <> " seconds"
        , "Test memory limit: " <> P.show session.testMemoryLimit
        , "Generate with hpack: " <> P.show session.generateWithHpack.getGenerateWithHpack
        ]
