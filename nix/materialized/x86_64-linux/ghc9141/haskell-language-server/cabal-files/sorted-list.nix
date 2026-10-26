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
      specVersion = "1.18";
      identifier = { name = "sorted-list"; version = "0.3.1.0"; };
      license = "MIT";
      copyright = "";
      maintainer = "Daniel Casanueva (coding `at` danielcasanueva.eu)";
      author = "Daniel Casanueva (coding `at` danielcasanueva.eu)";
      homepage = "";
      url = "";
      synopsis = "Type-enforced sorted lists and related functions.";
      description = "Type-enforced sorted lists and related functions.\n\nThese are useful for:\n\n* Constraining the argument of a function to be a sorted list\nby stating in your type that the input list is a sorted list.\n\n* Avoiding sorting a list twice.\n\n* Creating a list that is sorted from the moment of its construction,\nso it doesn't have to be sorted later.\n\n* Performing list operations keeping the input list sorted.\n\n* Improving those list operations that can be\nbenefited from the ordering of its elements.\n\n* Creating infinite lists that are sorted!\n\n* And more!\n\nIf you are missing a feature, do not hesitate\nto ask by opening an issue at the bug-tracker.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
        ];
        buildable = true;
      };
      tests = {
        "sorted-list-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."sorted-list" or (errorHandler.buildDepError "sorted-list"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "sorted-list-map-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."sorted-list" or (errorHandler.buildDepError "sorted-list"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/sorted-list-0.3.1.0.tar.gz";
      sha256 = "b4cea33b2536217010ea80152978b2005b0bbe1aa6fb271efc7b9884267dbcb1";
    });
  }) // {
    package-description-override = "name:                sorted-list\nversion:             0.3.1.0\nsynopsis:            Type-enforced sorted lists and related functions.\ndescription:         Type-enforced sorted lists and related functions.\n                     .\n                     These are useful for:\n                     .\n                     * Constraining the argument of a function to be a sorted list\n                       by stating in your type that the input list is a sorted list.\n                     .\n                     * Avoiding sorting a list twice.\n                     .\n                     * Creating a list that is sorted from the moment of its construction,\n                       so it doesn't have to be sorted later.\n                     .\n                     * Performing list operations keeping the input list sorted.\n                     .\n                     * Improving those list operations that can be\n                       benefited from the ordering of its elements.\n                     .\n                     * Creating infinite lists that are sorted!\n                     .\n                     * And more!\n                     .\n                     If you are missing a feature, do not hesitate\n                     to ask by opening an issue at the bug-tracker.\nlicense:             MIT\nlicense-file:        license\nauthor:              Daniel Casanueva (coding `at` danielcasanueva.eu)\nmaintainer:          Daniel Casanueva (coding `at` danielcasanueva.eu)\nbug-reports:         https://codeberg.org/daniel-casanueva/sorted-list/issues\ncategory:            Data\nbuild-type:          Simple\ncabal-version:       1.18\nextra-doc-files:     readme.md, changelog.md\n\nsource-repository head\n  type: git\n  location: https://codeberg.org/daniel-casanueva/sorted-list.git\n  branch: main\n\nlibrary\n  default-language:    Haskell2010\n  ghc-options:         -Wall -Wunused-packages\n  build-depends:       base == 4.*\n               ,       deepseq\n               ,       QuickCheck\n  exposed-modules:     Data.SortedList\n\nbenchmark sorted-list-map-bench\n  default-language: Haskell2010\n  type: exitcode-stdio-1.0\n  hs-source-dirs: bench\n  main-is: map.hs\n  ghc-options: -Wall\n  build-depends: base == 4.*\n               , sorted-list\n               , criterion\n\ntest-suite sorted-list-tests\n  default-language: Haskell2010\n  type: exitcode-stdio-1.0\n  hs-source-dirs: tests\n  main-is: Main.hs\n  ghc-options: -Wall\n  build-depends: base, sorted-list, QuickCheck\n";
  }