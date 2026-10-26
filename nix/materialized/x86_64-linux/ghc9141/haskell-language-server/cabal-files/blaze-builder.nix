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
      specVersion = "1.18";
      identifier = { name = "blaze-builder"; version = "0.4.4.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2010-2014 Simon Meier\n(c) 2010 Jasper Van der Jeugt\n(c) 2013-2015 Leon P Smith";
      maintainer = "https://github.com/blaze-builder";
      author = "Jasper Van der Jeugt, Simon Meier, Leon P Smith";
      homepage = "https://github.com/blaze-builder/blaze-builder";
      url = "";
      synopsis = "Efficient buffered output.";
      description = "This library allows to efficiently serialize Haskell values to lazy bytestrings\nwith a large average chunk size. The large average chunk size allows to make\ngood use of cache prefetching in later processing steps (e.g. compression) and\nreduces the system call overhead when writing the resulting lazy bytestring to a\nfile or sending it over the network.\n\nThis library was inspired by the module Data.Binary.Builder provided by the\nbinary package. It was originally developed with the specific needs of the\nblaze-html package in mind. Since then it has been restructured to serve as a\ndrop-in replacement for Data.Binary.Builder, which it improves upon both in\nspeed as well as expressivity.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."test-framework" or (errorHandler.buildDepError "test-framework"))
            (hsPkgs."test-framework-hunit" or (errorHandler.buildDepError "test-framework-hunit"))
            (hsPkgs."test-framework-quickcheck2" or (errorHandler.buildDepError "test-framework-quickcheck2"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/blaze-builder-0.4.4.1.tar.gz";
      sha256 = "971d360428ac97af9a4e55e4f2c23649f6cedc0ce5d6e94d520e663f33ea5113";
    });
  }) // {
    package-description-override = "Cabal-version:       1.18\nName:                blaze-builder\nVersion:             0.4.4.1\nSynopsis:            Efficient buffered output.\n\nDescription:\n    This library allows to efficiently serialize Haskell values to lazy bytestrings\n    with a large average chunk size. The large average chunk size allows to make\n    good use of cache prefetching in later processing steps (e.g. compression) and\n    reduces the system call overhead when writing the resulting lazy bytestring to a\n    file or sending it over the network.\n    .\n    This library was inspired by the module Data.Binary.Builder provided by the\n    binary package. It was originally developed with the specific needs of the\n    blaze-html package in mind. Since then it has been restructured to serve as a\n    drop-in replacement for Data.Binary.Builder, which it improves upon both in\n    speed as well as expressivity.\n\nAuthor:              Jasper Van der Jeugt, Simon Meier, Leon P Smith\nCopyright:           (c) 2010-2014 Simon Meier\n                     (c) 2010 Jasper Van der Jeugt\n                     (c) 2013-2015 Leon P Smith\nMaintainer:          https://github.com/blaze-builder\n\nLicense:             BSD3\nLicense-file:        LICENSE\n\nHomepage:            https://github.com/blaze-builder/blaze-builder\nBug-Reports:         https://github.com/blaze-builder/blaze-builder/issues\nStability:           Stable\n\nCategory:            Data\nBuild-type:          Simple\n\nTested-with:\n  GHC == 9.14.1\n  GHC == 9.12.2\n  GHC == 9.10.2\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nExtra-doc-files:\n                     README.markdown\n                     CHANGELOG.md\n\nExtra-source-files:\n                     Makefile\n\n                     benchmarks/*.hs\n                     benchmarks/Throughput/*.hs\n                     benchmarks/Throughput/*.h\n                     benchmarks/Throughput/*.c\n\n                     tests/*.hs\n\nSource-repository head\n  Type: git\n  Location: https://github.com/blaze-builder/blaze-builder.git\n\nLibrary\n  default-language:  Haskell98\n\n  exposed-modules:   Blaze.ByteString.Builder\n                     Blaze.ByteString.Builder.Int\n                     Blaze.ByteString.Builder.Word\n                     Blaze.ByteString.Builder.ByteString\n                     Blaze.ByteString.Builder.Char.Utf8\n                     Blaze.ByteString.Builder.Char8\n                     Blaze.ByteString.Builder.Html.Utf8\n                     Blaze.ByteString.Builder.Html.Word\n                     Blaze.ByteString.Builder.HTTP\n                     Blaze.ByteString.Builder.Compat.Write\n\n                     Blaze.ByteString.Builder.Internal.Write\n\n  build-depends:\n      base       >= 4.9    && < 5\n    , bytestring >= 0.10.4 && < 1\n    , text       >= 1.1.2  && < 3\n\n  ghc-options:\n    -Wall\n    -Wcompat\n\ntest-suite test\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   tests\n  main-is:          Tests.hs\n  default-language: Haskell98\n  ghc-options:\n    -Wall\n    -Wno-orphans\n    -Wcompat\n\n  build-depends: base\n               , blaze-builder\n               , bytestring\n               , HUnit\n               , QuickCheck\n               , test-framework\n               , test-framework-hunit\n               , test-framework-quickcheck2\n               , text\n               , utf8-string\n";
  }