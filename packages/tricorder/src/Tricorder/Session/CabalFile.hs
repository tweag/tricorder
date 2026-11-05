module Tricorder.Session.CabalFile
    ( CabalFile (..)
    , inputCabalFiles
    , discoverPackages
    , discoverCabalPackages
    , discoverStackPackages
    , readProjectFile
    )
where

import Atelier.Effects.FileSystem.Glob (Glob, globDir1)
import Atelier.Effects.Input (Input)
import Atelier.Effects.Log (Log)
import Atelier.FileSystem.Path (Path, (</>))
import Data.Traversable (for)
import Distribution.Fields (Field (..), FieldLine (..), Name (..), readFields)
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Distribution.Types.GenericPackageDescription (GenericPackageDescription)
import Effectful.Exception (catch, throwIO)
import Effectful.FileSystem (FileSystem)
import Effectful.Reader.Static (Reader)
import System.FilePath.Glob (compile)
import System.IO.Error (userError)

import Atelier.Effects.Input qualified as Input
import Atelier.Effects.Log qualified as Log
import Atelier.FileSystem.Directory qualified as Directory
import Atelier.FileSystem.File qualified as File
import Atelier.FileSystem.Path qualified as Path
import Data.ByteString.Char8 qualified as BC
import Data.Text qualified as T
import Effectful.Reader.Static qualified as Reader

import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.StackProject (StackProject (..))


data CabalFile = CabalFile
    { projectFilePath :: Path.Absolute
    , projectPackageDescription :: GenericPackageDescription
    }
    deriving stock (Show)


inputCabalFiles
    :: ( FileSystem :> es
       , Glob :> es
       , Input StackProject :> es
       , Log :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Input [CabalFile] : es) a -> Eff es a
inputCabalFiles = Input.withEff $ Log.withNamespace "CabalFile" do
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
                        <> T.intercalate ", " (toText . Path.toFilePath <$> faileds)
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
    => Path.Absolute -> Eff es (Either Path.Absolute CabalFile)
readProjectFile projectFilePath = do
    fileExists <- File.exists projectFilePath
    if fileExists
        then readFile projectFilePath
        else do
            dirExists <- Directory.exists projectFilePath
            if dirExists
                then do
                    files <- Directory.list projectFilePath
                    let mCabalFile = find (Path.relative @".cabal" `Path.isSuffixOf`) files
                    case mCabalFile of
                        Nothing -> pure $ Left projectFilePath
                        Just cabalFile -> readFile $ projectFilePath </> cabalFile
                else
                    pure $ Left projectFilePath
  where
    readFile path = do
        contents <- File.read path
        case parseGenericPackageDescriptionMaybe contents of
            Nothing -> pure $ Left path
            Just gpd -> pure $ Right $ CabalFile path gpd


discoverPackages
    :: ( FileSystem :> es
       , Glob :> es
       , Input StackProject :> es
       , Reader ProjectRoot :> es
       )
    => Eff es (Either Text [Path.Absolute])
discoverPackages = do
    ProjectRoot projectRoot <- Reader.ask
    hasStackYaml <- File.exists $ projectRoot </> Path.relative @"stack.yaml"
    if hasStackYaml
        then discoverStackPackages
        else discoverCabalPackages


-- | Discovers @.cabal@ files in all locations and formats Cabal itself
-- supports.
discoverCabalPackages
    :: ( FileSystem :> es
       , Glob :> es
       , Reader ProjectRoot :> es
       )
    => Eff es (Either Text [Path.Absolute])
discoverCabalPackages = do
    ProjectRoot projectRoot <- Reader.ask
    homeCabalFiles <-
        Directory.getHome <&> \h ->
            (h </>)
                <$> [ Path.relative @".cabal/config"
                    , Path.relative @".config/cabal/config"
                    ]
    let projectFilePaths = projectCabalFiles projectRoot <> homeCabalFiles
    projectFiles <- filterM File.exists projectFilePaths
    if null projectFiles
        then
            Right <$> cabalFilesIn projectRoot
        else do
            packages <- fmap (find (not . null))
                $ for projectFiles \projectFile -> do
                    contents <- File.read projectFile
                    concat
                        <$> traverse
                            (cabalFilesForEntry projectRoot)
                            (projectPackageEntries contents)
            case packages of
                Nothing -> Right <$> cabalFilesIn projectRoot
                Just pkgs -> pure $ Right pkgs
  where
    projectCabalFiles projectRoot =
        (projectRoot </>)
            <$> [ Path.relative @"cabal.project.local"
                , Path.relative @"cabal.project.freeze"
                , Path.relative @"cabal.project"
                ]

    cabalFilesForEntry projectRoot (entry :: Path.Relative)
        | hasWildcard entry = do
            matches <- globDir1 (compile $ Path.toFilePath entry) projectRoot
            concat <$> traverse resolveMatch matches
        | isCabalFile entry = pure [projectRoot </> entry]
        | otherwise = cabalFilesIn $ Path.normalise $ projectRoot </> entry
      where
        resolveMatch path
            | isCabalFile path = pure [Path.normalise path]
            | otherwise = cabalFilesIn (Path.normalise path)


discoverStackPackages
    :: (Input StackProject :> es, Reader ProjectRoot :> es)
    => Eff es (Either Text [Path.Absolute])
discoverStackPackages = do
    ProjectRoot projectRoot <- Reader.ask
    project <- Input.input
    pure $ Right $ Path.normalise . (projectRoot </>) <$> project.packages


-- | List the @.cabal@ files directly inside a directory.
cabalFilesIn :: (FileSystem :> es) => Path.Absolute -> Eff es [Path.Absolute]
cabalFilesIn dir = do
    entries <- filter isCabalFile <$> Directory.list dir
    pure $ (dir </>) <$> entries


-- | Does a @packages:@ entry contain a glob wildcard?
hasWildcard :: (Path path) => path -> Bool
hasWildcard = elem '*' . Path.toFilePath


-- | Extract the directory/file entries from the @packages:@ field of a
-- @cabal.project@.
projectPackageEntries :: ByteString -> [Path.Relative]
projectPackageEntries contents =
    case readFields contents of
        Left _ -> []
        Right fields -> concatMap (mkPaths . fromField) fields
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
    mkPaths = mapMaybe $ rightToMaybe . Path.fromFilePath @Path.Relative


isCabalFile :: (Path path) => path -> Bool
isCabalFile = (== ".cabal") . Path.takeExtension
