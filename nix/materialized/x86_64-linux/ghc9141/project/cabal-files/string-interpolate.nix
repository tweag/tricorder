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
    flags = {
      extended-benchmarks = false;
      text-builder = false;
      bytestring-builder = false;
    };
    package = {
      specVersion = "1.18";
      identifier = { name = "string-interpolate"; version = "0.3.4.0"; };
      license = "BSD-3-Clause";
      copyright = "2019-2026 William Yao";
      maintainer = "williamyaoh@gmail.com";
      author = "William Yao";
      homepage = "https://gitlab.com/williamyaoh/string-interpolate/blob/master/README.md";
      url = "";
      synopsis = "Haskell string/text/bytestring interpolation that just works";
      description = "Unicode-aware string interpolation that handles all textual types.\n\nSee the README at <https://gitlab.com/williamyaoh/string-interpolate/blob/master/README.md> for more info.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."split" or (errorHandler.buildDepError "split"))
          (hsPkgs."haskell-src-exts" or (errorHandler.buildDepError "haskell-src-exts"))
          (hsPkgs."haskell-src-meta" or (errorHandler.buildDepError "haskell-src-meta"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."text-conversions" or (errorHandler.buildDepError "text-conversions"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
        ];
        buildable = true;
      };
      tests = {
        "string-interpolate-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."string-interpolate" or (errorHandler.buildDepError "string-interpolate"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-core" or (errorHandler.buildDepError "hspec-core"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."quickcheck-text" or (errorHandler.buildDepError "quickcheck-text"))
            (hsPkgs."quickcheck-unicode" or (errorHandler.buildDepError "quickcheck-unicode"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "string-interpolate-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."string-interpolate" or (errorHandler.buildDepError "string-interpolate"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."formatting" or (errorHandler.buildDepError "formatting"))
            (hsPkgs."interpolate" or (errorHandler.buildDepError "interpolate"))
            (hsPkgs."neat-interpolation" or (errorHandler.buildDepError "neat-interpolation"))
          ] ++ pkgs.lib.optionals (flags.extended-benchmarks) [
            (hsPkgs."interpolatedstring-perl6" or (errorHandler.buildDepError "interpolatedstring-perl6"))
            (hsPkgs."Interpolation" or (errorHandler.buildDepError "Interpolation"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/string-interpolate-0.3.4.0.tar.gz";
      sha256 = "88838540b080308174d4fa51f20f15f46ed928bf1cf664f533f9bda5ae1e0b8e";
    });
  }) // {
    package-description-override = "cabal-version: 1.18\r\n\r\nname:           string-interpolate\r\nversion:        0.3.4.0\r\nx-revision: 7\r\nsynopsis:       Haskell string/text/bytestring interpolation that just works\r\ndescription:    Unicode-aware string interpolation that handles all textual types.\r\n                .\r\n                See the README at <https://gitlab.com/williamyaoh/string-interpolate/blob/master/README.md> for more info.\r\ncategory:       Data, Text\r\nhomepage:       https://gitlab.com/williamyaoh/string-interpolate/blob/master/README.md\r\nbug-reports:    https://gitlab.com/williamyaoh/string-interpolate/issues\r\nauthor:         William Yao\r\nmaintainer:     williamyaoh@gmail.com\r\ncopyright:      2019-2026 William Yao\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\nbuild-type:     Simple\r\nextra-doc-files:\r\n    README.md\r\n    CHANGELOG.md\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://www.gitlab.com/williamyaoh/string-interpolate.git\r\n\r\nflag extended-benchmarks\r\n     description: Enable benchmarks for Interpolation and interpolatedstring-perl6\r\n     manual: True\r\n     default: False\r\n\r\nflag text-builder\r\n     description:\r\n       Use Text Builders to construct Text outputs instead of the\r\n       Text type itself. If you're regularly constructing large (>50KB)\r\n       text objects, enabling this can speed up your code. Otherwise,\r\n       enabling this is likely to be a net slowdown.\r\n     manual: False\r\n     default: False\r\n\r\nflag bytestring-builder\r\n     description:\r\n       Use ByteString Builders to construct ByteString outputs instead of\r\n       the ByteString type itself. If you're regularly constructing large\r\n       (>50KB) bytestrings, enabling this can speed up your code. Otherwise,\r\n       enabling this is likely to be a net slowdown.\r\n     manual: False\r\n     default: False\r\n\r\nlibrary\r\n    exposed-modules:\r\n        Data.String.Interpolate\r\n        Data.String.Interpolate.Conversion\r\n        Data.String.Interpolate.Conversion.TextSink\r\n        Data.String.Interpolate.Conversion.ByteStringSink\r\n        Data.String.Interpolate.Types\r\n        Data.String.Interpolate.Parse\r\n    other-modules:\r\n        Data.String.Interpolate.Conversion.Classes\r\n        Data.String.Interpolate.Conversion.Encoding\r\n        Data.String.Interpolate.Lines\r\n        Data.String.Interpolate.Whitespace\r\n        Paths_string_interpolate\r\n    hs-source-dirs:\r\n        src/lib\r\n    ghc-options: -Wall -Wcompat -Wincomplete-record-updates\r\n                 -Wincomplete-uni-patterns -Wredundant-constraints\r\n                 -Wnoncanonical-monad-instances -fno-warn-name-shadowing\r\n    if flag(text-builder)\r\n      cpp-options: -DTEXT_BUILDER\r\n    if flag(bytestring-builder)\r\n      cpp-options: -DBYTESTRING_BUILDER\r\n    build-depends:\r\n        base >=4.11 && <5\r\n      , bytestring <0.13\r\n      , text <2.2\r\n      , split <0.3\r\n      , haskell-src-exts <1.25\r\n      , haskell-src-meta <0.9\r\n      , template-haskell <2.25\r\n      , text-conversions <0.4\r\n      , utf8-string <1.1\r\n    default-language: Haskell2010\r\n\r\ntest-suite string-interpolate-test\r\n    type: exitcode-stdio-1.0\r\n    main-is: spec.hs\r\n    other-modules:\r\n        Paths_string_interpolate\r\n    hs-source-dirs: test\r\n    ghc-options: -threaded -rtsopts -with-rtsopts=-N\r\n    build-depends:\r\n        base ==4.*\r\n      , string-interpolate\r\n      , QuickCheck <2.19\r\n      , bytestring <0.13\r\n      , text <2.2\r\n      , template-haskell <2.25\r\n      , hspec ==2.*\r\n      , hspec-core ==2.*\r\n      , quickcheck-instances <0.5\r\n      , quickcheck-text <0.2\r\n      , quickcheck-unicode <1.1\r\n      , unordered-containers <0.3\r\n    default-language: Haskell2010\r\n\r\nbenchmark string-interpolate-bench\r\n    type: exitcode-stdio-1.0\r\n    main-is: bench.hs\r\n    other-modules:\r\n        Paths_string_interpolate\r\n    hs-source-dirs: bench\r\n    build-depends:\r\n        base ==4.*\r\n      , string-interpolate\r\n      , QuickCheck <2.19\r\n      , bytestring <0.13\r\n      , text <2.2\r\n      , deepseq <1.6\r\n      , criterion <1.7\r\n      , formatting <7.3\r\n      , interpolate <0.3\r\n      , neat-interpolation <0.6\r\n    if flag(extended-benchmarks)\r\n      cpp-options: -DEXTENDED_BENCHMARKS\r\n      build-depends:\r\n          interpolatedstring-perl6 <1.1\r\n        , Interpolation <0.4\r\n    default-language: Haskell2010\r\n";
  }