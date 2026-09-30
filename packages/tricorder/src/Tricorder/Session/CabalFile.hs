module Tricorder.Session.CabalFile
    ( CabalFile (..)
    , inputCabalFiles
    , discoverPackages
    , discoverCabalPackages
    , discoverStackPackages
    , readProjectFile
    )
where

import Atelier.Effects.Env (Env)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, listDirectory, readFileBs)
import Atelier.Effects.FileSystem.Glob (Glob, globDir1)
import Atelier.Effects.Input (Input, input, runInputEff)
import Atelier.Effects.Log (Log)
import Data.Traversable (for)
import Distribution.Fields (Field (..), FieldLine (..), Name (..), readFields)
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Distribution.Types.GenericPackageDescription (GenericPackageDescription)
import Effectful.Exception (catch, throwIO)
import Effectful.Reader.Static (Reader, ask)
import System.FilePath (normalise, takeExtension, (</>))
import System.FilePath.Glob (compile)
import System.IO.Error (userError)

import Atelier.Effects.Env qualified as Env
import Atelier.Effects.FileSystem qualified as FileSystem
import Atelier.Effects.Log qualified as Log
import Data.ByteString.Char8 qualified as BC
import Data.List qualified as List
import Data.Text qualified as T

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.StackProject (StackProject (..))


data CabalFile = CabalFile
    { projectFilePath :: FilePath
    , projectPackageDescription :: GenericPackageDescription
    }
    deriving stock (Show)


inputCabalFiles
    :: ( Env :> es
       , FileSystem :> es
       , Glob :> es
       , Input StackProject :> es
       , Log :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Input [CabalFile] : es) a -> Eff es a
inputCabalFiles = runInputEff $ Log.withNamespace "CabalFile" do
    packageRes <- discoverPackages
    case packageRes of
        Left err -> throwIO $ userError $ toString err
        Right projectFilePaths -> do
            (faileds, packageDescriptions) <-
                logFailure
                    $ partitionEithers <$> for projectFilePaths readProjectFile
            unless (null faileds) do
                Log.warn
                    $ "Failed to parse .cabal files for the following packages: "
                        <> T.intercalate ", " (toText <$> faileds)
            pure $ packageDescriptions
  where
    logFailure =
        ( `catch`
            \(e :: SomeException) -> do
                Log.err $ "Failed to read package descriptions"
                Log.err $ show e
                throwIO e
        )


readProjectFile
    :: (FileSystem :> es)
    => FilePath -> Eff es (Either FilePath CabalFile)
readProjectFile projectFilePath = do
    fileExists <- FileSystem.doesFileExist projectFilePath
    if fileExists
        then readFile projectFilePath
        else do
            dirExists <- FileSystem.doesDirectoryExist projectFilePath
            if dirExists
                then do
                    files <- FileSystem.listDirectory projectFilePath
                    let mCabalFile = find (".cabal" `List.isSuffixOf`) files
                    case mCabalFile of
                        Nothing -> pure $ Left projectFilePath
                        Just cabalFile -> readFile $ projectFilePath </> cabalFile
                else
                    pure $ Left projectFilePath
  where
    readFile path = do
        contents <- readFileBs path
        case parseGenericPackageDescriptionMaybe contents of
            Nothing -> pure $ Left path
            Just gpd -> pure $ Right $ CabalFile path gpd


discoverPackages
    :: ( Env :> es
       , FileSystem :> es
       , Glob :> es
       , Input StackProject :> es
       , Reader ProjectRoot :> es
       )
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
    :: (Input StackProject :> es, Reader ProjectRoot :> es)
    => Eff es (Either Text [FilePath])
discoverStackPackages = do
    ProjectRoot projectRoot <- ask
    project <- input
    pure $ Right $ normalise . (projectRoot </>) <$> project.packages


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
