module Tricorder.Session.Hook
    ( Hook (..)
    , run
    )
where

import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process)
import Data.Aeson (FromJSON, ToJSON)
import Effectful.Exception (trySync)
import Effectful.Reader.Static (Reader)
import System.Exit (ExitCode (..))

import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Process qualified as Process
import Data.Text qualified as T
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))


newtype Hook = Hook {getHook :: Text}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Text


run :: (Log :> es, Process :> es, Reader ProjectRoot :> es) => Hook -> Eff es ()
run (Hook hook) = do
    ProjectRoot root <- Reader.ask
    res <-
        trySync
            $ Process.readProcess
            $ Process.setWorkingDir root
            $ Process.shell
            $ toString hook
    case res of
        Left err ->
            Log.warn $ "Hook failed to run: " <> toText (displayException err)
        Right (ExitFailure code, stdout, stderr) -> do
            let
                displayError kind e =
                    mconcat
                        [ "Unable to decode "
                        , kind
                        , ": "
                        , toText (displayException e)
                        ]
                decode kind =
                    either (displayError kind) (("Hook " <> kind <> " output: ") <>)
                        . decodeUtf8Strict
                        . toStrict
            Log.warn
                $ T.intercalate
                    "\n"
                    [ "Hook exited with a non-zero exit code: " <> show code
                    , "Hook output emitted as DEBUG logs."
                    ]
            Log.debug
                $ T.intercalate
                    "\n"
                    [ decode "stdout" stdout
                    , decode "stderr" stderr
                    ]
        Right (ExitSuccess, _, _) ->
            pure ()
