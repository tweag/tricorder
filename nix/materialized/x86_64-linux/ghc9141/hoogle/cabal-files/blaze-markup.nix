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
      identifier = { name = "blaze-markup"; version = "0.8.3.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Jasper Van der Jeugt <m@jaspervdj.be>";
      author = "Jasper Van der Jeugt, Simon Meier, Deepak Jois";
      homepage = "http://jaspervdj.be/blaze";
      url = "";
      synopsis = "A blazingly fast markup combinator library for Haskell";
      description = "Core modules of a blazingly fast markup combinator library for the Haskell\nprogramming language. The Text.Blaze module is a good\nstarting point, as well as this tutorial:\n<http://jaspervdj.be/blaze/tutorial.html>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
        ];
        buildable = true;
      };
      tests = {
        "blaze-markup-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/blaze-markup-0.8.3.0.tar.gz";
      sha256 = "8606ac8b4a1f7f8f1bbc0770b2752e9b6f88ccc9fbdcbb33aa20577d0e5930e8";
    });
  }) // {
    package-description-override = "Cabal-version: >= 1.10\nName:         blaze-markup\nVersion:      0.8.3.0\nx-revision:   2\nHomepage:     http://jaspervdj.be/blaze\nBug-Reports:  http://github.com/jaspervdj/blaze-markup/issues\nLicense:      BSD3\nLicense-file: LICENSE\nAuthor:       Jasper Van der Jeugt, Simon Meier, Deepak Jois\nMaintainer:   Jasper Van der Jeugt <m@jaspervdj.be>\nStability:    Experimental\nCategory:     Text\nSynopsis:     A blazingly fast markup combinator library for Haskell\nDescription:\n  Core modules of a blazingly fast markup combinator library for the Haskell\n  programming language. The Text.Blaze module is a good\n  starting point, as well as this tutorial:\n  <http://jaspervdj.be/blaze/tutorial.html>.\n\nBuild-type:    Simple\n\nTested-with:\n  GHC == 9.10.1\n  GHC == 9.8.2\n  GHC == 9.6.6\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nExtra-source-files:\n  CHANGELOG\n\nLibrary\n  Hs-source-dirs:   src\n  Ghc-Options:      -Wall\n  Default-language: Haskell2010\n\n  Exposed-modules:\n    Text.Blaze\n    Text.Blaze.Internal\n    Text.Blaze.Renderer.Pretty\n    Text.Blaze.Renderer.String\n    Text.Blaze.Renderer.Text\n    Text.Blaze.Renderer.Utf8\n\n  Build-depends:\n      base          >= 4    && < 5\n    , blaze-builder >= 0.3  && < 0.5\n    , text          >= 0.10 && < 2.2\n    , bytestring    >= 0.9  && < 0.13\n\nTest-suite blaze-markup-tests\n  Type:             exitcode-stdio-1.0\n  Hs-source-dirs:   src tests\n  Main-is:          TestSuite.hs\n  Ghc-options:      -Wall\n  Default-language: Haskell2010\n\n  Other-modules:\n    Text.Blaze\n    Text.Blaze.Internal\n    Text.Blaze.Renderer.Pretty\n    Text.Blaze.Renderer.String\n    Text.Blaze.Renderer.Text\n    Text.Blaze.Renderer.Utf8\n    Text.Blaze.Tests\n    Text.Blaze.Tests.Util\n\n  Build-depends:\n    -- Copied from regular dependencies...\n      base          >= 4    && < 5\n    , blaze-builder >= 0.3  && < 0.5\n    , text          >= 0.10 && < 2.2\n    , bytestring    >= 0.9  && < 0.13\n    -- Extra dependencies\n    , HUnit            >= 1.2  && < 1.7\n    , QuickCheck       >= 2.7  && < 3\n    , containers       >= 0.3  && < 0.8\n    , tasty            >= 1.0  && < 1.6\n    , tasty-hunit      >= 0.10 && < 0.11\n    , tasty-quickcheck >= 0.10 && < 1\n\nSource-repository head\n  Type:     git\n  Location: http://github.com/jaspervdj/blaze-markup\n";
  }