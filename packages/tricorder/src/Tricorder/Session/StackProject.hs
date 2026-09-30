module Tricorder.Session.StackProject
    ( StackProject (..)
    , inputWithCache
    )
where

import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Input (Input, runInputEff)
import Data.Aeson (FromJSON, ToJSON)
import Data.Time (UTCTime)
import Data.Time.Clock.POSIX (posixSecondsToUTCTime)
import Effectful.Concurrent.MVar.Strict (Concurrent)
import Effectful.Concurrent.STM
    ( TVar
    , atomically
    , newTVarIO
    , readTVar
    , writeTVar
    )
import Effectful.Exception (throwIO)
import Effectful.Reader.Static (Reader, ask)
import GHC.Generics (Generically (..))
import System.FilePath ((</>))
import System.IO.Error (userError)

import Atelier.Effects.FileSystem qualified as FileSystem
import Data.Yaml qualified as Yaml

import Tricorder.Runtime (ProjectRoot (..))


newtype StackProject = StackProject
    { packages :: [FilePath]
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically StackProject


inputWithCache
    :: ( Concurrent :> es
       , FileSystem :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Input StackProject : es) a -> Eff es a
inputWithCache act = do
    cache :: TVar StackProject <- newTVarIO $ StackProject []
    lastModified :: TVar UTCTime <- newTVarIO $ posixSecondsToUTCTime 0
    flip runInputEff act do
        ProjectRoot projectRoot <- ask
        let stackYamlPath = projectRoot </> "stack.yaml"
        exists <- FileSystem.doesFileExist stackYamlPath
        if not exists
            then throwIO $ userError "stack.yaml does not exist"
            else do
                newLastMod <- FileSystem.getModificationTime stackYamlPath
                oldLastMod <- atomically $ readTVar lastModified
                if oldLastMod /= newLastMod
                    then do
                        contents <- FileSystem.readFileBs stackYamlPath
                        let result = Yaml.decodeEither' contents
                        case result of
                            Right x -> do
                                atomically do
                                    writeTVar cache x
                                    writeTVar lastModified newLastMod
                                pure x
                            Left err ->
                                throwIO $ userError $ "Could not parse stack.yaml: " <> show err
                    else
                        atomically $ readTVar cache
