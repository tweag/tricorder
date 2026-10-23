module Tricorder.Daemon.HookDispatch (main) where

import Atelier.Effects.Process (Process)
import Atelier.Effects.PubSub.Sub (Sub)
import Effectful.Reader.Static (Reader)

import Atelier.Effects.FileWatcher.Event qualified as FileWatcher
import Atelier.Effects.FileWatcher.Event qualified as FileWatcher.Event
import Atelier.Effects.PubSub.Sub qualified as Sub
import System.FilePath qualified as Path

import Tricorder.Daemon.Watch (WatchedFile (..))
import Tricorder.Runtime (ProjectRoot)
import Tricorder.Session (Session (..))
import Tricorder.Session.HaskellHooks (HaskellHooks (..))
import Tricorder.Session.Hooks (Hooks (..))

import Tricorder.Session.Hook qualified as Hook


main :: (Process :> es, Reader ProjectRoot :> es, Sub WatchedFile :> es) => Session -> Eff es Void
main session =
    Sub.listen_ \case
        (WatchedFile path event)
            | Path.takeExtension path == "hs"
            , Just hooks <- session.hooks.haskell ->
                runHsHook hooks event
            | otherwise -> pure ()


runHsHook
    :: (Process :> es, Reader ProjectRoot :> es) => HaskellHooks -> FileWatcher.Event -> Eff es ()
runHsHook hooks = \case
    FileWatcher.Event.Added -> whenJust hooks.fileAdded Hook.run
    FileWatcher.Event.Modified -> whenJust hooks.fileModified Hook.run
    FileWatcher.Event.Removed -> whenJust hooks.fileRemoved Hook.run
