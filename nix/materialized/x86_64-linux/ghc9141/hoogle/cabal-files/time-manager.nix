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
      identifier = { name = "time-manager"; version = "0.3.2"; };
      license = "MIT";
      copyright = "";
      maintainer = "kazu@iij.ad.jp";
      author = "Michael Snoyman and Kazu Yamamoto";
      homepage = "http://github.com/yesodweb/wai";
      url = "";
      synopsis = "Scalable timer";
      description = "Scalable timer functions provided by a timer manager\nand thread management functions to prevent thread\nleak by a thread manager.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/time-manager-0.3.2.tar.gz";
      sha256 = "776dec1e000a9c306b1747495776c2400591a6b51b2cd58b835cd7a429ed3619";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               time-manager\nversion:            0.3.2\nlicense:            MIT\nlicense-file:       LICENSE\nmaintainer:         kazu@iij.ad.jp\nauthor:             Michael Snoyman and Kazu Yamamoto\nstability:          Stable\nhomepage:           http://github.com/yesodweb/wai\nsynopsis:           Scalable timer\ndescription:\n    Scalable timer functions provided by a timer manager\n    and thread management functions to prevent thread\n    leak by a thread manager.\n\ncategory:           System\nbuild-type:         Simple\nextra-source-files: ChangeLog.md\n                    README.md\n\nlibrary\n    exposed-modules:\n        System.TimeManager\n        System.ThreadManager\n    other-modules:\n        System.TimeManager.Internal\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.12 && <5,\n        containers,\n        stm\n\ntest-suite spec\n    type:             exitcode-stdio-1.0\n    main-is:          test/Spec.hs\n    other-modules:\n        System.TimeManager,\n        System.TimeManager.Internal\n    build-depends:    base\n    default-language: Haskell2010\n    ghc-options:      -Wall -threaded\n    build-depends:\n        base >=4.12 && <5,\n        hspec,\n        HUnit\n";
  }