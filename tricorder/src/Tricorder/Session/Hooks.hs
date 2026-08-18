module Tricorder.Session.Hooks
    ( Hooks (..)
    , Hook (..)
    , runHook
    )
where

import Atelier.Effects.Process (Process)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import Effectful.Exception (trySync)
import Effectful.Reader.Static (Reader)

import Atelier.Effects.Process qualified as Process
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime (ProjectRoot (..))


data Hooks = Hooks
    { start :: Maybe Hook
    , reload :: Maybe Hook
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake Hooks


instance Default Hooks where
    def =
        Hooks
            { start = def
            , reload = def
            }


data Hook = Hook
    { before :: Maybe Text
    , after :: Maybe Text
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake Hook


instance Default Hook where
    def =
        Hook
            { before = Nothing
            , after = Nothing
            }


runHook :: (Process :> es, Reader ProjectRoot :> es) => Text -> Eff es ()
runHook hook = do
    ProjectRoot root <- Reader.ask
    void
        $ trySync
        $ Process.runProcess
        $ Process.setWorkingDir root
        $ Process.shell
        $ toString hook
