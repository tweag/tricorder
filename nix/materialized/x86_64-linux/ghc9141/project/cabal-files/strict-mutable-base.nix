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
      specVersion = "3.0";
      identifier = { name = "strict-mutable-base"; version = "2.0.0.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "andrzej@rybczak.net";
      author = "Andrzej Rybczak";
      homepage = "https://github.com/arybczak/strict-mutable";
      url = "";
      synopsis = "Strict variants of mutable data types from base.";
      description = "Strict (WHNF) variants of @Chan@, @IORef@ and @MVar@ for proactive\nprevention of space leaks.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."strict-mutable-base" or (errorHandler.buildDepError "strict-mutable-base"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/strict-mutable-base-2.0.0.0.tar.gz";
      sha256 = "c4094420c46fa21e6c01d04a470a27c26619a8ca0505b76cf8758a0f03762de2";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\nbuild-type:         Simple\nname:               strict-mutable-base\nversion:            2.0.0.0\nhomepage:           https://github.com/arybczak/strict-mutable\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\ncategory:           Data\nmaintainer:         andrzej@rybczak.net\nauthor:             Andrzej Rybczak\n\nsynopsis: Strict variants of mutable data types from base.\n\ndescription: Strict (WHNF) variants of @Chan@, @IORef@ and @MVar@ for proactive\n             prevention of space leaks.\n\nextra-doc-files:\n  CHANGELOG.md\n  README.md\n\ntested-with: GHC == { 8.10.7, 9.0.2, 9.2.8, 9.4.8, 9.6.7, 9.8.4, 9.10.3, 9.12.4, 9.14.1 }\n\nbug-reports:   https://github.com/arybczak/strict-mutable/issues\nsource-repository head\n  type:     git\n  location: https://github.com/arybczak/strict-mutable.git\n\ncommon language\n    ghc-options:        -Wall -Wcompat\n\n    default-language:   Haskell2010\n\n    default-extensions: GeneralizedNewtypeDeriving\n                        LambdaCase\n                        MagicHash\n                        TupleSections\n                        UnboxedTuples\n\nlibrary\n    import:           language\n\n    build-depends:    base >=4.14 && < 5\n                    , deepseq >= 1.4.3.0\n\n    hs-source-dirs:   src\n\n    exposed-modules:  Control.Concurrent.Chan.Strict\n                      Control.Concurrent.MVar.Strict\n                      Data.IORef.Strict\n\ntest-suite test\n    import:           language\n\n    type:             exitcode-stdio-1.0\n\n    build-depends:    base\n                    , strict-mutable-base\n                    , tasty >= 1.0\n                    , tasty-hunit >= 0.10\n\n    hs-source-dirs:   tests\n\n    main-is:          Main.hs\n\n    other-modules:    ChanTests\n                      IORefTests\n                      MVarTests\n                      Utils\n\n    default-extensions: TypeApplications\n";
  }