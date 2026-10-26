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
      identifier = { name = "Diff"; version = "1.0.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "David Fox <dsf@seereason.com>";
      author = "Sterling Clover";
      homepage = "https://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.4.6927";
      url = "";
      synopsis = "Diff algorithm in pure Haskell";
      description = "Implementation of the standard diff algorithm in Haskell.\n\nTime complexity is O(ND) (input length * number of differences).\nSpace complexity is O(D^2).  Includes utilities for pretty printing.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
        ];
        buildable = true;
      };
      tests = {
        "diff-tests" = {
          depends = [
            (hsPkgs."Diff" or (errorHandler.buildDepError "Diff"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."test-framework" or (errorHandler.buildDepError "test-framework"))
            (hsPkgs."test-framework-quickcheck2" or (errorHandler.buildDepError "test-framework-quickcheck2"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/Diff-1.0.2.tar.gz";
      sha256 = "cd7e26d3d5ebf7f2c1a7525aebe251fbcbffee2a6362db634b4be23b9e354d85";
    });
  }) // {
    package-description-override = "Cabal-Version:       1.18\nname:                Diff\nversion:             1.0.2\nsynopsis:            Diff algorithm in pure Haskell\ndescription:         Implementation of the standard diff algorithm in Haskell.\n .\n Time complexity is O(ND) (input length * number of differences).\n Space complexity is O(D^2).  Includes utilities for pretty printing.\ncategory:            Algorithms\nhomepage:            https://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.4.6927\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              Sterling Clover\nmaintainer:          David Fox <dsf@seereason.com>\nBuild-Type:          Simple\n\ntested-with:\n  GHC == 9.12.0\n  GHC == 9.10.1\n  GHC == 9.8.2\n  GHC == 9.6.6\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n\nextra-doc-files:     CHANGELOG.md\n\nlibrary\n  default-language: Haskell2010\n  build-depends:\n      base >= 4.11 && <= 6\n    , array\n    , pretty >= 1.1\n  hs-source-dirs:  src\n  exposed-modules:\n                   Data.Algorithm.Diff,\n                   Data.Algorithm.DiffOutput\n                   Data.Algorithm.DiffContext\n  ghc-options:     -Wall -funbox-strict-fields\n\nsource-repository head\n  type:      git\n  location:  https://github.com/seereason/Diff\n\ntest-suite diff-tests\n  default-language: Haskell2010\n  type: exitcode-stdio-1.0\n  hs-source-dirs: test\n  main-is: Test.hs\n  build-depends:\n      Diff\n    , base >= 3 && <= 6\n    , array\n    , pretty\n    , directory\n    , process\n    , QuickCheck\n    , test-framework\n    , test-framework-quickcheck2\n";
  }