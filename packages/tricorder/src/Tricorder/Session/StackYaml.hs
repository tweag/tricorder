module Tricorder.Session.StackYaml
    ( StackYaml
    , readProject
    , StackProject (..)
    , runWithCache
    , runConst
    )
where

import Atelier.Effects.FileSystem (FileSystem)
import Data.Aeson (FromJSON, ToJSON)
import Data.Time (UTCTime)
import Effectful (Effect)
import Effectful.Concurrent.MVar.Strict (Concurrent)
import Effectful.Concurrent.STM (TMVar, atomically, newEmptyTMVarIO, readTMVar, writeTMVar)
import Effectful.Dispatch.Dynamic (interpretWith_, interpret_)
import Effectful.Reader.Static (Reader, ask)
import Effectful.TH (makeEffect)
import GHC.Generics (Generically (..))
import System.FilePath ((</>))

import Atelier.Effects.FileSystem qualified as FileSystem
import Data.Yaml qualified as Yaml

import Tricorder.Runtime (ProjectRoot (..))


data StackYaml :: Effect where
    ReadProject :: StackYaml m (Either Text StackProject)


newtype StackProject = StackProject
    { packages :: [FilePath]
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically StackProject


makeEffect ''StackYaml


runWithCache
    :: ( Concurrent :> es
       , FileSystem :> es
       , Reader ProjectRoot :> es
       )
    => Eff (StackYaml : es) a -> Eff es a
runWithCache act = do
    cache :: TMVar StackProject <- newEmptyTMVarIO
    lastModified :: TMVar UTCTime <- newEmptyTMVarIO
    interpretWith_ act \case
        ReadProject -> do
            ProjectRoot projectRoot <- ask
            let stackYamlPath = projectRoot </> "stack.yaml"
            exists <- FileSystem.doesFileExist stackYamlPath
            if not exists
                then pure $ Left "stack.yaml does not exist"
                else do
                    newLastMod <- FileSystem.getModificationTime stackYamlPath
                    oldLastMod <- atomically $ readTMVar lastModified
                    if oldLastMod /= newLastMod
                        then do
                            contents <- FileSystem.readFileBs stackYamlPath
                            let result = Yaml.decodeEither' contents
                            case result of
                                Right x -> do
                                    atomically do
                                        writeTMVar cache x
                                        writeTMVar lastModified newLastMod
                                    pure $ Right x
                                Left err ->
                                    pure $ Left $ "Could not parse stack.yaml: " <> show err
                        else
                            atomically $ Right <$> readTMVar cache


-- | Interpret 'StackYaml' with a fixed result, for tests.
runConst :: Either Text StackProject -> Eff (StackYaml : es) a -> Eff es a
runConst result = interpret_ \case
    ReadProject -> pure result
