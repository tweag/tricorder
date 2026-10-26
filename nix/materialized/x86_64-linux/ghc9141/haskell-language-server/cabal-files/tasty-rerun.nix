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
      identifier = { name = "tasty-rerun"; version = "1.1.20"; };
      license = "BSD-3-Clause";
      copyright = "Oliver Charles (c) 2014,\nAndrew Lelechenko (c) 2019";
      maintainer = "ollie@ocharles.org.uk";
      author = "Oliver Charles";
      homepage = "http://github.com/ocharles/tasty-rerun";
      url = "";
      synopsis = "Rerun only tests which failed in a previous test run";
      description = "This ingredient\nfor the <https://hackage.haskell.org/package/tasty tasty> testing framework\nallows filtering a test tree depending\non the outcome of the previous run.\nThis may be useful in many scenarios,\nespecially when a test suite grows large.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."split" or (errorHandler.buildDepError "split"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tasty-rerun-1.1.20.tar.gz";
      sha256 = "7e8a2d0be2df0e1c864bc8b5f4e7ecb261d112981e68e1b0186f611faa44a55f";
    });
  }) // {
    package-description-override = "cabal-version:   2.2\r\nname:            tasty-rerun\r\nversion:         1.1.20\r\nx-revision: 4\r\nlicense:         BSD-3-Clause\r\nlicense-file:    LICENSE\r\ncopyright:\r\n    Oliver Charles (c) 2014,\r\n    Andrew Lelechenko (c) 2019\r\n\r\nmaintainer:      ollie@ocharles.org.uk\r\nauthor:          Oliver Charles\r\ntested-with:\r\n    ghc ==9.12.1 ghc ==9.10.1 ghc ==9.8.4 ghc ==9.6.6 ghc ==9.4.8\r\n\r\nhomepage:        http://github.com/ocharles/tasty-rerun\r\nsynopsis:        Rerun only tests which failed in a previous test run\r\ndescription:\r\n    This ingredient\r\n    for the <https://hackage.haskell.org/package/tasty tasty> testing framework\r\n    allows filtering a test tree depending\r\n    on the outcome of the previous run.\r\n    This may be useful in many scenarios,\r\n    especially when a test suite grows large.\r\n\r\ncategory:        Testing\r\nbuild-type:      Simple\r\nextra-doc-files:\r\n    Changelog.md\r\n    README.md\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/ocharles/tasty-rerun\r\n\r\nlibrary\r\n    exposed-modules:  Test.Tasty.Ingredients.Rerun\r\n    hs-source-dirs:   src\r\n    default-language: GHC2021\r\n    ghc-options:      -Wall -Wcompat\r\n    build-depends:\r\n        base >=4.17 && <4.24,\r\n        containers >=0.5.0.0 && <0.9,\r\n        filepath <1.6,\r\n        mtl >=2.1.2 && <2.4,\r\n        optparse-applicative >=0.6 && <0.20,\r\n        split >=0.1 && <0.3,\r\n        stm >=2.4.2 && <2.6,\r\n        tagged >=0.7 && <0.10,\r\n        tasty >=1.5 && <1.6,\r\n        transformers >=0.3.0.0 && <0.7\r\n";
  }