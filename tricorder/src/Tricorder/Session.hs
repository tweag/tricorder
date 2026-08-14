module Tricorder.Session
    ( Session (..)
    , loadSession
    , inputSession
    ) where

import Atelier.Config (LoadedConfig, extractConfig)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Input (Input, input, runInputEff)
import Atelier.Effects.Log (Log)
import Data.Default (Default (..))
import Effectful.Reader.Static (Reader, ask)

import Atelier.Effects.Log qualified as Log
import Data.Text qualified as T

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.CabalFile (CabalFile)
import Tricorder.Session.Command (Command (..), resolveCommand)
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.GenerateWithHpack (GenerateWithHpack (..))
import Tricorder.Session.ReplBuildDir (ReplBuildDir (..))
import Tricorder.Session.Target (Target, definesCustomPrelude, resolveTargets)
import Tricorder.Session.TestTarget (TestTarget, resolveTestTargets)
import Tricorder.Session.TestTimeout (TestTimeout (..))
import Tricorder.Session.WatchDirs (WatchDirs (..), resolveWatchDirs)
import Tricorder.Session.WatchExclusionPatterns (WatchExclusionPatterns (..), resolveWatchExclusionPatterns)


data Session = Session
    { command :: Command
    , targets :: [Target]
    , testTargets :: [TestTarget]
    , watchDirs :: WatchDirs
    , watchExclusionPatterns :: WatchExclusionPatterns
    , replBuildDir :: ReplBuildDir
    , testTimeout :: TestTimeout
    , generateWithHpack :: GenerateWithHpack
    }
    deriving stock (Eq)


instance Default Session where
    def =
        Session
            { command = def
            , targets = []
            , testTargets = []
            , watchDirs = def
            , watchExclusionPatterns = def
            , replBuildDir = def
            , testTimeout = def
            , generateWithHpack = def
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
        effectiveTargets = resolveTargets projectFiles cfgFile.targets
        testTargets = resolveTestTargets cfgFile effectiveTargets
        watchDirs = resolveWatchDirs projectRoot projectFiles cfgFile effectiveTargets

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

    command <- resolveCommand projectRoot cfgFile effectiveTargets testTargets

    pure
        $ Session
            { targets = effectiveTargets
            , command
            , watchDirs
            , watchExclusionPatterns
            , testTargets
            , replBuildDir = ReplBuildDir cfgFile.replBuildDir
            , testTimeout = TestTimeout cfgFile.testTimeout
            , generateWithHpack = GenerateWithHpack cfgFile.generateWithHpack
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
