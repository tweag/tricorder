module Tricorder.Daemon.Hpack.Effect
    ( Hpack (..)
    , Result (..)
    , hpackIsInPath
    , hpack
    , run
    )
where

import Atelier.Effects.Process (Process, readProcess, runProcess, setWorkingDir, shell)
import Effectful (Effect)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.Exception (trySync)
import Effectful.TH (makeEffect)
import System.Exit (ExitCode (..))

import Data.ByteString.Char8 qualified as B8
import System.FilePath qualified as Path


data Hpack :: Effect where
    HpackIsInPath :: Hpack m Bool
    Hpack :: FilePath -> Hpack m (Either Text Result)


data Result
    = Generated
    | Unchanged
    | WasGeneratedWithNewerHpack
    | WasEditedManually
    | UnknownSuccess Text


makeEffect ''Hpack


run :: (Process :> es) => Eff (Hpack : es) a -> Eff es a
run = interpret_ \case
    HpackIsInPath -> do
        exitCode <- runProcess $ shell "command -v hpack"
        pure $ exitCode == ExitSuccess
    Hpack path -> do
        res <-
            trySync
                $ readProcess
                $ setWorkingDir (Path.takeDirectory path)
                $ shell "hpack"
        case res of
            Left ex -> pure $ Left $ show ex
            Right (exitCode, lstdout, lstderr) -> do
                let stdout = toStrict lstdout
                    stderr = toStrict lstderr
                    infoMsg =
                        if
                            | "generated" `B8.isInfixOf` stdout -> Generated
                            | "is up-to-date" `B8.isInfixOf` stdout -> Unchanged
                            | "generated with a newer version" `B8.isInfixOf` stdout -> WasGeneratedWithNewerHpack
                            | "was modified manually" `B8.isInfixOf` stdout -> WasEditedManually
                            | otherwise -> UnknownSuccess $ decodeUtf8 stdout
                if exitCode == ExitSuccess then
                    pure $ Right $ infoMsg
                else
                    pure $ Left $ decodeUtf8 stderr
