module Tricorder.Session.CabalFile
    ( CabalFile (..)
    , inputCabalFiles
    , discoverCabalFiles
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
import Effectful.Reader.Static (Reader, ask)
import System.FilePath (normalise, takeExtension, (</>))
import System.FilePath.Glob (compile)

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
       , Glob :> es
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


-- | Discovers `.cabal` files in all locations and formats Cabal itself
-- supports.
discoverCabalFiles
    :: ( Env :> es
       , FileSystem :> es
       , Glob :> es
       , Reader ProjectRoot :> es
       )
    => Eff es [FilePath]
discoverCabalFiles = do
    ProjectRoot projectRoot <- ask
    homeCabalFiles <- maybe [] (one . (</> ".cabal/config")) <$> Env.lookupEnv "HOME"
    let projectFilePaths = projectCabalFiles projectRoot <> homeCabalFiles
    projectFiles <- filterM doesFileExist projectFilePaths
    if null projectFiles
        then
            cabalFilesIn projectRoot
        else do
            packages <- fmap (find (not . null))
                $ for projectFiles \projectFile -> do
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
