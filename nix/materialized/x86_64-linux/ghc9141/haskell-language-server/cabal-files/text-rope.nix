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
    flags = { debug = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "text-rope"; version = "0.3"; };
      license = "BSD-3-Clause";
      copyright = "2021-2022 Andrew Lelechenko, 2024 Olle Fredriksson";
      maintainer = "Andrew Lelechenko <andrew.lelechenko@gmail.com>";
      author = "Andrew Lelechenko <andrew.lelechenko@gmail.com>, Olle Fredriksson <fredriksson.olle@gmail.com>";
      homepage = "https://github.com/Bodigrim/text-rope";
      url = "";
      synopsis = "Text lines and ropes";
      description = "A wrapper around `Text` for fast line/column navigation and logarithmic concatenation.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "text-rope-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "text-rope-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/text-rope-0.3.tar.gz";
      sha256 = "bfafee27b63885b19eb58120cc97771d127aa8ba9f141f03044d1ac476699337";
    });
  }) // {
    package-description-override = "name: text-rope\nversion: 0.3\ncabal-version: >=1.10\nbuild-type: Simple\nlicense: BSD3\nlicense-file: LICENSE\ncopyright: 2021-2022 Andrew Lelechenko, 2024 Olle Fredriksson\nmaintainer: Andrew Lelechenko <andrew.lelechenko@gmail.com>\nhomepage: https://github.com/Bodigrim/text-rope\ncategory: Text\nsynopsis: Text lines and ropes\ndescription:\n  A wrapper around `Text` for fast line/column navigation and logarithmic concatenation.\nauthor: Andrew Lelechenko <andrew.lelechenko@gmail.com>, Olle Fredriksson <fredriksson.olle@gmail.com>\nextra-source-files:\n  changelog.md\n  README.md\ndata-files:\n  bench/bench.txt\n  bench/bench-utf8.txt\n\ntested-with: GHC == 9.10.1, GHC == 9.8.2, GHC == 9.6.5, GHC == 9.4.8, GHC == 9.2.8, GHC==9.0.2, GHC==8.10.7, GHC==8.8.4, GHC==8.6.5, GHC==8.4.4, GHC==8.2.2, GHC==8.0.2\n\nsource-repository head\n  type: git\n  location: git://github.com/Bodigrim/text-rope.git\n\nflag debug\n  default: False\n  manual: True\n  description: Build library with sanity checks enabled.\n\nlibrary\n  exposed-modules:\n    Data.Text.Lines\n    Data.Text.Rope\n    Data.Text.Utf8.Lines\n    Data.Text.Utf16.Lines\n    Data.Text.Utf8.Rope\n    Data.Text.Utf16.Rope\n    Data.Text.Utf16.Rope.Mixed\n    Data.Text.Mixed.Rope\n  other-modules:\n    Data.Text.Lines.Internal\n  build-depends:\n    base >=4.9 && <5,\n    deepseq < 1.6,\n    text >= 1.2.3 && < 2.2,\n    vector >=0.11 && < 0.14\n  default-language: Haskell2010\n  hs-source-dirs: src\n  ghc-options: -O2 -Wall -Wcompat -fexpose-all-unfoldings\n  if flag(debug)\n    cpp-options: -DDEBUG\n    if impl(ghc >= 9.2.2)\n      ghc-options: -fcheck-prim-bounds\n  c-sources:\n    cbits/utils.c\n\ntest-suite text-rope-tests\n  type: exitcode-stdio-1.0\n  main-is: Main.hs\n  other-modules:\n    CharLines\n    CharRope\n    MixedRope\n    Utf8Lines\n    Utf8Rope\n    Utf16Lines\n    Utf16Rope\n    Utils\n  build-depends:\n    base,\n    text-rope,\n    tasty,\n    tasty-quickcheck >= 0.8.1,\n    text\n  default-language: Haskell2010\n  hs-source-dirs: test\n  ghc-options: -Wall -threaded -rtsopts -Wcompat \"-with-rtsopts -N\"\n\nbenchmark text-rope-bench\n  type: exitcode-stdio-1.0\n  main-is: Main.hs\n  other-modules:\n    Paths_text_rope\n  hs-source-dirs: bench\n  ghc-options: -O2 -rtsopts\n  build-depends:\n    base,\n    -- core-text,\n    text-rope,\n    random,\n    -- yi-rope,\n    -- rope-utf16-splay,\n    tasty >= 1.2,\n    tasty-bench >= 0.3,\n    text\n  default-language: Haskell2010\n";
  }