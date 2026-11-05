module Tricorder.Runtime.ProjectRoot
    ( ProjectRoot (..)
    , asReader
    , findProjectRoot
    , findFileUpwards
    )
where

import Atelier.FileSystem.Path ((</>))
import Data.Aeson (ToJSON)
import Effectful.FileSystem (FileSystem)
import Effectful.Reader.Static (Reader, runReader)

import Atelier.FileSystem.Directory qualified as Directory
import Atelier.FileSystem.File qualified as File
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


-- | Find the project root: the nearest directory, starting at the given one
-- and walking upwards, that contains a Stack or Cabal file.
--
-- This deliberately stops at a package directory even when it is part of a
-- larger multi-package project, so Tricorder can be used on one package at a
-- time. Use 'findFileUpwards' to locate project-level configuration such as
-- @stack.yaml@ or @cabal.project@ further up.
findProjectRoot :: (FileSystem :> es) => Path.Absolute -> Eff es (Maybe Path.Absolute)
findProjectRoot dir = do
    files <- Directory.list dir
    if
        | any isRootMarker files -> pure $ Just dir
        | parent == dir -> pure Nothing
        | otherwise -> findProjectRoot parent
  where
    parent = Path.takeDirectory dir


-- | Find the nearest directory, starting at the given one and walking
-- upwards, that contains a file with the given name. This is how @stack@
-- looks for @stack.yaml@ and @cabal@ for @cabal.project@.
findFileUpwards
    :: (FileSystem :> es) => Path.Relative -> Path.Absolute -> Eff es (Maybe Path.Absolute)
findFileUpwards name dir = do
    found <- File.exists $ dir </> name
    if
        | found -> pure $ Just dir
        | parent == dir -> pure Nothing
        | otherwise -> findFileUpwards name parent
  where
    parent = Path.takeDirectory dir


isRootMarker :: Path.Relative -> Bool
isRootMarker f =
    Path.takeExtension f == ".cabal"
        || Path.toFilePath f
            `elem` [ "cabal.project"
                   , "cabal.project.freeze"
                   , "cabal.project.local"
                   , "stack.yaml"
                   ]
