module Tricorder.Runtime.ProjectRoot
    ( ProjectRoot (..)
    , asReader
    , findProjectRoot
    , findFileUpwards
    )
where

import Atelier.Effects.FileSystem (FileSystem, doesFileExist, getCurrentDirectory, listDirectory)
import Data.Aeson (ToJSON)
import Effectful.Reader.Static (Reader, runReader)
import System.FilePath (takeDirectory, takeExtension, (</>))


newtype ProjectRoot = ProjectRoot {getProjectRoot :: FilePath}
    deriving stock (Eq)
    deriving (ToJSON) via FilePath


asReader
    :: (FileSystem :> es, HasCallStack)
    => Eff (Reader ProjectRoot : es) a -> Eff es a
asReader act = do
    cwd <- getCurrentDirectory
    projectRoot <- fromMaybe cwd <$> findProjectRoot cwd
    runReader (ProjectRoot projectRoot) act


-- | Find the project root: the nearest directory, starting at the given one
-- and walking upwards, that contains a Stack or Cabal file.
--
-- This deliberately stops at a package directory even when it is part of a
-- larger multi-package project, so Tricorder can be used on one package at a
-- time. Use 'findFileUpwards' to locate project-level configuration such as
-- @stack.yaml@ or @cabal.project@ further up.
findProjectRoot :: (FileSystem :> es) => FilePath -> Eff es (Maybe FilePath)
findProjectRoot = findUpwards isRootMarker


-- | Find the nearest directory, starting at the given one and walking
-- upwards, that contains a file with the given name. This is how @stack@
-- looks for @stack.yaml@ and @cabal@ for @cabal.project@.
findFileUpwards :: (FileSystem :> es) => FilePath -> FilePath -> Eff es (Maybe FilePath)
findFileUpwards name dir = do
    found <- doesFileExist $ dir </> name
    let parent = takeDirectory dir
    if found
        then pure (Just dir)
        else
            if parent == dir
                then pure Nothing
                else findFileUpwards name parent


findUpwards :: (FileSystem :> es) => (FilePath -> Bool) -> FilePath -> Eff es (Maybe FilePath)
findUpwards isMarker dir = do
    files <- listDirectory dir
    let parent = takeDirectory dir
    if any isMarker files
        then pure (Just dir)
        else
            if parent == dir
                then pure Nothing
                else findUpwards isMarker parent


isRootMarker :: FilePath -> Bool
isRootMarker f =
    takeExtension f == ".cabal"
        || f `elem` ["cabal.project", "cabal.project.freeze", "cabal.project.local", "stack.yaml"]
