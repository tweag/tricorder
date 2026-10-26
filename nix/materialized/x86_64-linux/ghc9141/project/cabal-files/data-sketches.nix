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
      identifier = { name = "data-sketches"; version = "0.4.0.1"; };
      license = "LicenseRef-Apache";
      copyright = "2025 Ian Duncan, Rob Bassi, Mercury Technologies";
      maintainer = "ian@iankduncan.com";
      author = "Ian Duncan, Rob Bassi";
      homepage = "https://github.com/iand675/datasketches-haskell#readme";
      url = "";
      synopsis = "Stochastic streaming algorithms for approximate computation on large datasets. Includes KLL, HLL, Theta, Count-Min, and REQ sketches.";
      description = "Please see the README on GitHub at <https://github.com/iand675/datasketches-haskell#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."data-sketches-core" or (errorHandler.buildDepError "data-sketches-core"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "data-sketches-test" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."data-sketches" or (errorHandler.buildDepError "data-sketches"))
            (hsPkgs."data-sketches-core" or (errorHandler.buildDepError "data-sketches-core"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."pretty-show" or (errorHandler.buildDepError "pretty-show"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."statistics" or (errorHandler.buildDepError "statistics"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."data-sketches" or (errorHandler.buildDepError "data-sketches"))
            (hsPkgs."data-sketches-core" or (errorHandler.buildDepError "data-sketches-core"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/data-sketches-0.4.0.1.tar.gz";
      sha256 = "df65e2acf0f67420b0909cb848042b8b3fa3e50df8a90d4917d49302a94a265e";
    });
  }) // {
    package-description-override = "cabal-version: 1.18\n\n-- This file has been generated from package.yaml by hpack version 0.38.1.\n--\n-- see: https://github.com/sol/hpack\n\nname:           data-sketches\nversion:        0.4.0.1\nsynopsis:       Stochastic streaming algorithms for approximate computation on large datasets. Includes KLL, HLL, Theta, Count-Min, and REQ sketches.\ndescription:    Please see the README on GitHub at <https://github.com/iand675/datasketches-haskell#readme>\ncategory:       Data\nhomepage:       https://github.com/iand675/datasketches-haskell#readme\nbug-reports:    https://github.com/iand675/datasketches-haskell/issues\nauthor:         Ian Duncan, Rob Bassi\nmaintainer:     ian@iankduncan.com\ncopyright:      2025 Ian Duncan, Rob Bassi, Mercury Technologies\nlicense:        Apache\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\nextra-doc-files:\n    docs/images/KllErrorK100SL11.png\n    docs/images/ReqErrorHraK12SL11_LT.png\n    docs/images/ReqErrorLraK12SL11_LE.png\n\nsource-repository head\n  type: git\n  location: https://github.com/iand675/datasketches-haskell\n\nlibrary\n  exposed-modules:\n      DataSketches.Quantiles.RelativeErrorQuantile\n      DataSketches.Quantiles.KLL\n      DataSketches.Frequencies.CountMin\n      DataSketches.Distinct.HyperLogLog\n      DataSketches.Distinct.Theta\n  other-modules:\n      Paths_data_sketches\n  hs-source-dirs:\n      src\n  default-extensions:\n      BangPatterns\n      FlexibleInstances\n      RecordWildCards\n      ScopedTypeVariables\n      StandaloneDeriving\n      TypeFamilies\n      TypeOperators\n  build-depends:\n      base >=4.7 && <5\n    , data-sketches-core ==0.3.*\n    , ghc-prim\n    , primitive\n    , vector\n  default-language: Haskell2010\n\ntest-suite data-sketches-test\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      BugFixSpec\n      CountMinSpec\n      CrossValidationSpec\n      HyperLogLogSpec\n      KllSpec\n      ProofCheckSpec\n      RelativeErrorQuantileSpec\n      ThetaSpec\n      Paths_data_sketches\n  hs-source-dirs:\n      test\n  default-extensions:\n      BangPatterns\n      FlexibleInstances\n      RecordWildCards\n      ScopedTypeVariables\n      StandaloneDeriving\n      TypeFamilies\n      TypeOperators\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  build-depends:\n      QuickCheck\n    , base >=4.7 && <5\n    , data-sketches\n    , data-sketches-core\n    , directory\n    , ghc-prim\n    , hedgehog\n    , hspec\n    , pretty-show\n    , primitive\n    , process\n    , statistics\n    , temporary\n    , vector\n  default-language: Haskell2010\n\nbenchmark bench\n  type: exitcode-stdio-1.0\n  main-is: Bench.hs\n  other-modules:\n      Paths_data_sketches\n  hs-source-dirs:\n      bench\n  default-extensions:\n      BangPatterns\n      FlexibleInstances\n      RecordWildCards\n      ScopedTypeVariables\n      StandaloneDeriving\n      TypeFamilies\n      TypeOperators\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N -O2\n  build-depends:\n      base >=4.7 && <5\n    , criterion\n    , data-sketches\n    , data-sketches-core\n    , ghc-prim\n    , primitive\n    , vector\n  default-language: Haskell2010\n";
  }