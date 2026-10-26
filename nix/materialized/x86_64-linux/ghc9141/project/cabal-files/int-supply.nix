{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  ({
    flags = {};
    package = {
      specVersion = "2.4";
      identifier = { name = "int-supply"; version = "1.0.0"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2023-2025 Mitchell Dalvi Rosen, Travis Staton";
      maintainer = "Mitchell Dalvi Rosen <mitchellwrosen@gmail.com>, Travis Staton <hello@travisstaton.com>";
      author = "Mitchell Dalvi Rosen, Travis Staton";
      homepage = "https://github.com/awkward-squad/int-supply";
      url = "";
      synopsis = "A simple, efficient supply of integers using atomic fetch-and-add.";
      description = "This package provides a simple, efficient supply of integers using atomic fetch-and-add.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/int-supply-1.0.0.tar.gz";
      sha256 = "ff5ec55f94d8f3477104fb0674e46cf8514b4b0565cb6ec57a84f84d1989fe40";
    });
  }) // {
    package-description-override = "cabal-version: 2.4\n\ncategory: Data\nauthor: Mitchell Dalvi Rosen, Travis Staton\nbug-reports: https://github.com/awkward-squad/int-supply/issues\nbuild-type: Simple\ncopyright: (c) 2023-2025 Mitchell Dalvi Rosen, Travis Staton\ndescription: This package provides a simple, efficient supply of integers using atomic fetch-and-add.\nhomepage: https://github.com/awkward-squad/int-supply\nlicense: BSD-3-Clause\nlicense-file: LICENSE\nmaintainer: Mitchell Dalvi Rosen <mitchellwrosen@gmail.com>, Travis Staton <hello@travisstaton.com>\nname: int-supply\nsynopsis: A simple, efficient supply of integers using atomic fetch-and-add.\ntested-with: GHC == 9.6.5, GHC == 9.8.2, GHC == 9.10.1\nversion: 1.0.0\nx-revision: 3\n\nextra-doc-files:\n  CHANGELOG.md\n  README.md\n\nsource-repository head\n  type: git\n  location: git://github.com/awkward-squad/int-supply.git\n\nlibrary\n  build-depends:\n    base ^>= 4.13\n      || ^>= 4.14\n      || ^>= 4.15\n      || ^>= 4.16\n      || ^>= 4.17\n      || ^>= 4.18\n      || ^>= 4.19\n      || ^>= 4.20\n      || ^>= 4.21\n      || ^>= 4.22\n  default-language: Haskell2010\n  exposed-modules: IntSupply\n  ghc-options:\n    -Weverything\n    -Wno-all-missed-specialisations\n    -Wno-implicit-prelude\n    -Wno-missing-import-lists\n    -Wno-missing-local-signatures\n    -Wno-monomorphism-restriction\n    -Wno-safe\n    -Wno-unsafe\n  if impl(ghc >= 8.10)\n    ghc-options:\n      -Wno-missing-safe-haskell-mode\n      -Wno-prepositive-qualified-module\n  if impl(ghc >= 9.2)\n    ghc-options:\n      -Wno-missing-kind-signatures\n  if impl(ghc >= 9.8)\n    ghc-options:\n      -Wno-missing-role-annotations\n  hs-source-dirs: src\n";
  }