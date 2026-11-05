module Tricorder.Session.StackProject
    ( StackProject (..)
    , inputWithCache
    )
where

import Atelier.Effects.Input (Input)
import Atelier.FileSystem.Path ((</>))
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
import Effectful.FileSystem (FileSystem)
import Effectful.Reader.Static (Reader, ask)
import GHC.Generics (Generically (..))
import System.IO.Error (userError)

import Atelier.Effects.Input qualified as Input
import Atelier.FileSystem.File qualified as File
import Atelier.FileSystem.Path qualified as Path
import Data.Yaml qualified as Yaml

import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))


newtype StackProject = StackProject
    { packages :: [Path.Relative]
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
    flip Input.withEff act do
        ProjectRoot projectRoot <- ask
        let stackYamlPath = projectRoot </> Path.relative @"stack.yaml"
        exists <- File.exists stackYamlPath
        if not exists
            then throwIO $ userError "stack.yaml does not exist"
            else do
                newLastMod <- File.getModificationTime stackYamlPath
                oldLastMod <- atomically $ readTVar lastModified
                if oldLastMod /= newLastMod
                    then do
                        contents <- File.read stackYamlPath
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
