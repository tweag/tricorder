module Unit.Tricorder.Session.Helpers
    ( multiCabalFiles
    , singleCabalFile
    , multiPackageFs
    , preludeOnlyLibCabal
    , libWithPreludeCabal
    , libTestCabal
    , gpdFixture
    , cabalFixture
    , gpd
    )
where

import Distribution.PackageDescription (GenericPackageDescription)
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)

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
        . second
            ( fromMaybe (error "multiCabalFiles failed to parse")
                . parseGenericPackageDescriptionMaybe
            )
        <$> Map.toList multiPackageCabalFs


-- | An in-memory project root with a @cabal.project@ listing two packages,
-- each in its own subdirectory with a library and a test suite.
multiPackageFs :: Map FilePath ByteString
multiPackageFs =
    Map.fromList
        [ ("/cabal.project", "packages:\n  pkg-a\n  pkg-b\n\ntests: True\n")
        ]
        `Map.union` multiPackageCabalFs


multiPackageCabalFs :: Map FilePath ByteString
multiPackageCabalFs =
    Map.fromList
        [ ("/pkg-a/pkg-a.cabal", libTestCabal "pkg-a")
        , ("/pkg-b/pkg-b.cabal", libTestCabal "pkg-b")
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
singleCabalFile = [CabalFile "/myapp.cabal" gpdFixture]


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
