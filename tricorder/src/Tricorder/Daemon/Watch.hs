module Tricorder.Daemon.Watch
    ( WatchedFile (..)
    , files
    , publishChange
    , specs
    , isCabalFile
    ) where

import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.FileWatcher
    ( FileEvent
    , FileWatcher
    , Watch
    , containing
    , dirExt
    , dirWhere
    , excluding
    )
import Atelier.Effects.Publishing.Pub (Pub)
import System.FilePath (takeExtension, takeFileName)
import Text.Regex.TDFA (ExecOption (..), blankCompOpt, blankExecOpt, match)
import Text.Regex.TDFA.TDFA (patternToRegex)

import Atelier.Effects.FileWatcher qualified as FileWatcher
import Atelier.Effects.Publishing.Pub qualified as Pub

import Tricorder.Build.Changes
    ( CabalChangeDetected (..)
    , ChangeKind (..)
    , SourceChangeDetected (..)
    )
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session
    ( Pattern
    , Session (..)
    , WatchDirs (..)
    , WatchExclusionPatterns (..)
    )


data WatchedFile = WatchedFile
    { path :: FilePath
    , event :: FileEvent
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


specs :: ProjectRoot -> WatchExclusionPatterns -> WatchDirs -> [Watch]
specs projectRoot watchExclusionPatterns watchDirs =
    sourceWatches (coerce watchExclusionPatterns) (coerce watchDirs)
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
