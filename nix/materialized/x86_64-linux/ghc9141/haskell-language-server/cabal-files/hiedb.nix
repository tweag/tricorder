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
      identifier = { name = "hiedb"; version = "0.8.0.0"; };
      license = "BSD-3-Clause";
      copyright = "Zubin Duggal";
      maintainer = "zubin.duggal@gmail.com";
      author = "Zubin Duggal";
      homepage = "";
      url = "";
      synopsis = "Generates a references DB from .hie files";
      description = "Tool and library to index and query a collection of `.hie` files";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."sqlite-simple" or (errorHandler.buildDepError "sqlite-simple"))
          (hsPkgs."hie-compat" or (errorHandler.buildDepError "hie-compat"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."algebraic-graphs" or (errorHandler.buildDepError "algebraic-graphs"))
          (hsPkgs."lucid" or (errorHandler.buildDepError "lucid"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
          (hsPkgs."terminal-size" or (errorHandler.buildDepError "terminal-size"))
        ];
        buildable = true;
      };
      exes = {
        "hiedb" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hiedb" or (errorHandler.buildDepError "hiedb"))
            (hsPkgs."ghc-paths" or (errorHandler.buildDepError "ghc-paths"))
          ];
          buildable = true;
        };
      };
      tests = {
        "hiedb-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc-paths" or (errorHandler.buildDepError "ghc-paths"))
            (hsPkgs."hiedb" or (errorHandler.buildDepError "hiedb"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."algebraic-graphs" or (errorHandler.buildDepError "algebraic-graphs"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hiedb.components.exes.hiedb or (pkgs.pkgsBuildBuild.hiedb or (errorHandler.buildToolDepError "hiedb:hiedb")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hiedb-0.8.0.0.tar.gz";
      sha256 = "8500d0339bd2baeec255139290a1256bfbd3694bb945638a92d2e9161d38d849";
    });
  }) // {
    package-description-override = "cabal-version:       2.4\nname:                hiedb\nversion:             0.8.0.0\nsynopsis:            Generates a references DB from .hie files\ndescription:         Tool and library to index and query a collection of `.hie` files\nbug-reports:         https://github.com/wz1000/HieDb/issues\nlicense:             BSD-3-Clause\nlicense-file:        LICENSE\nauthor:              Zubin Duggal\nmaintainer:          zubin.duggal@gmail.com\ncopyright:           Zubin Duggal\ncategory:            Development\nextra-doc-files:\n  README.md\n  CHANGELOG.md\nextra-source-files:\n  test/data/*.hs\n  test/data/Sub/*.hs\ntested-with:         GHC ==9.0.2\n                      || ==9.2.8\n                      || ==9.4.8\n                      || ==9.6.7\n                      || ==9.8.4\n                      || ==9.10.3\n                      || ==9.12.2\n                      || ==9.14.1\n\nsource-repository head\n  type: git\n  location: https://github.com/wz1000/HieDb\n\ncommon common-options\n  default-language:    Haskell2010\n  build-depends:       base >= 4.12 && < 4.23\n  ghc-options:         -Wall\n                       -Wcompat\n                       -Widentities\n                       -Wincomplete-record-updates\n                       -Wincomplete-uni-patterns\n                       -Wpartial-fields\n                       -Wredundant-constraints\n                       -Wunused-packages\n                       -Wno-name-shadowing\n\nexecutable hiedb\n  import:              common-options\n  hs-source-dirs:      exe\n  main-is:             Main.hs\n  build-depends:       base\n                     , hiedb\n                     , ghc-paths\n\nlibrary\n  import:              common-options\n  hs-source-dirs:      src\n  exposed-modules:     HieDb,\n                       HieDb.Utils,\n                       HieDb.Create,\n                       HieDb.Query,\n                       HieDb.Compat,\n                       HieDb.Types,\n                       HieDb.Dump,\n                       HieDb.Html,\n                       HieDb.Run\n  build-depends:       ghc >= 8.6 && < 9.15\n                     , array\n                     , containers\n                     , filepath\n                     , directory\n                     , mtl\n                     , sqlite-simple\n                     , hie-compat ^>= 0.3\n                     , text\n                     , bytestring\n                     , algebraic-graphs >= 0.3\n                     , lucid\n                     , optparse-applicative\n                     , extra\n                     , ansi-terminal >= 0.9\n                     , terminal-size >= 0.2\n\ntest-suite hiedb-tests\n  import:             common-options\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     test\n  main-is:            Main.hs\n  other-modules:      Test.Orphans\n  build-tool-depends: hiedb:hiedb\n  build-depends:      directory\n                    , filepath\n                    , ghc-paths\n                    , hiedb\n                    , hspec\n                    , process\n                    , temporary\n                    , algebraic-graphs\n";
  }