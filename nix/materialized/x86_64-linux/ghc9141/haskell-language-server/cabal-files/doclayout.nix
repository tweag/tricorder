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
      identifier = { name = "doclayout"; version = "0.5.0.3"; };
      license = "BSD-3-Clause";
      copyright = "2016-24 John MacFarlane";
      maintainer = "jgm@berkeley.edu";
      author = "John MacFarlane";
      homepage = "https://github.com/jgm/doclayout";
      url = "";
      synopsis = "A prettyprinting library for laying out text documents.";
      description = "doclayout is a prettyprinting library for laying out\ntext documents, with several features not present\nin prettyprinting libraries designed for code.  It\nwas designed for use in pandoc.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."emojis" or (errorHandler.buildDepError "emojis"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."safe" or (errorHandler.buildDepError "safe"))
        ];
        buildable = true;
      };
      tests = {
        "doclayout-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."doclayout" or (errorHandler.buildDepError "doclayout"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-golden" or (errorHandler.buildDepError "tasty-golden"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."emojis" or (errorHandler.buildDepError "emojis"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "doclayout-bench" = {
          depends = [
            (hsPkgs."doclayout" or (errorHandler.buildDepError "doclayout"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."emojis" or (errorHandler.buildDepError "emojis"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/doclayout-0.5.0.3.tar.gz";
      sha256 = "52dfe6278173e4464f4ae6fbafdf18576336a8d8f2b5a51aac95d318537d48e9";
    });
  }) // {
    package-description-override = "name:                doclayout\nversion:             0.5.0.3\nsynopsis:            A prettyprinting library for laying out text documents.\ndescription:         doclayout is a prettyprinting library for laying out\n                     text documents, with several features not present\n                     in prettyprinting libraries designed for code.  It\n                     was designed for use in pandoc.\nhomepage:            https://github.com/jgm/doclayout\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              John MacFarlane\nmaintainer:          jgm@berkeley.edu\ncopyright:           2016-24 John MacFarlane\ncategory:            Text\nbuild-type:          Simple\nextra-source-files:  udhr/txt/*.txt,\n                     udhr/README,\n                     udhr/languages.txt,\n                     src/Text/unicodeWidth.inc\ndata-files:          README.md\nextra-source-files:  changelog.md\ncabal-version:       >=1.10\n\nlibrary\n  hs-source-dirs:      src\n  exposed-modules:     Text.DocLayout\n  other-modules:       Text.DocLayout.HasChars,\n                       Text.DocLayout.ANSIFont,\n                       Text.DocLayout.Attributed\n  build-depends:       base >= 4.12 && < 5,\n                       text,\n                       containers,\n                       emojis >=0.1.2,\n                       mtl,\n                       safe\n  default-language:    Haskell2010\n  ghc-options:         -Wall -fno-warn-unused-do-bind\n\ntest-suite doclayout-test\n  type:                exitcode-stdio-1.0\n  hs-source-dirs:      test\n  main-is:             test.hs\n  build-depends:       base,\n                       doclayout,\n                       mtl,\n                       tasty,\n                       tasty-golden,\n                       tasty-hunit,\n                       tasty-quickcheck,\n                       text,\n                       emojis >=0.1.2\n  ghc-options:         -threaded -rtsopts -with-rtsopts=-N\n  default-language:    Haskell2010\n\nbenchmark doclayout-bench\n  Type:            exitcode-stdio-1.0\n  Main-Is:         bench.hs\n  Hs-Source-Dirs:  bench\n  Build-Depends:   doclayout,\n                   base >= 4.8 && < 5,\n                   criterion >= 1.0,\n                   deepseq,\n                   text,\n                   emojis >= 0.1.2,\n                   mtl\n  Ghc-Options:   -rtsopts -Wall -fno-warn-unused-do-bind\n  Default-Language: Haskell2010\n\nsource-repository head\n  type:     git\n  location: https://github.com/jgm/doclayout\n";
  }