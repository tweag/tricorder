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
    flags = { aeson = true; llvm = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "alfred-margaret"; version = "2.1.1.1"; };
      license = "BSD-3-Clause";
      copyright = "2020 Channable";
      maintainer = "Ruud van Asseldonk <ruud@channable.com>, Fabian Thorand <fabian@channable.com>";
      author = "The Alfred-Margaret authors";
      homepage = "https://github.com/channable/alfred-margaret";
      url = "";
      synopsis = "Fast Aho-Corasick string searching";
      description = "An efficient implementation of the Aho-Corasick\nstring searching algorithm.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ] ++ pkgs.lib.optional (flags.aeson) (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"));
        buildable = true;
      };
      exes = {
        "dump-automaton" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."alfred-margaret" or (errorHandler.buildDepError "alfred-margaret"))
          ];
          buildable = true;
        };
      };
      tests = {
        "test-suite" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."alfred-margaret" or (errorHandler.buildDepError "alfred-margaret"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-expectations" or (errorHandler.buildDepError "hspec-expectations"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "uvector-vs-tba" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."alfred-margaret" or (errorHandler.buildDepError "alfred-margaret"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
          ];
          buildable = true;
        };
        "bm" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."alfred-margaret" or (errorHandler.buildDepError "alfred-margaret"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/alfred-margaret-2.1.1.1.tar.gz";
      sha256 = "4fd79cf3ada571d1a127d40f8d25cf0cc6660f4132897fa293f2b13a7bba1bab";
    });
  }) // {
    package-description-override = "name:                alfred-margaret\nversion:             2.1.1.1\nsynopsis:            Fast Aho-Corasick string searching\ndescription:         An efficient implementation of the Aho-Corasick\n                     string searching algorithm.\nhomepage:            https://github.com/channable/alfred-margaret\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              The Alfred-Margaret authors\nmaintainer:          Ruud van Asseldonk <ruud@channable.com>, Fabian Thorand <fabian@channable.com>\ncopyright:           2020 Channable\ncategory:            Data, Text\nbuild-type:          Simple\nextra-source-files:  README.md\n                   , CHANGELOG.md\n                   , performance.png\ncabal-version:       >=1.10\ntested-with:\n                     -- Nixpkgs unstable (Updated 2022-04-14)\n                     GHC == 8.8.4\n                     -- Nixpkgs unstable (Updated 2022-04-14)\n                   , GHC == 8.10.7\n                     -- Nixpkgs unstable (Updated 2022-04-14)\n                   , GHC == 9.0.2\n                     -- Nixpkgs unstable (Updated 2024-09-05)\n                   , GHC == 9.6.6\n                     -- Nixpkgs unstable (Updated 2026-04-22)\n                   , GHC == 9.6.*\n                   , GHC == 9.8.*\n                   , GHC == 9.10.*\n                   , GHC == 9.12.*\n                   , GHC == 9.14.*\n\nsource-repository head\n  type:     git\n  location: https://github.com/channable/alfred-margaret\n\nFlag aeson\n    Description: Enable aeson support\n    Manual: False\n    Default: True\n\n-- Compile this package with LLVM, rather than with the default code generator.\n-- LLVM produces about 20% faster code.\nFlag llvm\n  Description: Compile with LLVM\n  Manual: True\n  -- Defaulting to false makes the package buildable by Hackage,\n  -- allowing the documentation to be generated for us.\n  Default: False\n\nlibrary\n  hs-source-dirs:      src\n  exposed-modules:     Data.Text.CaseSensitivity\n                     , Data.Text.Utf8\n                     , Data.Text.Utf8.Unlower\n                     , Data.Text.AhoCorasick.Automaton\n                     , Data.Text.AhoCorasick.Replacer\n                     , Data.Text.AhoCorasick.Searcher\n                     , Data.Text.AhoCorasick.Splitter\n                     , Data.Text.BoyerMoore.Automaton\n                     , Data.Text.BoyerMoore.Replacer\n                     , Data.Text.BoyerMoore.Searcher\n                     , Data.Text.BoyerMooreCI.Automaton\n                     , Data.Text.BoyerMooreCI.Replacer\n                     , Data.Text.BoyerMooreCI.Searcher\n  other-modules:       Data.Primitive.Extended\n  build-depends:\n      base             >= 4.7 && < 5\n    , containers       >= 0.6 && < 0.9\n    , deepseq          >= 1.4 && < 1.6\n    , hashable         >= 1.4.0.2 && < 1.6\n    , primitive        >= 0.6.4 && < 0.10\n    , text             >= 2.0 && < 2.2\n    , unordered-containers >= 0.2.9 && < 0.3\n    , vector           >= 0.12 && < 0.14\n  ghc-options:         -Wall -Wincomplete-record-updates -Wincomplete-uni-patterns -O2\n  default-language:    Haskell2010\n  if flag(aeson) {\n                       -- Even an older version of aeson is fine since\n                       -- we only use it for instances\n  build-depends:       aeson >= 1.4.2 && < 3\n  cpp-options:         -DHAS_AESON\n  }\n  if flag(llvm) {\n  ghc-options:         -fllvm -optlo=-passes=default<O3>\n  }\n\ntest-suite test-suite\n  type:                exitcode-stdio-1.0\n  main-is:             Main.hs\n  other-modules:       Data.Text.AhoCorasickSpec\n                     , Data.Text.BoyerMooreSpec\n                     , Data.Text.BoyerMooreCISpec\n                     , Data.Text.Utf8Spec\n                     , Data.Text.TestInstances\n  hs-source-dirs:      tests\n  ghc-options:         -Wall -Wincomplete-record-updates -Wno-orphans\n  build-depends:       base >= 4.7 && < 5\n                     , QuickCheck\n                     , alfred-margaret\n                     , deepseq\n                     , hspec\n                     , hspec-expectations\n                     , primitive\n                     , quickcheck-instances\n                     , text\n  default-language:    Haskell2010\n\nbenchmark uvector-vs-tba\n  type:                exitcode-stdio-1.0\n  main-is:             Main.hs\n  hs-source-dirs:      bench/uvector-vs-tba\n  ghc-options:         -Wall -Wincomplete-record-updates -Wno-orphans\n  build-depends:       base >= 4.7 && < 5\n                     , alfred-margaret\n                     , vector\n                     , deepseq\n                     , criterion\n  default-language:    Haskell2010\n\nbenchmark bm\n  type:                exitcode-stdio-1.0\n  main-is:             Main.hs\n  hs-source-dirs:      bench/bm\n  ghc-options:         -Wall -Wincomplete-record-updates -Wno-orphans\n  build-depends:       base >= 4.7 && < 5\n                     , alfred-margaret\n                     , deepseq\n                     , criterion\n                     , text\n  default-language:    Haskell2010\n\nexecutable dump-automaton\n  main-is: Main.hs\n  hs-source-dirs:\n    app/dump-automaton\n  build-depends:   base\n                 , alfred-margaret\n  default-language: Haskell2010\n";
  }