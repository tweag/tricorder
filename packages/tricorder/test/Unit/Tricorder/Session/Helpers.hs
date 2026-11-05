module Unit.Tricorder.Session.Helpers
    ( multiCabalFiles
    , singleCabalFile
    , multiPackageFs
    , multiPackageCabalFs
    , preludeOnlyLibCabal
    , libWithPreludeCabal
    , libTestCabal
    , gpdFixture
    , cabalFixture
    , gpd
    , withProjectFiles
    , withHome
    )
where

import Atelier.FileSystem.Path ((</>))
import Control.Exception (bracket)
import Distribution.PackageDescription (GenericPackageDescription)
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Effectful (IOE, runEff)
import Effectful.Exception (finally)
import Effectful.FileSystem (FileSystem, runFileSystem)
import System.Environment (lookupEnv, setEnv, unsetEnv)
import System.Posix.Temp (mkdtemp)

import Atelier.FileSystem.Directory qualified as Directory
import Atelier.FileSystem.File qualified as File
import Atelier.FileSystem.Path qualified as Path
import Data.Map.Strict qualified as Map
import Data.Text qualified as T

import Tricorder.Session.CabalFile (CabalFile (..))


gpd :: GenericPackageDescription
gpd =
    fromMaybe (error "cabalFixture failed to parse")
        $ parseGenericPackageDescriptionMaybe cabalFixture


multiCabalFiles :: [CabalFile]
multiCabalFiles =
    uncurry CabalFile
        . bimap
            (Path.absolute @"/" </>)
            ( fromMaybe (error "multiCabalFiles failed to parse")
                . parseGenericPackageDescriptionMaybe
            )
        <$> Map.toList multiPackageCabalFs


-- | An in-memory project root with a @cabal.project@ listing two packages,
-- each in its own subdirectory with a library and a test suite.
multiPackageFs :: Map Path.Relative ByteString
multiPackageFs =
    Map.fromList
        [ (Path.rel @"cabal.project", "packages:\n  pkg-a\n  pkg-b\n\ntests: True\n")
        ]
        `Map.union` multiPackageCabalFs


multiPackageCabalFs :: Map Path.Relative ByteString
multiPackageCabalFs =
    Map.fromList
        [ (Path.rel @"pkg-a/pkg-a.cabal", libTestCabal "pkg-a")
        , (Path.rel @"pkg-b/pkg-b.cabal", libTestCabal "pkg-b")
        ]


-- | A minimal cabal file for @name@ with a single library that exposes
-- @Prelude@ and nothing else. All auto-detected targets define a custom
-- Prelude, which triggers the 'loadSession' warning.
preludeOnlyLibCabal :: Text -> ByteString
preludeOnlyLibCabal name =
    encodeUtf8
        $ T.unlines
            [ "cabal-version: 2.0"
            , "name:          " <> name
            , "version:       0.1.0.0"
            , "build-type:    Simple"
            , ""
            , "library"
            , "  hs-source-dirs: src"
            , "  exposed-modules: Prelude"
            , "  build-depends: base"
            , "  default-language: Haskell2010"
            ]


-- | A minimal cabal file for @name@ with one library that exposes @Prelude@
-- and one executable. Used to verify that libraries defining a custom Prelude
-- are sorted last by 'resolveTargets'.
libWithPreludeCabal :: Text -> ByteString
libWithPreludeCabal name =
    encodeUtf8
        $ T.unlines
            [ "cabal-version: 2.0"
            , "name:          " <> name
            , "version:       0.1.0.0"
            , "build-type:    Simple"
            , ""
            , "library"
            , "  hs-source-dirs: src"
            , "  exposed-modules: Prelude"
            , "  build-depends: base"
            , "  default-language: Haskell2010"
            , ""
            , "executable " <> name <> "-exe"
            , "  main-is: Main.hs"
            , "  hs-source-dirs: app"
            , "  build-depends: base"
            , "  default-language: Haskell2010"
            ]


-- | A minimal cabal file for @name@ with one library and one test suite
-- (@<name>-test@).
libTestCabal :: Text -> ByteString
libTestCabal name =
    encodeUtf8
        $ T.unlines
            [ "cabal-version: 2.0"
            , "name:          " <> name
            , "version:       0.1.0.0"
            , "build-type:    Simple"
            , ""
            , "library"
            , "  hs-source-dirs: src"
            , "  build-depends: base"
            , "  default-language: Haskell2010"
            , ""
            , "test-suite " <> name <> "-test"
            , "  type: exitcode-stdio-1.0"
            , "  main-is: Test.hs"
            , "  hs-source-dirs: test"
            , "  build-depends: base"
            , "  default-language: Haskell2010"
            ]


singleCabalFile :: [CabalFile]
singleCabalFile = [CabalFile (Path.absolute @"/myapp.cabal") gpdFixture]


gpdFixture :: GenericPackageDescription
gpdFixture = fromMaybe (error "gpdFixture failed to parse") $ parseGenericPackageDescriptionMaybe cabalFixture


cabalFixture :: ByteString
cabalFixture =
    "cabal-version: 2.0\n\
    \name:          myapp\n\
    \version:       0.1.0.0\n\
    \build-type:    Simple\n\
    \\n\
    \library\n\
    \  hs-source-dirs: src\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \library myapp-utils\n\
    \  hs-source-dirs: utils\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \foreign-library myapp-flib\n\
    \  type: native-shared\n\
    \  hs-source-dirs: flib\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \executable myapp-exe\n\
    \  main-is: Main.hs\n\
    \  hs-source-dirs: app\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \test-suite myapp-test\n\
    \  type: exitcode-stdio-1.0\n\
    \  main-is: Test.hs\n\
    \  hs-source-dirs: test\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \benchmark myapp-bench\n\
    \  type: exitcode-stdio-1.0\n\
    \  main-is: Bench.hs\n\
    \  hs-source-dirs: bench\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n"


-- | Seed a fresh temporary directory with the given files (paths relative to
-- it, parent directories created as needed), run the action with that
-- directory as its project root, and delete the directory afterwards.
--
-- 'Effectful.FileSystem' only has a real-IO interpreter, so tests that need a
-- particular file layout have to materialise it on disk.
withProjectFiles
    :: Map Path.Relative ByteString
    -> (Path.Absolute -> Eff '[FileSystem, IOE] a)
    -> IO a
withProjectFiles files act =
    bracket (mkAbsolute <$> mkdtemp "/tmp/tricorder-test-") cleanup \root -> run do
        for_ (Map.toList files) \(rel, content) -> do
            let file = root </> rel
            Directory.createIfMissing True (Path.takeDirectory file)
            File.write file content
        act root
  where
    run = runEff . runFileSystem
    cleanup = run . Directory.removeRecursive
    mkAbsolute = either error id . Path.fromFilePath @Path.Absolute


-- | Run an action with @$HOME@ pointing at the given directory (and
-- @$XDG_CACHE_HOME@ unset, so XDG lookups fall back to @$HOME/.cache@),
-- restoring the previous values afterwards. These are process-global, so tests
-- using this must not run concurrently with each other (see
-- 'dependentTestGroup').
withHome :: (IOE :> es) => Path.Absolute -> Eff es a -> Eff es a
withHome home act = do
    oldHome <- liftIO $ lookupEnv "HOME"
    oldXdgCache <- liftIO $ lookupEnv "XDG_CACHE_HOME"
    liftIO $ setEnv "HOME" (Path.toFilePath home)
    liftIO $ unsetEnv "XDG_CACHE_HOME"
    act `finally` liftIO do
        restore "HOME" oldHome
        restore "XDG_CACHE_HOME" oldXdgCache
  where
    restore name = maybe (unsetEnv name) (setEnv name)
