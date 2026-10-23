{-# OPTIONS_GHC -Wno-redundant-constraints #-}

module Atelier.Effects.FSNotify
    ( FSNotify
    , withManager
    , startManager
    , stopManager
    , withManagerConf
    , startManagerConf
    , watchDir
    , watchDirChan
    , watchTree
    , watchTreeChan
    , module System.FSNotify
    , run
    )
where

import Effectful (Dispatch (..), DispatchOf, Effect, IOE, Limit (..), Persistence (..))
import Effectful.Dispatch.Static
    ( SideEffects (..)
    , StaticRep
    , concUnliftIO
    , evalStaticRep
    , unsafeEff
    , unsafeEff_
    )
import System.FSNotify hiding
    ( Action
    , startManager
    , startManagerConf
    , stopManager
    , watchDir
    , watchDirChan
    , watchTree
    , watchTreeChan
    , withManager
    , withManagerConf
    )

import System.FSNotify qualified as FSNotify


data FSNotify :: Effect


type instance DispatchOf FSNotify = Static 'WithSideEffects


data instance StaticRep FSNotify = FSNotify


type Action es = Event -> Eff es ()


withManager :: (FSNotify :> es) => (WatchManager -> Eff es a) -> Eff es a
withManager act =
    unsafeEff \env ->
        concUnliftIO env Persistent Unlimited \unlift ->
            FSNotify.withManager (unlift . act)


startManager :: (FSNotify :> es) => Eff es WatchManager
startManager = unsafeEff_ $ FSNotify.startManager


stopManager :: (FSNotify :> es) => WatchManager -> Eff es ()
stopManager = unsafeEff_ . FSNotify.stopManager


withManagerConf :: (FSNotify :> es) => WatchConfig -> (WatchManager -> Eff es a) -> Eff es a
withManagerConf conf act =
    unsafeEff \env ->
        concUnliftIO env Persistent Unlimited \unlift ->
            FSNotify.withManagerConf conf (unlift . act)


startManagerConf :: (FSNotify :> es) => WatchConfig -> Eff es WatchManager
startManagerConf = unsafeEff_ . FSNotify.startManagerConf


watchDir
    :: (FSNotify :> es) => WatchManager -> FilePath -> ActionPredicate -> Action es -> Eff es StopListening
watchDir watchManager filePath actionPredicate action =
    unsafeEff \env ->
        concUnliftIO env Persistent Unlimited \unlift ->
            FSNotify.watchDir watchManager filePath actionPredicate (unlift . action)


watchDirChan
    :: (FSNotify :> es)
    => WatchManager -> FilePath -> ActionPredicate -> EventChannel -> Eff es StopListening
watchDirChan watchManager filePath actionPredicate eventChannel =
    unsafeEff_ $ FSNotify.watchDirChan watchManager filePath actionPredicate eventChannel


watchTree
    :: (FSNotify :> es) => WatchManager -> FilePath -> ActionPredicate -> Action es -> Eff es StopListening
watchTree watchManager filePath actionPredicate action =
    unsafeEff \env ->
        concUnliftIO env Persistent Unlimited \unlift ->
            FSNotify.watchTree watchManager filePath actionPredicate (unlift . action)


watchTreeChan
    :: (FSNotify :> es)
    => WatchManager -> FilePath -> ActionPredicate -> EventChannel -> Eff es StopListening
watchTreeChan watchManager filePath actionPredicate eventChannel =
    unsafeEff_ $ FSNotify.watchTreeChan watchManager filePath actionPredicate eventChannel


run :: (IOE :> es) => Eff (FSNotify : es) a -> Eff es a
run = evalStaticRep FSNotify
