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
      identifier = { name = "tasty-hedgehog"; version = "1.4.0.2"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (c) 2017, Commonwealth Scientific and Industrial Research Organisation (CSIRO) ABN 41 687 119 230.";
      maintainer = "dave.laing.80@gmail.com";
      author = "Dave Laing";
      homepage = "https://github.com/qfpl/tasty-hedgehog";
      url = "";
      synopsis = "Integration for tasty and hedgehog.";
      description = "Integrates the <https://hackage.haskell.org/package/hedgehog hedgehog testing library> with the <https://hackage.haskell.org/package/tasty tasty testing framework>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
          (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
        ];
        buildable = true;
      };
      tests = {
        "tasty-hedgehog-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-expected-failure" or (errorHandler.buildDepError "tasty-expected-failure"))
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."tasty-hedgehog" or (errorHandler.buildDepError "tasty-hedgehog"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tasty-hedgehog-1.4.0.2.tar.gz";
      sha256 = "453484d732712525a9c74a07db5f18b5f80f867a98958e67031d8d0bfe007152";
    });
  }) // {
    package-description-override = "name:                tasty-hedgehog\r\nversion:             1.4.0.2\r\nx-revision: 9\r\nlicense:             BSD3\r\nlicense-file:        LICENCE\r\nauthor:              Dave Laing\r\nmaintainer:          dave.laing.80@gmail.com\r\ncopyright:           Copyright (c) 2017, Commonwealth Scientific and Industrial Research Organisation (CSIRO) ABN 41 687 119 230.\r\ndescription:         Integrates the <https://hackage.haskell.org/package/hedgehog hedgehog testing library> with the <https://hackage.haskell.org/package/tasty tasty testing framework>.\r\ncategory:            Testing\r\nsynopsis:            Integration for tasty and hedgehog.\r\nhomepage:            https://github.com/qfpl/tasty-hedgehog\r\nbug-reports:         https://github.com/qfpl/tasty-hedgehog/issues\r\nbuild-type:          Simple\r\nextra-source-files:  changelog.md\r\ncabal-version:       >=1.10\r\ntested-with:         GHC == 8.0.2, GHC == 8.2.2, GHC == 8.4.4, GHC == 8.6.5, GHC == 8.8.3, GHC == 8.10.1\r\n\r\nsource-repository   head\r\n  type:             git\r\n  location:         git@github.com:qfpl/tasty-hedgehog.git\r\n\r\nlibrary\r\n  exposed-modules:     Test.Tasty.Hedgehog\r\n  build-depends:       base >= 4.8 && <4.23\r\n                     , tagged >= 0.8 && < 0.10\r\n                     , tasty >= 0.11 && < 1.6\r\n                     , hedgehog >= 1.4 && < 1.8\r\n  hs-source-dirs:      src\r\n  ghc-options:         -Wall\r\n  default-language:    Haskell2010\r\n\r\ntest-suite tasty-hedgehog-tests\r\n  type:                exitcode-stdio-1.0\r\n  main-is:             Main.hs\r\n  hs-source-dirs:      test\r\n  build-depends:       base >= 4.8 && <4.23\r\n                     , tasty >= 0.11 && < 1.6\r\n                     , tasty-expected-failure >= 0.11 && < 0.13\r\n                     , hedgehog >= 1.4 && < 1.8\r\n                     , tasty-hedgehog\r\n  ghc-options:         -Wall\r\n  default-language:    Haskell2010\r\n";
  }