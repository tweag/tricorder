module Tricorder.Watcher
    ( component
    , WatchedFile (..)
    , WatcherSession (..)
    , isCabalFile
    , makeWatches
    , markWatchedFiles
    ) where

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.FileWatcher
    ( FileEvent
    , FileWatcher
    , Watch
    , containing
    , dirExt
    , dirWhere
    , excluding
    , watchFilePathsDebounced
    )
import Atelier.Effects.Publishing.Pub (Pub)
import Atelier.Effects.Publishing.Sub (Sub)
import Effectful.Concurrent (Concurrent)
import Effectful.Reader.Static (Reader, ask)
import System.FilePath (takeExtension, takeFileName)
import Text.Regex.TDFA (ExecOption (..), blankCompOpt, blankExecOpt, match)
import Text.Regex.TDFA.TDFA (patternToRegex)

import Atelier.Effects.Publishing.Pub qualified as Pub
import Atelier.Effects.Publishing.Sub qualified as Sub

import Tricorder.BuildState
    ( CabalChangeDetected (..)
    , ChangeKind (..)
    , SourceChangeDetected (..)
    )
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.SessionStore (SessionStore, SessionStoreReloaded)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Pattern, Session (..), WatchDirs (..), WatchExclusionPatterns (..))

import Tricorder.Effects.BuildStore qualified as BuildStore
import Tricorder.Effects.SessionStore qualified as SessionStore


-- | Watcher component.
-- Watches source files and cabal-related files for changes, setting the dirty
-- flag in 'BuildStore'. 'GhciSession' polls this flag and triggers a rebuild
-- or session restart accordingly.
component
    :: ( BuildStore :> es
       , Chan :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce FilePath :> es
       , FileWatcher :> es
       , Pub CabalChangeDetected :> es
       , Pub SourceChangeDetected :> es
       , Pub WatchedFile :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , Sub SessionStoreReloaded :> es
       , Sub WatchedFile :> es
       )
    => Component es
component =
    defaultComponent
        { name = "Watcher"
        , triggers = pure [watchFiles]
        , listeners = pure [Sub.listen_ markWatchedFiles]
        }


markWatchedFiles
    :: ( BuildStore :> es
       , Pub CabalChangeDetected :> es
       , Pub SourceChangeDetected :> es
       )
    => WatchedFile -> Eff es ()
markWatchedFiles f = do
    BuildStore.markDirty change
    case change of
        CabalChange -> Pub.publish (CabalChangeDetected f.path f.event)
        SourceChange -> Pub.publish (SourceChangeDetected f.path f.event)
  where
    change = changeKindFor f.path


data WatchedFile = WatchedFile
    { path :: FilePath
    , event :: FileEvent
    }


data WatcherSession = WatcherSession
    { watchDirs :: WatchDirs
    , watchExclusionPatterns :: WatchExclusionPatterns
    }
    deriving stock (Eq)


withWatcherSession
    :: ( Chan :> es
       , Conc :> es
       , Concurrent :> es
       , SessionStore :> es
       , Sub SessionStoreReloaded :> es
       )
    => Session
    -> (SessionStore.Reloader es -> WatcherSession -> Eff es Void)
    -> Eff es Void
withWatcherSession =
    SessionStore.withSubSession $ \session ->
        WatcherSession
            { watchDirs = session.watchDirs
            , watchExclusionPatterns = session.watchExclusionPatterns
            }


watchFiles
    :: ( Chan :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce FilePath :> es
       , FileWatcher :> es
       , Pub WatchedFile :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , Sub SessionStoreReloaded :> es
       )
    => Eff es Void
watchFiles = do
    initialSession <- SessionStore.get
    withWatcherSession initialSession $ \_ session -> do
        projectRoot <- ask
        let watches = makeWatches projectRoot session
        watchFilePathsDebounced watches \filePath fileEvent -> Pub.publish (WatchedFile filePath fileEvent)


makeWatches :: ProjectRoot -> WatcherSession -> [Watch]
makeWatches projectRoot session =
    sourceWatches (coerce session.watchExclusionPatterns) (coerce session.watchDirs)
        <> cabalWatches projectRoot


sourceWatches :: [Pattern] -> [FilePath] -> [Watch]
sourceWatches exclusionPatterns =
    map \d ->
        dirExt d ".hs"
            `excluding` containing "dist-newstyle"
            `excluding` exclusionMatches exclusionPatterns


exclusionMatches :: [Pattern] -> FilePath -> Bool
exclusionMatches exclusionPatterns fp = any matchPattern exclusionPatterns
  where
    matchPattern p =
        match
            (patternToRegex p blankCompOpt blankExecOpt {captureGroups = False})
            fp


cabalWatches :: ProjectRoot -> [Watch]
cabalWatches (ProjectRoot projectRoot) =
    [dirWhere projectRoot isCabalFile `excluding` containing "dist-newstyle"]


isCabalFile :: FilePath -> Bool
isCabalFile f =
    takeExtension f == ".cabal"
        || takeFileName f `elem` ["cabal.project", "package.yaml"]


changeKindFor :: FilePath -> ChangeKind
changeKindFor path
    | isCabalFile path = CabalChange
    | otherwise = SourceChange
