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
    flags = { base4 = true; };
    package = {
      specVersion = "1.8";
      identifier = { name = "monad-loops"; version = "0.4.3"; };
      license = "LicenseRef-PublicDomain";
      copyright = "";
      maintainer = "James Cook <mokus@deepbondi.net>";
      author = "James Cook <mokus@deepbondi.net>";
      homepage = "https://github.com/mokus0/monad-loops";
      url = "";
      synopsis = "Monadic loops";
      description = "Some useful control operators for looping.\n\nNew in 0.4: STM loop operators have been split into a\nnew package instead of being conditionally-built.\n\nNew in 0.3.2.0: various functions for traversing lists and\ncomputing minima/maxima using arbitrary procedures to compare\nor score the elements.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
      tests = {
        "test-monad-loops" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."monad-loops" or (errorHandler.buildDepError "monad-loops"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/monad-loops-0.4.3.tar.gz";
      sha256 = "7eaaaf6bc43661e9e86e310ff8c56fbea16eb6bf13c31a2e28103138ac164c18";
    });
  }) // {
    package-description-override = "name:                   monad-loops\nversion:                0.4.3\nstability:              provisional\nlicense:                PublicDomain\n\ncabal-version:          >= 1.8\nbuild-type:             Simple\n\nauthor:                 James Cook <mokus@deepbondi.net>\nmaintainer:             James Cook <mokus@deepbondi.net>\nhomepage:               https://github.com/mokus0/monad-loops\n\ncategory:               Control\nsynopsis:               Monadic loops\ndescription:            Some useful control operators for looping.\n                        .\n                        New in 0.4: STM loop operators have been split into a\n                        new package instead of being conditionally-built.\n                        .\n                        New in 0.3.2.0: various functions for traversing lists and \n                        computing minima/maxima using arbitrary procedures to compare\n                        or score the elements.\n\nsource-repository head\n  type: git\n  location: git://github.com/mokus0/monad-loops.git\n\nFlag base4\n  Description:          Build using base >= 4\n  Default:              True\n\nLibrary\n  hs-source-dirs:       src\n  if impl(ghc >= 7)\n    ghc-options:        -Wall -fno-warn-unused-do-bind -fno-warn-name-shadowing\n  exposed-modules:      Control.Monad.Loops\n  if flag(base4)\n    cpp-options:        -Dbase4\n    build-depends:      base >= 4 && < 5\n  else\n    build-depends:      base >= 2 && < 4\n\nTest-Suite test-monad-loops\n    type:       exitcode-stdio-1.0\n    main-is:    Tests/test-monad-loops.hs\n    if flag(base4)\n      cpp-options:        -Dbase4\n      build-depends:      base >= 4 && < 5, tasty, tasty-hunit, monad-loops\n    else\n      build-depends:      base >= 2 && < 4, tasty, tasty-hunit, monad-loops";
  }