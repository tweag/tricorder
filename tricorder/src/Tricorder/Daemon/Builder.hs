module Tricorder.Daemon.Builder
    ( Builder (..)
    , build
    , consider
    , BuildConsideration (..)
    , BuildFailure (..)
    , with
    , compileBuildResults
    , BuildConfig (..)

      -- * Internals exposed for testing
    , NewLoadResult (..)
    , EnteringNewPhase (..)
    , compileLoadResultsIntoBuildResults
    ) where

import Atelier.Effects.Clock (Clock, UTCTime)
import Atelier.Effects.FileWatcher (FileEvent)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Publishing.Pub (Pub)
import Atelier.Time (Millisecond, nominalDiffTime)
import Data.Default (Default (..))
import Data.Time (diffUTCTime)
import Effectful (Effect, inject)
import Effectful.Dispatch.Dynamic (reinterpretWith_)
import Effectful.Exception (trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, get, modify)
import Effectful.TH (makeEffect)
import System.FilePath (normalise)

import Atelier.Effects.Clock qualified as Clock
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Publishing.Pub qualified as Pub
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Effectful.State.Static.Shared qualified as State

import Tricorder.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildResult (..)
    , Diagnostic (..)
    )
import Tricorder.BuildState.BuildProgress (BuildProgress)
import Tricorder.Daemon.Dispatch
    ( BuilderState (..)
    , DiagnosticMap
    , DispatchAction (..)
    , KnownTargetNames (..)
    , dispatch
    , emptyBuilderState
    , filterToWatchDirs
    , mergeDiagnostics
    , preserveFailureVisibility
    )
import Tricorder.Effects.GhciSession (GhciSession, LoadResult (..))
import Tricorder.Effects.GhciSession.GhciParser (resolveKnownTargets)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session
    ( Command (..)
    , Session (..)
    , Target
    , TestTargets
    , WatchDirs
    )

import Tricorder.Effects.GhciSession qualified as GhciSession


data Builder :: Effect where
    Consider :: FilePath -> FileEvent -> Builder m BuildConsideration
    Build :: DispatchAction -> Builder m (Either BuildFailure NewLoadResult)


data BuildConsideration
    = SkipBuilding
    | ShouldBuild DispatchAction


data BuildFailure
    = ReloadFailed SomeException
    deriving stock (Show)


data NewLoadResult = NewLoadResult
    { startTime :: UTCTime
    , endTime :: UTCTime
    , loadResult :: LoadResult
    }
    deriving stock (Eq, Show)


makeEffect ''Builder


-- | A subset of 'Session' with just the properties that 'Builder' cares about.
data BuildConfig = BuildConfig
    { command :: Command
    , targets :: [Target]
    , testTargets :: TestTargets
    , watchDirs :: WatchDirs
    }
    deriving stock (Eq)


instance Default BuildConfig where
    def =
        BuildConfig
            { command = session.command
            , targets = session.targets
            , testTargets = session.testTargets
            , watchDirs = session.watchDirs
            }
      where
        session = def @Session


with
    :: ( Clock :> es
       , GhciSession :> es
       , Log :> es
       , Pub BuildProgress :> es
       , Reader ProjectRoot :> es
       )
    => BuildId
    -> BuildConfig
    -> (BuilderState -> NewLoadResult -> Eff (Builder : es) a)
    -> Eff es (Either SomeException a)
with buildId config action = do
    root <- ask
    startTime <- Clock.currentTime
    trySync $ GhciSession.withGhciWith Pub.publish config.command root \initialLoad controls -> do
        endTime <- Clock.currentTime
        let filteredMsgs = filterToWatchDirs root.getProjectRoot config.watchDirs initialLoad.diagnostics
        Log.info
            $ mconcat
                [ "GHCi started (session #"
                , show buildId.getBuildId
                , "): "
                , show (length filteredMsgs)
                , " diagnostics"
                ]
        let initialLoadResult = NewLoadResult {startTime, endTime, loadResult = initialLoad}
        let initialBuilderState =
                emptyBuilderState
                    { loadedModules = resolveKnownTargets Map.empty initialLoad
                    , knownTargets = KnownTargetNames (Set.fromList initialLoad.targetNames)
                    }
        reinterpretWith_
            (State.evalState initialBuilderState)
            (action initialBuilderState initialLoadResult)
            \case
                Consider fp event -> considerBuild fp event
                Build dispatchAction ->
                    buildSource (GhciSession.transformControls inject controls) dispatchAction


considerBuild
    :: (State BuilderState :> es)
    => FilePath
    -> FileEvent
    -> Eff es BuildConsideration
considerBuild fp event = do
    builderState <- get
    let known = Map.lookup (normalise fp) builderState.loadedModules
    case dispatch builderState.knownTargets known fp event of
        Nothing ->
            -- File not loaded in GHCi, so we skip building.
            pure SkipBuilding
        Just action -> do
            pure $ ShouldBuild action


buildSource
    :: (Clock :> es, State BuilderState :> es)
    => GhciSession.Controls (Eff es)
    -> DispatchAction
    -> Eff es (Either BuildFailure NewLoadResult)
buildSource controls action = do
    res <- trySync do
        startTime <- Clock.currentTime
        res <- runAction controls action
        endTime <- Clock.currentTime
        pure (startTime, endTime, res)

    case res of
        Left e -> do
            pure $ Left $ ReloadFailed e
        Right (startTime, endTime, loadResult) -> do
            modify \s ->
                s
                    { loadedModules = resolveKnownTargets s.loadedModules loadResult
                    , knownTargets = KnownTargetNames (Set.fromList loadResult.targetNames)
                    }
            pure $ Right $ NewLoadResult {startTime, endTime, loadResult}


compileBuildResults
    :: ProjectRoot
    -> WatchDirs
    -> NewLoadResult
    -> DiagnosticMap
    -> (DiagnosticMap, BuildResult)
compileBuildResults (ProjectRoot projectRoot) watchDirs newLoadResult diagnosticMap = (merged, buildResult)
  where
    NewLoadResult {startTime, endTime, loadResult} = newLoadResult
    merged = mergeDiagnostics diagnosticMap filteredResult
    filteredResult =
        loadResult
            { GhciSession.diagnostics =
                preserveFailureVisibility loadResult.diagnostics
                    $ filterToWatchDirs projectRoot watchDirs loadResult.diagnostics
            }
    buildResult =
        BuildResult
            { completedAt = endTime
            , duration = nominalDiffTime (diffUTCTime endTime startTime) :: Millisecond
            , moduleCount = loadResult.moduleCount
            , diagnostics = sortOn (\d -> (d.severity, d.file, d.line, d.col)) $ concat $ Map.elems merged
            }


runAction :: GhciSession.Controls (Eff es) -> DispatchAction -> Eff es LoadResult
runAction controls = \case
    Reload -> controls.reload
    Add fp -> controls.add fp
    Unadd mn -> controls.unadd mn


compileLoadResultsIntoBuildResults
    :: ( Reader ProjectRoot :> es
       , State BuilderState :> es
       )
    => BuildConfig
    -> NewLoadResult
    -> Eff es BuildResult
compileLoadResultsIntoBuildResults session newLoadResult = do
    ProjectRoot projectRoot <- ask
    let filteredResult =
            loadResult
                { GhciSession.diagnostics =
                    preserveFailureVisibility loadResult.diagnostics
                        $ filterToWatchDirs projectRoot watchDirs loadResult.diagnostics
                }

    newAccumulated <- State.state \s ->
        let merged = mergeDiagnostics s.diagnosticMap filteredResult
        in  (merged, s {diagnosticMap = merged})

    pure
        BuildResult
            { completedAt = endTime
            , duration = nominalDiffTime (diffUTCTime endTime startTime) :: Millisecond
            , moduleCount = loadResult.moduleCount
            , diagnostics = sortOn (\d -> (d.severity, d.file, d.line, d.col)) $ concat (Map.elems newAccumulated)
            }
  where
    BuildConfig {watchDirs} = session
    NewLoadResult {startTime, endTime, loadResult} = newLoadResult


--------------------------------------------------------------------------------
-- Supporting types
--------------------------------------------------------------------------------

-- | A pending phase transition. Carried by 'setNewPhase' into the 'BuildStore'.
data EnteringNewPhase = EnteringNewPhase BuildId BuildPhase
    deriving stock (Eq, Show)
