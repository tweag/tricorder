module Tricorder.Daemon.Watch
    ( WatchedFile (..)
    , files
    , publishChange
    , specs
    , isCabalFile
    )
where

import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.FileWatcher (FileWatcher)
import Atelier.Effects.PubSub.Pub (Pub)
import System.FilePath (takeExtension, takeFileName)
import Text.Regex.TDFA (ExecOption (..), blankCompOpt, blankExecOpt, match)
import Text.Regex.TDFA.TDFA (patternToRegex)

import Atelier.Effects.FileWatcher qualified as FileWatcher
import Atelier.Effects.FileWatcher.Event qualified as FileWatcher (Event)
import Atelier.Effects.FileWatcher.Watch qualified as FileWatcher (Watch)
import Atelier.Effects.FileWatcher.Watch qualified as Watch
import Atelier.Effects.PubSub.Pub qualified as Pub

import Tricorder.Build.Changes
    ( CabalChangeDetected (..)
    , ChangeKind (..)
    , SourceChangeDetected (..)
    )
import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Session (Session (..))
import Tricorder.Session.WatchDirs (WatchDirs (..))
import Tricorder.Session.WatchExclusionPatterns (Pattern, WatchExclusionPatterns (..))


data WatchedFile = WatchedFile
    { path :: FilePath
    , event :: FileWatcher.Event
    }


files
    :: ( Debounce FilePath :> es
       , FileWatcher :> es
       , Pub WatchedFile :> es
       )
    => ProjectRoot -> Session -> Eff es Void
files projectRoot session =
    FileWatcher.watchFilePathsDebounced watches \filePath fileEvent ->
        Pub.publish $ WatchedFile filePath fileEvent
  where
    watches = specs projectRoot session.watchExclusionPatterns session.watchDirs


publishChange
    :: ( Pub CabalChangeDetected :> es
       , Pub SourceChangeDetected :> es
       )
    => WatchedFile -> Eff es ()
publishChange f =
    case changeKindFor f.path of
        CabalChange -> Pub.publish (CabalChangeDetected f.path f.event)
        SourceChange -> Pub.publish (SourceChangeDetected f.path f.event)


changeKindFor :: FilePath -> ChangeKind
changeKindFor path
    | isCabalFile path = CabalChange
    | otherwise = SourceChange


specs :: ProjectRoot -> WatchExclusionPatterns -> WatchDirs -> [FileWatcher.Watch]
specs projectRoot watchExclusionPatterns watchDirs =
    sourceWatches (coerce watchExclusionPatterns) (coerce watchDirs)
        <> cabalWatches projectRoot


sourceWatches :: [Pattern] -> [FilePath] -> [FileWatcher.Watch]
sourceWatches exclusionPatterns =
    map \d ->
        Watch.dirExt d ".hs"
            `Watch.excluding` Watch.containing "dist-newstyle"
            `Watch.excluding` exclusionMatches exclusionPatterns


exclusionMatches :: [Pattern] -> FilePath -> Bool
exclusionMatches exclusionPatterns fp = any matchPattern exclusionPatterns
  where
    matchPattern p =
        match
            (patternToRegex p blankCompOpt blankExecOpt {captureGroups = False})
            fp


cabalWatches :: ProjectRoot -> [FileWatcher.Watch]
cabalWatches (ProjectRoot projectRoot) =
    [ Watch.dirWhere projectRoot isCabalFile
        `Watch.excluding` Watch.containing "dist-newstyle"
    ]


isCabalFile :: FilePath -> Bool
isCabalFile f =
    takeExtension f == ".cabal"
        || takeFileName f `elem` ["cabal.project", "package.yaml"]
