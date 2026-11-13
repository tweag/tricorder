module Tricorder.Daemon.HookDispatch (main) where

import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process)
import Atelier.Effects.PubSub.Sub (Sub)
import Effectful.Reader.Static (Reader)

import Atelier.Effects.FileWatcher.Event qualified as FileWatcher
import Atelier.Effects.FileWatcher.Event qualified as FileWatcher.Event
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.PubSub.Sub qualified as Sub
import Atelier.FileSystem.Path qualified as Path

import Tricorder.Daemon.Watch (WatchedFile (..))
import Tricorder.Runtime.ProjectRoot (ProjectRoot)
import Tricorder.Session (Session (..))
import Tricorder.Session.HaskellHooks (HaskellHooks (..))
import Tricorder.Session.Hooks (Hooks (..))

import Tricorder.Session.Hook qualified as Hook


main
    :: ( Log :> es
       , Process :> es
       , Reader ProjectRoot :> es
       , Sub WatchedFile :> es
       )
    => Session -> Eff es Void
main session =
    Sub.listen_ \case
        (WatchedFile path event)
            | Path.takeExtension path == ".hs"
            , Just hooks <- session.hooks.haskell ->
                runHsHook hooks event
            | otherwise -> pure ()


runHsHook
    :: (Log :> es, Process :> es, Reader ProjectRoot :> es)
    => HaskellHooks -> FileWatcher.Event -> Eff es ()
runHsHook hooks = \case
    FileWatcher.Event.Added -> whenJust hooks.fileAdded \hook -> do
        Hook.run hook
        Log.debug "Haskell file added hook ran"
    FileWatcher.Event.Modified -> whenJust hooks.fileModified \hook -> do
        Hook.run hook
        Log.debug "Haskell file modified hook ran"
    FileWatcher.Event.Removed -> whenJust hooks.fileRemoved \hook -> do
        Hook.run hook
        Log.debug "Haskell file removed hook ran"
