module Tricorder.Runtime.ProjectRoot
    ( ProjectRoot (..)
    , asReader
    )
where

import Atelier.Effects.FileSystem (FileSystem, getCurrentDirectory, listDirectory)
import Effectful.Reader.Static (Reader, runReader)
import System.FilePath (takeDirectory, takeExtension)


newtype ProjectRoot = ProjectRoot {getProjectRoot :: FilePath}


asReader
    :: (FileSystem :> es, HasCallStack)
    => Eff (Reader ProjectRoot : es) a -> Eff es a
asReader act = do
    cwd <- getCurrentDirectory
    projectRoot <- fromMaybe cwd <$> findProjectRoot cwd
    runReader (ProjectRoot projectRoot) act


findProjectRoot :: (FileSystem :> es) => FilePath -> Eff es (Maybe FilePath)
findProjectRoot dir = do
    files <- listDirectory dir
    let parent = takeDirectory dir
    if any isRootMarker files
        then pure (Just dir)
        else
            if parent == dir
                then pure Nothing
                else findProjectRoot parent


isRootMarker :: FilePath -> Bool
isRootMarker f =
    takeExtension f == ".cabal"
        || f `elem` ["cabal.project", "cabal.project.freeze", "cabal.project.local", "stack.yaml"]
