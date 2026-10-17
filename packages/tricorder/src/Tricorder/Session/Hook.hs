module Tricorder.Session.Hook
    ( Hook (..)
    , run
    )
where

import Atelier.Effects.Process (Process)
import Data.Aeson (FromJSON, ToJSON)
import Effectful.Exception (trySync)
import Effectful.Reader.Static (Reader)

import Atelier.Effects.Process qualified as Process
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime (ProjectRoot (..))


newtype Hook = Hook {getHook :: Text}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Text


run :: (Process :> es, Reader ProjectRoot :> es) => Hook -> Eff es ()
run (Hook hook) = do
    ProjectRoot root <- Reader.ask
    void
        $ trySync
        $ Process.runProcess
        $ Process.setWorkingDir root
        $ Process.shell
        $ toString hook
