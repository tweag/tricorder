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
      identifier = { name = "parallel"; version = "3.3.0.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "libraries@haskell.org";
      author = "";
      homepage = "";
      url = "";
      synopsis = "Parallel programming library";
      description = "This package provides a library for parallel programming.\n\nFor documentation, start from the \"Control.Parallel.Strategies\"\nmodule below.\n\nFor more tutorial documentation, see the book <https://simonmar.github.io/pages/pcph.html Parallel and Concurrent Programming in Haskell>.\n\nTo understand the principles behind the library, see\n<https://simonmar.github.io/bib/papers/strategies.pdf Seq no more: Better Strategies for Parallel Haskell>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/parallel-3.3.0.0.tar.gz";
      sha256 = "47c21e778d8e8ebf657aa72fd30e189e71ffddb188660e9d09ca9062d7541791";
    });
  }) // {
    package-description-override = "cabal-version:  >=1.10\r\nname:           parallel\r\nversion:        3.3.0.0\r\nx-revision: 1\r\n-- NOTE: Don't forget to update ./changelog.md\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\nmaintainer:     libraries@haskell.org\r\nbug-reports:    https://github.com/haskell/parallel/issues\r\nsynopsis:       Parallel programming library\r\ncategory:       Control, Parallelism\r\nbuild-type:     Simple\r\n\r\ntested-with:\r\n  GHC == 9.14.1\r\n  GHC == 9.12.2\r\n  GHC == 9.10.1\r\n  GHC == 9.8.4\r\n  GHC == 9.6.7\r\n  GHC == 9.4.8\r\n  GHC == 9.2.8\r\n  GHC == 9.0.2\r\n  GHC == 8.10.7\r\n  GHC == 8.8.4\r\n  GHC == 8.6.5\r\n  GHC == 8.4.4\r\n  GHC == 8.2.2\r\n  GHC == 8.0.2\r\n  MHS\r\n\r\ndescription:\r\n    This package provides a library for parallel programming.\r\n    .\r\n    For documentation, start from the \"Control.Parallel.Strategies\"\r\n    module below.\r\n    .\r\n    For more tutorial documentation, see the book <https://simonmar.github.io/pages/pcph.html Parallel and Concurrent Programming in Haskell>.\r\n    .\r\n    To understand the principles behind the library, see\r\n    <https://simonmar.github.io/bib/papers/strategies.pdf Seq no more: Better Strategies for Parallel Haskell>.\r\n\r\n\r\nextra-source-files: changelog.md\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/haskell/parallel.git\r\n\r\nlibrary\r\n    default-language: Haskell2010\r\n    other-extensions:\r\n        BangPatterns\r\n        CPP\r\n        MagicHash\r\n        UnboxedTuples\r\n\r\n    exposed-modules:\r\n        Control.Seq\r\n        Control.Parallel\r\n        Control.Parallel.Strategies\r\n\r\n    build-depends:\r\n        array      >= 0.3 && < 0.6,\r\n        base       >= 4.3 && < 4.23,\r\n        containers >= 0.4 && < 0.9,\r\n        deepseq    >= 1.1 && < 1.6\r\n\r\n    ghc-options: -Wall\r\n\r\n    if impl(ghc >= 6.11)\r\n        -- To improve parallel performance:\r\n        ghc-options: -feager-blackholing\r\n";
  }