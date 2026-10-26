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
      specVersion = "2.2";
      identifier = { name = "integer-conversion"; version = "0.1.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2023 Oleg Grenrus";
      maintainer = "Oleg.Grenrus <oleg.grenrus@iki.fi>";
      author = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      homepage = "https://github.com/phadej/integer-conversion";
      url = "";
      synopsis = "Conversion from strings to Integer";
      description = "The naive @foldl' (\\acc d -> acc * 10 + d) 0@ is expensive (quadratic!) for large @Integer@s.\nThis package provides sub-quadratic implementation.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "integer-conversion-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."integer-conversion" or (errorHandler.buildDepError "integer-conversion"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "integer-conversion-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."integer-conversion" or (errorHandler.buildDepError "integer-conversion"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/integer-conversion-0.1.1.tar.gz";
      sha256 = "c18164a048073310f6353ebc64c9037b52a4b8299963ce05e027bcf60e22155a";
    });
  }) // {
    package-description-override = "cabal-version:      2.2\nname:               integer-conversion\nversion:            0.1.1\nx-revision:         2\nsynopsis:           Conversion from strings to Integer\ncategory:           Data\ndescription:\n  The naive @foldl' (\\acc d -> acc * 10 + d) 0@ is expensive (quadratic!) for large @Integer@s.\n  This package provides sub-quadratic implementation.\n\nhomepage:           https://github.com/phadej/integer-conversion\nbug-reports:        https://github.com/phadej/integer-conversion/issues\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nauthor:             Oleg Grenrus <oleg.grenrus@iki.fi>\nmaintainer:         Oleg.Grenrus <oleg.grenrus@iki.fi>\ncopyright:          (c) 2023 Oleg Grenrus\nbuild-type:         Simple\nextra-source-files: ChangeLog.md\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.2\n   || ==9.12.2\n   || ==9.14.1\n\nsource-repository head\n  type:     git\n  location: https://github.com/phadej/integer-conversion.git\n\nlibrary\n  default-language: Haskell2010\n  hs-source-dirs:   src\n  exposed-modules:  Data.Integer.Conversion\n  build-depends:\n    , base        >=4.12.0.0   && <4.23\n    , bytestring  ^>=0.10.8.1 || ^>=0.11.4.0 || ^>=0.12.0.2\n    , primitive   ^>=0.9.0.0\n    , text        ^>=1.2.3.0  || ^>=2.0.1    || ^>=2.1\n\ntest-suite integer-conversion-tests\n  default-language: Haskell2010\n  hs-source-dirs:   tests src-other\n  type:             exitcode-stdio-1.0\n  main-is:          integer-conversion-tests.hs\n  build-depends:\n    , base\n    , bytestring\n    , integer-conversion\n    , text\n\n  -- test dependencies\n  build-depends:\n    , QuickCheck        ^>=2.14.3 || ^>=2.15 || ^>=2.16.0.0 || ^>=2.17.1.0\n    , tasty             ^>=1.4.3  || ^>=1.5\n    , tasty-quickcheck  ^>=0.10.2 || ^>=0.11\n\n  other-modules:\n    Alternative\n    Naive\n\nbenchmark integer-conversion-bench\n  default-language: Haskell2010\n  ghc-options:      -threaded -rtsopts\n  type:             exitcode-stdio-1.0\n  main-is:          integer-conversion-bench.hs\n  hs-source-dirs:   bench src-other\n  build-depends:\n    , base\n    , bytestring\n    , integer-conversion\n    , text\n\n  -- bench dependencies\n  build-depends:    tasty-bench ^>=0.3.4 || ^>=0.4.1 || ^>=0.5\n  other-modules:\n    Alternative\n    Naive\n";
  }