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
      specVersion = "1.10";
      identifier = { name = "row-types"; version = "1.0.1.2"; };
      license = "MIT";
      copyright = "";
      maintainer = "dwincort@gmail.com";
      author = "Daniel Winograd-Cort, Matthew Farkas-Dyck";
      homepage = "https://github.com/dwincort/row-types";
      url = "";
      synopsis = "Open Records and Variants";
      description = "This package uses closed type families and type literals to implement open\nrecords and variants.\nThe core is based off of the <https://hackage.haskell.org/package/CTRex CTRex>\npackage, but it also includes polymorphic variants and a number of\nadditional functions.  That said, it is not a proper superset of CTRex as it\nspecifically forbids records from having more than one element of the same\nlabel.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."constraints" or (errorHandler.buildDepError "constraints"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."generic-lens" or (errorHandler.buildDepError "generic-lens"))
          (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."generic-lens" or (errorHandler.buildDepError "generic-lens"))
            (hsPkgs."row-types" or (errorHandler.buildDepError "row-types"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "perf" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."row-types" or (errorHandler.buildDepError "row-types"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."gauge" or (errorHandler.buildDepError "gauge"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/row-types-1.0.1.2.tar.gz";
      sha256 = "0ea98606fe49d69311800ae29200162dd2dd915088da197b8b9a9fe818b46e17";
    });
  }) // {
    package-description-override = "Name:                row-types\r\nVersion:             1.0.1.2\r\nx-revision: 1\r\nLicense:             MIT\r\nLicense-file:        LICENSE\r\nAuthor:              Daniel Winograd-Cort, Matthew Farkas-Dyck\r\nMaintainer:          dwincort@gmail.com\r\nhomepage:            https://github.com/dwincort/row-types\r\nBuild-Type:          Simple\r\nCabal-Version:       >=1.10\r\nTested-With:         GHC == 8.6.5, GHC == 8.8.3, GHC == 8.10.7, GHC == 9.0.1\r\nCategory:            Data, Data Structures\r\nSynopsis:\t           Open Records and Variants\r\nDescription:\r\n  This package uses closed type families and type literals to implement open\r\n  records and variants.\r\n  The core is based off of the <https://hackage.haskell.org/package/CTRex CTRex>\r\n  package, but it also includes polymorphic variants and a number of\r\n  additional functions.  That said, it is not a proper superset of CTRex as it\r\n  specifically forbids records from having more than one element of the same\r\n  label.\r\n\r\nextra-source-files:\r\n  examples/Examples.lhs\r\n  README.md\r\n  CHANGELOG.md\r\n  LICENSE\r\n  NOTICE\r\n\r\nLibrary\r\n  Build-Depends:\r\n    base >= 2 && < 6,\r\n    constraints >= 0.11,\r\n    deepseq >= 1.4,\r\n    hashable >= 1.2,\r\n    unordered-containers >= 0.2,\r\n    generic-lens >= 1.0.0.0,\r\n    profunctors >= 5.0,\r\n    text\r\n  Exposed-modules:\r\n      Data.Row\r\n    , Data.Row.Internal\r\n    , Data.Row.Dictionaries\r\n    , Data.Row.Records\r\n    , Data.Row.Variants\r\n    , Data.Row.Switch\r\n  hs-source-dirs:\r\n    src\r\n  ghc-options: -W\r\n  default-language: Haskell2010\r\n  default-extensions:\r\n      DataKinds\r\n    , ExplicitForAll\r\n    , GADTs\r\n    , OverloadedLabels\r\n    , TypeApplications\r\n    , TypeOperators\r\n\r\nbenchmark perf\r\n  type: exitcode-stdio-1.0\r\n  main-is: Main.hs\r\n  hs-source-dirs:\r\n      benchmarks/perf\r\n  ghc-options: -W\r\n  build-depends: base >= 2 && < 6\r\n               , row-types\r\n               , deepseq >= 1.4\r\n               , gauge >= 0.2.0\r\n  default-language: Haskell2010\r\n  default-extensions: AllowAmbiguousTypes,\r\n              DataKinds,\r\n              OverloadedLabels,\r\n              RankNTypes,\r\n              ScopedTypeVariables,\r\n              TypeApplications,\r\n              TypeFamilies,\r\n              TypeOperators\r\n\r\ntest-suite test\r\n  type: exitcode-stdio-1.0\r\n  main-is: Main.hs\r\n  hs-source-dirs: tests, examples\r\n  ghc-options: -W +RTS -M1G -RTS\r\n  other-modules: Examples,\r\n                 DiffPerformance,\r\n                 MergePerformance,\r\n                 UnionPerformance\r\n  build-depends: base >= 2 && < 6\r\n               , generic-lens >= 1.1.0.0\r\n               , row-types\r\n  default-language: Haskell2010\r\n  default-extensions: AllowAmbiguousTypes,\r\n              DataKinds,\r\n              FlexibleContexts,\r\n              OverloadedLabels,\r\n              PatternSynonyms,\r\n              RankNTypes,\r\n              ScopedTypeVariables,\r\n              TypeApplications,\r\n              TypeFamilies,\r\n              TypeOperators,\r\n              ViewPatterns\r\n\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/target/row-types/\r\n";
  }