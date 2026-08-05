module Tricorder.Session.CabalFile
    ( CabalFile (..)
    , inputCabalFiles
    , discoverCabalFiles
    ) where

import Atelier.Effects.FileSystem (FileSystem, doesFileExist, listDirectory, readFileBs)
import Atelier.Effects.Input (Input, runInputEff)
import Atelier.Effects.Log (Log)
import Data.Traversable (for)
import Distribution.Fields (Field (..), FieldLine (..), Name (..), readFields)
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Distribution.Types.GenericPackageDescription (GenericPackageDescription)
import Effectful.Reader.Static (Reader, ask)
import System.FilePath (normalise, takeExtension, (</>))

import Atelier.Effects.Log qualified as Log
import Data.ByteString.Char8 qualified as BC
import Data.Text qualified as T

import Tricorder.Runtime (ProjectRoot (..))


data CabalFile = CabalFile
    { projectFilePath :: FilePath
    , projectPackageDescription :: GenericPackageDescription
    }
    deriving stock (Show)


inputCabalFiles
    :: ( FileSystem :> es
       , Log :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Input [CabalFile] : es) a -> Eff es a
inputCabalFiles = runInputEff do
    projectRoot <- ask
    projectFilePaths <- discoverCabalFiles projectRoot
    (faileds, packageDescriptions) <-
        partitionEithers <$> for projectFilePaths \p -> do
            contents <- readFileBs p
            case parseGenericPackageDescriptionMaybe contents of
                Nothing -> pure $ Left p
                Just gpd -> pure $ Right $ CabalFile p gpd
    unless (null faileds) do
        Log.warn
            $ "Failed to parse .cabal files for the following packages: "
                <> T.intercalate ", " (toText <$> faileds)
    pure $ packageDescriptions


-- | Locate every package's @.cabal@ file, logging what drove the result. In a
-- multi-package project the packages live in subdirectories listed under
-- @packages:@ in @cabal.project@; in a single-package project the @.cabal@
-- file(s) sit in the root. Called once per session load; the result is shared
-- by target and watch-dir resolution.
discoverCabalFiles :: (FileSystem :> es, Log :> es) => ProjectRoot -> Eff es [FilePath]
discoverCabalFiles (ProjectRoot projectRoot) = do
    hasProject <- doesFileExist projectFile
    cabalFiles <-
        if hasProject then do
            contents <- readFileBs projectFile
            concat <$> traverse cabalFilesForEntry (projectPackageEntries contents)
        else
            cabalFilesIn projectRoot
    let listed
            | null cabalFiles = "none"
            | otherwise = T.intercalate ", " (map toText cabalFiles)
    if hasProject then
        Log.debug
            $ "Found cabal.project; discovered "
                <> show (length cabalFiles)
                <> " package cabal file(s): "
                <> listed
    else
        Log.debug $ "No cabal.project; using cabal file(s) in project root: " <> listed
    pure cabalFiles
  where
    projectFile = projectRoot </> "cabal.project"

    -- A @packages:@ entry is either a direct path to a @.cabal@ file or a
    -- directory to search for one.
    cabalFilesForEntry entry
        | takeExtension entry == ".cabal" = pure [projectRoot </> entry]
        | otherwise = cabalFilesIn (normalise (projectRoot </> entry))


-- | List the @.cabal@ files directly inside a directory.
cabalFilesIn :: (FileSystem :> es) => FilePath -> Eff es [FilePath]
cabalFilesIn dir = do
    entries <- filter (\f -> takeExtension f == ".cabal") <$> listDirectory dir
    pure $ map (dir </>) entries


-- | Extract the directory/file entries from the @packages:@ field of a
-- @cabal.project@. Glob entries (containing @*@) are not expanded and are
-- skipped.
projectPackageEntries :: ByteString -> [FilePath]
projectPackageEntries contents =
    case readFields contents of
        Left _ -> []
        Right fields -> filter (notElem '*') $ concatMap fromField fields
  where
    fromField (Field (Name _ name) fieldLines)
        | name == "packages" = concatMap fromLine fieldLines
    fromField _ = []
    fromLine (FieldLine _ bs) = map BC.unpack (BC.words bs)
