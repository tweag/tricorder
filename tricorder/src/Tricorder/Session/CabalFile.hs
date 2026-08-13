module Tricorder.Session.CabalFile
    ( CabalFile (..)
    , inputCabalFiles
    , discoverCabalFiles
    ) where

import Atelier.Effects.Env (Env)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, listDirectory, readFileBs)
import Atelier.Effects.Input (Input, runInputEff)
import Atelier.Effects.Log (Log)
import Data.Traversable (for)
import Distribution.Fields (Field (..), FieldLine (..), Name (..), readFields)
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Distribution.Types.GenericPackageDescription (GenericPackageDescription)
import Effectful.Reader.Static (Reader, ask)
import System.FilePath (normalise, takeExtension, (</>))

import Atelier.Effects.Env qualified as Env
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
    :: ( Env :> es
       , FileSystem :> es
       , Log :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Input [CabalFile] : es) a -> Eff es a
inputCabalFiles = runInputEff do
    projectFilePaths <- discoverCabalFiles
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


-- | Lists all `.cabal` files for packages listed in the project root's
-- `cabal.project` (or `cabal.project.local`) file. If no `cabal.project` file
-- is found, looks for a `.cabal` file in the project root, and uses that
-- instead.
discoverCabalFiles
    :: ( Env :> es
       , FileSystem :> es
       , Reader ProjectRoot :> es
       )
    => Eff es [FilePath]
discoverCabalFiles = do
    ProjectRoot projectRoot <- ask
    homeCabalFiles <- maybe [] (one . (</> ".cabal/config")) <$> Env.lookupEnv "HOME"
    let projectFilePaths = projectCabalFiles projectRoot <> homeCabalFiles
    projectFiles <- filterM doesFileExist projectFilePaths
    case nonEmpty projectFiles of
        Nothing ->
            cabalFilesIn projectRoot
        Just neProjectFiles -> do
            packages <- fmap (find (not . null))
                $ for (toList neProjectFiles) \projectFile -> do
                    contents <- readFileBs projectFile
                    concat
                        <$> traverse
                            (cabalFilesForEntry projectRoot)
                            (projectPackageEntries contents)
            case packages of
                Nothing -> cabalFilesIn projectRoot
                Just pkgs -> pure pkgs
  where
    projectCabalFiles projectRoot =
        (projectRoot </>) <$> ["cabal.project.local", "cabal.project.freeze", "cabal.project"]

    -- A @packages:@ entry is either a direct path to a @.cabal@ file or a
    -- directory to search for one.
    cabalFilesForEntry projectRoot entry
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
