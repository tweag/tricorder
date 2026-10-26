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
      specVersion = "2.0";
      identifier = { name = "generic-arbitrary"; version = "1.0.1.2"; };
      license = "MIT";
      copyright = "";
      maintainer = "makeit@typeable.io";
      author = "Typeable.io contributors";
      homepage = "http://github.com/typeable/generic-arbitrary#readme";
      url = "";
      synopsis = "Generic implementation for QuickCheck's Arbitrary";
      description = "Generic implementations of methods of the 'Arbitrary' class from the\nQuickCheck library. The approach taken here can lead to diverging instances\nfor mutually recursive types but is safe for simply recursive ones and guarantees\nflat distribution for constructors of sum-types.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."generic-arbitrary" or (errorHandler.buildDepError "generic-arbitrary"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-discover" or (errorHandler.buildDepError "tasty-discover"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.tasty-discover.components.exes.tasty-discover or (pkgs.pkgsBuildBuild.tasty-discover or (errorHandler.buildToolDepError "tasty-discover:tasty-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/generic-arbitrary-1.0.1.2.tar.gz";
      sha256 = "3d4138b74c7cd22697f8ffd02b197153dc31117ed7590014d3e933cf9ae5979d";
    });
  }) // {
    package-description-override = "name:                generic-arbitrary\nversion:             1.0.1.2\nsynopsis:            Generic implementation for QuickCheck's Arbitrary\ndescription:\n    Generic implementations of methods of the 'Arbitrary' class from the\n    QuickCheck library. The approach taken here can lead to diverging instances\n    for mutually recursive types but is safe for simply recursive ones and guarantees\n    flat distribution for constructors of sum-types.\n\nlicense:             MIT\nlicense-file:        LICENSE\nauthor:              Typeable.io contributors\nmaintainer:          makeit@typeable.io\nhomepage:            http://github.com/typeable/generic-arbitrary#readme\ncategory:            Generic\nbuild-type:          Simple\nextra-source-files:  CHANGELOG.md\n                   , README.md\ncabal-version:       2.0\ntested-with: GHC == 8.6.5\n           , GHC == 8.10.7\n           , GHC == 9.0.2\n           , GHC == 9.2.4\n           , GHC == 9.4.3\n           , GHC == 9.8.1\n\nsource-repository head\n  type:     git\n  location: https://github.com/typeable/generic-arbitrary.git\n\nlibrary\n  exposed-modules:     Test.QuickCheck.Arbitrary.Generic\n  build-depends:       base >=4.8 && <5\n                     , QuickCheck >=2.8\n  hs-source-dirs:      src\n  default-language:    Haskell2010\n  default-extensions: AllowAmbiguousTypes\n                    , CPP\n                    , ConstraintKinds\n                    , DataKinds\n                    , DeriveGeneric\n                    , FlexibleContexts\n                    , FlexibleInstances\n                    , GeneralizedNewtypeDeriving\n                    , LambdaCase\n                    , MultiParamTypeClasses\n                    , PolyKinds\n                    , RankNTypes\n                    , ScopedTypeVariables\n                    , TypeFamilies\n                    , TypeOperators\n                    , TypeSynonymInstances\n                    , UndecidableInstances\n                    , ViewPatterns\n\n\ntest-suite test\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   test\n  main-is:          Test.hs\n  default-language: Haskell2010\n  build-depends:    base >=4.12 && <5\n                  , QuickCheck >=2.10\n                  , deepseq\n                  , generic-arbitrary\n                  , tasty >=1.4.2 || <1.4.0.1\n                  , tasty-discover >= 2.0.0\n                  , tasty-hunit >= 0.9.2\n                  , tasty-quickcheck\n  other-modules: Auxiliary\n               , EnumTest\n               , LimitationDemo\n               , NoTypecheckTest\n               , ParametersTest\n               , RecursiveTest\n  default-extensions: AllowAmbiguousTypes\n                    , CPP\n                    , DataKinds\n                    , DeriveAnyClass\n                    , DeriveGeneric\n                    , DerivingStrategies\n                    , DerivingVia\n                    , FlexibleContexts\n                    , FlexibleInstances\n                    , GeneralizedNewtypeDeriving\n                    , LambdaCase\n                    , MultiParamTypeClasses\n                    , PolyKinds\n                    , RankNTypes\n                    , ScopedTypeVariables\n                    , TypeApplications\n                    , TypeFamilies\n                    , TypeOperators\n                    , TypeSynonymInstances\n                    , UndecidableInstances\n                    , ViewPatterns\n  build-tool-depends: tasty-discover:tasty-discover\n  ghc-options:      -Wall\n                    -threaded\n                    -rtsopts\n                    \"-with-rtsopts=-N -A64m -qb0 -n4m -T -I1\"\n";
  }