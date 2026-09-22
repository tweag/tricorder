module Tricorder.Session.CabalFile
    ( CabalFile (..)
    , inputCabalFiles
    , discoverPackages
    , discoverCabalPackages
    , discoverStackPackages
    )
where

import Atelier.Effects.Env (Env)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, listDirectory, readFileBs)
import Atelier.Effects.FileSystem.Glob (Glob, globDir1)
import Atelier.Effects.Input (Input, runInputEff)
import Atelier.Effects.Log (Log)
import Data.Traversable (for)
import Distribution.Fields (Field (..), FieldLine (..), Name (..), readFields)
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Distribution.Types.GenericPackageDescription (GenericPackageDescription)
import Effectful.Exception (throwIO)
import Effectful.Reader.Static (Reader, ask)
import System.FilePath (normalise, takeExtension, (</>))
import System.FilePath.Glob (compile)
import System.IO.Error (userError)

import Atelier.Effects.Env qualified as Env
import Atelier.Effects.FileSystem qualified as FileSystem
import Atelier.Effects.Log qualified as Log
import Data.ByteString.Char8 qualified as BC
import Data.Text qualified as T

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.StackYaml (StackYaml)

import Tricorder.Session.StackYaml qualified as StackYaml


data CabalFile = CabalFile
    { projectFilePath :: FilePath
    , projectPackageDescription :: GenericPackageDescription
    }
    deriving stock (Show)


inputCabalFiles
    :: ( Env :> es
       , FileSystem :> es
       , Glob :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , StackYaml :> es
       )
    => Eff (Input [CabalFile] : es) a -> Eff es a
inputCabalFiles = runInputEff do
    packageRes <- discoverPackages
    case packageRes of
        Left err -> throwIO $ userError $ toString err
        Right projectFilePaths -> do
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


discoverPackages
    :: (Env :> es, FileSystem :> es, Glob :> es, Reader ProjectRoot :> es, StackYaml :> es)
    => Eff es (Either Text [FilePath])
discoverPackages = do
    ProjectRoot projectRoot <- ask
    hasStackYaml <- FileSystem.doesFileExist $ projectRoot </> "stack.yaml"
    if hasStackYaml
        then discoverStackPackages
        else discoverCabalPackages


-- | Discovers `.cabal` files in all locations and formats Cabal itself
-- supports.
discoverCabalPackages
    :: ( Env :> es
       , FileSystem :> es
       , Glob :> es
       , Reader ProjectRoot :> es
       )
    => Eff es (Either Text [FilePath])
discoverCabalPackages = do
    ProjectRoot projectRoot <- ask
    homeCabalFiles <- maybe [] (one . (</> ".cabal/config")) <$> Env.lookupEnv "HOME"
    let projectFilePaths = projectCabalFiles projectRoot <> homeCabalFiles
    projectFiles <- filterM doesFileExist projectFilePaths
    if null projectFiles
        then
            Right <$> cabalFilesIn projectRoot
        else do
            packages <- fmap (find (not . null))
                $ for projectFiles \projectFile -> do
                    contents <- readFileBs projectFile
                    concat
                        <$> traverse
                            (cabalFilesForEntry projectRoot)
                            (projectPackageEntries contents)
            case packages of
                Nothing -> Right <$> cabalFilesIn projectRoot
                Just pkgs -> pure $ Right pkgs
  where
    projectCabalFiles projectRoot =
        (projectRoot </>) <$> ["cabal.project.local", "cabal.project.freeze", "cabal.project"]

    cabalFilesForEntry projectRoot entry
        | hasWildcard entry = do
            matches <- globDir1 (compile entry) projectRoot
            concat <$> traverse resolveMatch matches
        | isCabalFile entry = pure [projectRoot </> entry]
        | otherwise = cabalFilesIn $ normalise $ projectRoot </> entry
      where
        resolveMatch path
            | isCabalFile path = pure [path]
            | otherwise = cabalFilesIn path


discoverStackPackages
    :: (Reader ProjectRoot :> es, StackYaml :> es)
    => Eff es (Either Text [FilePath])
discoverStackPackages = do
    ProjectRoot projectRoot <- ask
    mProject <- StackYaml.readProject
    case mProject of
        Left err -> pure $ Left $ "Failed to read project file: " <> err
        Right project -> pure $ Right $ normalise . (projectRoot </>) <$> project.packages


-- | List the @.cabal@ files directly inside a directory.
cabalFilesIn :: (FileSystem :> es) => FilePath -> Eff es [FilePath]
cabalFilesIn dir = do
    entries <- filter isCabalFile <$> listDirectory dir
    pure $ (dir </>) <$> entries


-- | Does a @packages:@ entry contain a glob wildcard?
hasWildcard :: FilePath -> Bool
hasWildcard = elem '*'


-- | Extract the directory/file entries from the @packages:@ field of a
-- @cabal.project@.
projectPackageEntries :: ByteString -> [FilePath]
projectPackageEntries contents =
    case readFields contents of
        Left _ -> []
        Right fields -> concatMap fromField fields
  where
    fromField = \case
        (Field (Name _ name) fieldLines)
            | name == "packages" -> concatMap fromLine fieldLines
            | otherwise -> []
        _ -> []
    fromLine (FieldLine _ bs) =
        fmap BC.unpack $ filter (not . BC.null) $ BC.words $ BC.map dropComma bs

    dropComma ',' = ' '
    dropComma c = c


isCabalFile :: FilePath -> Bool
isCabalFile = (== ".cabal") . takeExtension
