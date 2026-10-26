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
      identifier = { name = "blaze-html"; version = "0.9.2.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Jasper Van der Jeugt <m@jaspervdj.be>";
      author = "Jasper Van der Jeugt, Simon Meier";
      homepage = "http://jaspervdj.be/blaze";
      url = "";
      synopsis = "A blazingly fast HTML combinator library for Haskell";
      description = "A blazingly fast HTML combinator library for the Haskell\nprogramming language. The Text.Blaze module is a good\nstarting point, as well as this tutorial:\n<http://jaspervdj.be/blaze/tutorial.html>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
          (hsPkgs."blaze-markup" or (errorHandler.buildDepError "blaze-markup"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "blaze-html-tests" = {
          depends = [
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."test-framework" or (errorHandler.buildDepError "test-framework"))
            (hsPkgs."test-framework-hunit" or (errorHandler.buildDepError "test-framework-hunit"))
            (hsPkgs."test-framework-quickcheck2" or (errorHandler.buildDepError "test-framework-quickcheck2"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
            (hsPkgs."blaze-markup" or (errorHandler.buildDepError "blaze-markup"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/blaze-html-0.9.2.0.tar.gz";
      sha256 = "65542ef39f7644a3d76afcadeb976d3e334c6947516b7313fcb59165cea1608f";
    });
  }) // {
    package-description-override = "Cabal-version: >= 1.10\nName:          blaze-html\nVersion:       0.9.2.0\nx-revision:    1\nHomepage:      http://jaspervdj.be/blaze\nBug-Reports:   http://github.com/jaspervdj/blaze-html/issues\nLicense:       BSD3\nLicense-file:  LICENSE\nAuthor:        Jasper Van der Jeugt, Simon Meier\nMaintainer:    Jasper Van der Jeugt <m@jaspervdj.be>\nStability:     Experimental\nCategory:      Text\nSynopsis:      A blazingly fast HTML combinator library for Haskell\nDescription:\n  A blazingly fast HTML combinator library for the Haskell\n  programming language. The Text.Blaze module is a good\n  starting point, as well as this tutorial:\n  <http://jaspervdj.be/blaze/tutorial.html>.\n\nBuild-type:    Simple\n\nTested-with:\n  GHC == 9.10.1\n  GHC == 9.8.2\n  GHC == 9.6.6\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nExtra-source-files:\n  CHANGELOG\n  src/Util/Sanitize.hs\n  src/Util/GenerateHtmlCombinators.hs\n\nLibrary\n  Hs-source-dirs:   src\n  Ghc-Options:      -Wall\n  Default-language: Haskell98\n\n  Exposed-modules:\n    Text.Blaze.Html\n    Text.Blaze.Html.Renderer.Pretty\n    Text.Blaze.Html.Renderer.String\n    Text.Blaze.Html.Renderer.Text\n    Text.Blaze.Html.Renderer.Utf8\n    Text.Blaze.Html4.FrameSet\n    Text.Blaze.Html4.FrameSet.Attributes\n    Text.Blaze.Html4.Strict\n    Text.Blaze.Html4.Strict.Attributes\n    Text.Blaze.Html4.Transitional\n    Text.Blaze.Html4.Transitional.Attributes\n    Text.Blaze.Html5\n    Text.Blaze.Html5.Attributes\n    Text.Blaze.XHtml1.FrameSet\n    Text.Blaze.XHtml1.FrameSet.Attributes\n    Text.Blaze.XHtml1.Strict\n    Text.Blaze.XHtml1.Strict.Attributes\n    Text.Blaze.XHtml1.Transitional\n    Text.Blaze.XHtml1.Transitional.Attributes\n    Text.Blaze.XHtml5\n    Text.Blaze.XHtml5.Attributes\n\n  Build-depends:\n    base          >= 4    && < 5,\n    blaze-builder >= 0.3  && < 0.5,\n    blaze-markup  >= 0.8  && < 0.9,\n    bytestring    >= 0.9  && < 0.13,\n    text          >= 0.10 && < 2.2\n\nTest-suite blaze-html-tests\n  Type:             exitcode-stdio-1.0\n  Hs-source-dirs:   src tests\n  Main-is:          TestSuite.hs\n  Ghc-options:      -Wall\n  Default-language: Haskell98\n\n  Other-modules:\n    Text.Blaze.Html\n    Text.Blaze.Html.Renderer.String\n    Text.Blaze.Html.Renderer.Text\n    Text.Blaze.Html.Renderer.Utf8\n    Text.Blaze.Html.Tests\n    Text.Blaze.Html.Tests.Util\n    Text.Blaze.Html5\n    Text.Blaze.Html5.Attributes\n    Util.Sanitize\n    Util.Tests\n\n  Build-depends:\n    HUnit                      >= 1.2 && < 1.7,\n    QuickCheck                 >= 2.4 && < 3,\n    containers                 >= 0.3 && < 0.8,\n    test-framework             >= 0.4 && < 0.9,\n    test-framework-hunit       >= 0.3 && < 0.4,\n    test-framework-quickcheck2 >= 0.3 && < 0.4,\n    -- Copied from regular dependencies...\n    base          >= 4    && < 5,\n    blaze-builder >= 0.3  && < 0.5,\n    blaze-markup  >= 0.8  && < 0.9,\n    bytestring    >= 0.9  && < 0.13,\n    text          >= 0.10 && < 2.2\n\nSource-repository head\n  Type:     git\n  Location: http://github.com/jaspervdj/blaze-html.git\n";
  }