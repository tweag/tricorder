module Tricorder.Session
    ( Session (..)
    , loadSession
    , inputSession
    )
where

import Atelier.Config (LoadedConfig, extractConfig)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Input (Input, input, runInputEff)
import Atelier.Effects.Log (Log)
import Data.Default (Default (..))
import Effectful.Reader.Static (Reader, ask)

import Atelier.Effects.Log qualified as Log
import Data.Text qualified as T

import Tricorder.Build.ByteSize (ByteSize)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.CabalFile (CabalFile)
import Tricorder.Session.Command
    ( CommandTemplate (..)
    , hasPlaceholder
    , targetPlaceholder
    )
import Tricorder.Session.Command.Build (resolveBuildCommand)
import Tricorder.Session.Command.Eval (resolveEvalCommand)
import Tricorder.Session.Command.Test (resolveTestCommand)
import Tricorder.Session.Config (CommandConfig (..), Config (..))
import Tricorder.Session.GenerateWithHpack (GenerateWithHpack (..))
import Tricorder.Session.Hooks (Hooks)
import Tricorder.Session.IdleTimeout (IdleTimeout (..))
import Tricorder.Session.Repl (resolveRepl)
import Tricorder.Session.ReplBuildDir (ReplBuildDir (..))
import Tricorder.Session.Target (Target, definesCustomPrelude, resolveTargets)
import Tricorder.Session.TestTarget (TestTarget, resolveTestTargets)
import Tricorder.Session.TestTimeout (TestTimeout (..))
import Tricorder.Session.WatchDirs (WatchDirs (..), resolveWatchDirs)
import Tricorder.Session.WatchExclusionPatterns
    ( WatchExclusionPatterns (..)
    , resolveWatchExclusionPatterns
    )

import Tricorder.Build.ByteSize qualified as ByteSize
import Tricorder.Session.Stage qualified as Stage


data Session = Session
    { build :: CommandTemplate 'Stage.Build
    , buildTargets :: [Target]
    -- ^ The target(s) to 'Tricorder.Session.Command.render' 'build' with.
    -- Usually equal to 'targets', except when that's empty (no components
    -- could be auto-detected at all), in which case this falls back to
    -- @all@ plus the discovered test targets — see
    -- 'Tricorder.Session.Command.resolveBuildCommand'.
    , test :: CommandTemplate 'Stage.Test
    , eval :: CommandTemplate 'Stage.Eval
    , targets :: [Target]
    , testTargets :: [TestTarget]
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
            { build = def
            , buildTargets = []
            , test = def
            , eval = def
            , targets = []
            , testTargets = []
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
    projectFiles <- input

    let cfgFile = extractConfig @"session" @Config loadedCfg
        rawBuildTargets = fromMaybe cfgFile.targets cfgFile.build.targets
        effectiveTargets = resolveTargets projectFiles rawBuildTargets
        testTargets = resolveTestTargets cfgFile effectiveTargets
        watchDirs = resolveWatchDirs projectRoot projectFiles cfgFile effectiveTargets
        hooks = fromMaybe def cfgFile.hooks

    warnDeprecatedConfig cfgFile

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

    when (not (null effectiveTargets) && all (definesCustomPrelude projectFiles) effectiveTargets)
        $ Log.warn
            "Every resolved target exposes a custom Prelude module. GHCi may \
            \fail to start because the first target's Prelude will be loaded \
            \before its package is ready. Consider adding a target that does \
            \not define its own Prelude, or set an explicit command in your \
            \tricorder configuration."

    repl <- resolveRepl projectRoot
    (build, buildTargets) <- resolveBuildCommand projectRoot cfgFile repl effectiveTargets testTargets
    let test = resolveTestCommand repl cfgFile
        eval = resolveEvalCommand repl cfgFile

    warnMissingTargetPlaceholder "test" cfgFile.test.commandTemplate
    warnMissingTargetPlaceholder "eval" cfgFile.eval.commandTemplate

    warnIgnoredextraAutoArguments
        "build"
        (cfgFile.build.commandTemplate <|> cfgFile.command)
        cfgFile.build.extraAutoArguments
    warnIgnoredextraAutoArguments "test" cfgFile.test.commandTemplate cfgFile.test.extraAutoArguments
    warnIgnoredextraAutoArguments "eval" cfgFile.eval.commandTemplate cfgFile.eval.extraAutoArguments

    pure
        $ Session
            { targets = effectiveTargets
            , build
            , buildTargets
            , test
            , eval
            , watchDirs
            , watchExclusionPatterns
            , testMemoryLimit
            , testTargets
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


-- | Warn, once per session load, for each deprecated top-level config key
-- that is present — regardless of whether its replacement is also set and
-- takes precedence. See @packages/tricorder/proposals/009-…@ for the
-- deprecation policy (removed no earlier than 3 major version bumps after
-- the release that introduces this warning).
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
-- @command_template@ for that section — @extra_auto_arguments@ only ever applies
-- to Tricorder's automatically resolved command (see
-- 'Tricorder.Session.Config.CommandConfig'), so it is silently ignored in
-- that combination; this makes the ignoring visible instead.
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


-- | Warn when a user-supplied @test@/@eval@ @command_template@ has no
-- @{target}@ placeholder. Both @test@ and @eval@ spawn one process per
-- target (one test suite, one module being evaluated) — with no
-- placeholder, that per-invocation target is never substituted in, so
-- every invocation silently runs the exact same command against whatever
-- is hardcoded in the template. @build@ is not checked this way: its
-- placeholder is @{targets}@ (plural), and a missing one there mirrors
-- today's behavior for a fully custom @command@, which is far more likely
-- to be a deliberate fixed-target template than an oversight.
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
