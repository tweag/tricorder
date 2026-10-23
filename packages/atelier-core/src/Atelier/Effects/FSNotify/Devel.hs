{-# OPTIONS_GHC -Wno-redundant-constraints #-}

module Atelier.Effects.FSNotify.Devel
    ( treeExtAny
    , treeExtExists
    , module System.FSNotify.Devel
    )
where

import Effectful (Limit (..), Persistence (..))
import Effectful.Dispatch.Static (concUnliftIO, unsafeEff)
import System.FSNotify (StopListening, WatchManager)
import System.FSNotify.Devel hiding (treeExtAny, treeExtExists)

import System.FSNotify.Devel qualified as FSNotify.Devel

import Atelier.Effects.FSNotify (FSNotify)


treeExtAny
    :: (FSNotify :> es)
    => WatchManager -> FilePath -> Text -> (FilePath -> Eff es ()) -> Eff es StopListening
treeExtAny manager path extension action = unsafeEff \env ->
    concUnliftIO env Persistent Unlimited \unlift ->
        FSNotify.Devel.treeExtAny manager path extension (\fp -> unlift $ action fp)


treeExtExists
    :: (FSNotify :> es)
    => WatchManager -> FilePath -> Text -> (FilePath -> Eff es ()) -> Eff es StopListening
treeExtExists manager path extension action = unsafeEff \env ->
    concUnliftIO env Persistent Unlimited \unlift ->
        FSNotify.Devel.treeExtExists manager path extension (\fp -> unlift $ action fp)
