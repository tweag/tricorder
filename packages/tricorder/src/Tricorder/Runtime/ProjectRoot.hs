module Tricorder.Runtime.ProjectRoot
    ( ProjectRoot (..)
    , asReader
    )
where

import Data.Aeson (ToJSON)
import Effectful.FileSystem (FileSystem)
import Effectful.Reader.Static (Reader, runReader)

import Atelier.FileSystem.Directory qualified as Directory
import Atelier.FileSystem.Path qualified as Path


newtype ProjectRoot = ProjectRoot {getProjectRoot :: Path.Absolute}
    deriving stock (Eq)
    deriving (ToJSON) via Path.Absolute


asReader
    :: (FileSystem :> es, HasCallStack)
    => Eff (Reader ProjectRoot : es) a -> Eff es a
asReader act = do
    cwd <- Directory.getCurrent
    projectRoot <- fromMaybe cwd <$> findProjectRoot cwd
    runReader (ProjectRoot projectRoot) act


findProjectRoot :: (FileSystem :> es) => Path.Absolute -> Eff es (Maybe Path.Absolute)
findProjectRoot dir = do
    files <- Directory.list dir
    let parent = Path.takeDirectory dir
    if any isRootMarker files
        then pure (Just dir)
        else
            if parent == dir
                then pure Nothing
                else findProjectRoot parent


isRootMarker :: Path.Relative -> Bool
isRootMarker f =
    Path.takeExtension f == ".cabal"
        || Path.toFilePath f
            `elem` ["cabal.project", "cabal.project.freeze", "cabal.project.local", "stack.yaml"]
