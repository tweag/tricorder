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
      identifier = { name = "alex"; version = "3.5.4.2"; };
      license = "BSD-3-Clause";
      copyright = "(c) Chis Dornan, Simon Marlow";
      maintainer = "https://github.com/haskell/alex";
      author = "Chris Dornan and Simon Marlow";
      homepage = "https://github.com/haskell/alex";
      url = "";
      synopsis = "Alex is a tool for generating lexical analysers in Haskell";
      description = "Alex is a tool for generating lexical analysers in Haskell.\nIt takes a description of tokens based on regular\nexpressions and generates a Haskell module containing code\nfor scanning text efficiently. It is similar to the tool\nlex or flex for C/C++.";
      buildType = "Simple";
    };
    components = {
      exes = {
        "alex" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          ];
          buildable = true;
        };
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.alex.components.exes.alex or (pkgs.pkgsBuildBuild.alex or (errorHandler.buildToolDepError "alex:alex")))
          ];
          buildable = true;
        };
        "tests-debug" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.alex.components.exes.alex or (pkgs.pkgsBuildBuild.alex or (errorHandler.buildToolDepError "alex:alex")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/alex-3.5.4.2.tar.gz";
      sha256 = "df481dc960e2c59a30395f7335031fd4ef8773b8a42894a4f2320e00ff474418";
    });
  }) // {
    package-description-override = "cabal-version: 1.18\nname: alex\nversion: 3.5.4.2\n-- Remember to update the changelog\n-- and to build dist tarball using `make sdist`!\nlicense: BSD3\nlicense-file: LICENSE\ncopyright: (c) Chis Dornan, Simon Marlow\nauthor: Chris Dornan and Simon Marlow\nmaintainer: https://github.com/haskell/alex\nbug-reports: https://github.com/haskell/alex/issues\nstability: stable\nhomepage: https://github.com/haskell/alex\nsynopsis: Alex is a tool for generating lexical analysers in Haskell\ndescription:\n  Alex is a tool for generating lexical analysers in Haskell.\n  It takes a description of tokens based on regular\n  expressions and generates a Haskell module containing code\n  for scanning text efficiently. It is similar to the tool\n  lex or flex for C/C++.\n\ncategory: Development\nbuild-type: Simple\n\ntested-with:\n        GHC == 9.14.1\n        GHC == 9.12.2\n        GHC == 9.10.3\n        GHC == 9.8.4\n        GHC == 9.6.7\n        GHC == 9.4.8\n        GHC == 9.2.8\n        GHC == 9.0.2\n        GHC == 8.10.7\n        GHC == 8.8.4\n        GHC == 8.6.5\n        GHC == 8.4.4\n        GHC == 8.2.2\n        GHC == 8.0.2\n\ndata-dir: data/\n\ndata-files:\n        AlexTemplate.hs\n        AlexWrappers.hs\n\nextra-doc-files:\n        CHANGELOG.md\n        README.md\n\nextra-source-files:\n        examples/Makefile\n        examples/Tokens.x\n        examples/Tokens_gscan.x\n        examples/Tokens_posn.x\n        examples/examples.x\n        examples/haskell.x\n        examples/lit.x\n        examples/pp.x\n        examples/state.x\n        examples/tiny.y\n        examples/words.x\n        examples/words_monad.x\n        examples/words_posn.x\n        src/Parser.y.boot\n        src/Scan.x.boot\n        src/ghc_hooks.c\n        tests/Makefile\n        tests/simple.x\n        tests/null.x\n        tests/tokens.x\n        tests/tokens_gscan.x\n        tests/tokens_posn.x\n        tests/tokens_bytestring.x\n        tests/tokens_posn_bytestring.x\n        tests/tokens_scan_user.x\n        tests/tokens_strict_bytestring.x\n        tests/tokens_monad_bytestring.x\n        tests/tokens_monadUserState_bytestring.x\n        tests/tokens_bytestring_unicode.x\n        tests/basic_typeclass.x\n        tests/basic_typeclass_bytestring.x\n        tests/default_typeclass.x\n        tests/gscan_typeclass.x\n        tests/posn_typeclass.x\n        tests/monad_typeclass.x\n        tests/monadic_expr.x\n        tests/monad_typeclass_bytestring.x\n        tests/monadUserState_typeclass.x\n        tests/monadUserState_typeclass_bytestring.x\n        tests/posn_typeclass_bytestring.x\n        tests/strict_typeclass.x\n        tests/unicode.x\n        tests/issue_71.x\n        tests/issue_119.x\n        tests/issue_141.x\n        tests/issue_197.x\n        tests/issue_262.x\n        tests/issue_269_part1.x\n        tests/issue_269_part2.x\n        tests/strict_text_typeclass.x\n        tests/posn_typeclass_strict_text.x\n        tests/tokens_monadUserState_strict_text.x\n\nsource-repository head\n    type:     git\n    location: https://github.com/haskell/alex.git\n\nexecutable alex\n  hs-source-dirs: src\n  main-is: Main.hs\n\n  build-depends:\n      base >= 4.9 && < 5\n        -- Data.List.NonEmpty enters `base` at 4.9\n    , array\n    , containers\n    , directory\n\n  default-language:\n    Haskell2010\n  default-extensions:\n    DeriveFunctor\n    PatternSynonyms\n    ScopedTypeVariables\n    TupleSections\n  other-extensions:\n    CPP\n    FlexibleContexts\n    MagicHash\n    NondecreasingIndentation\n    OverloadedLists\n  ghc-options: -Wall -Wcompat -rtsopts\n\n  other-modules:\n    AbsSyn\n    CharSet\n    DFA\n    DFAMin\n    DFS\n    Info\n    NFA\n    Output\n    Paths_alex\n    Parser\n    ParseMonad\n    Scan\n    Util\n    UTF8\n    Data.Ranged\n    Data.Ranged.Boundaries\n    Data.Ranged.RangedSet\n    Data.Ranged.Ranges\n\ntest-suite tests\n  type: exitcode-stdio-1.0\n  main-is: test.hs\n  -- This line is important as it ensures that the local `exe:alex` component declared above is built before the test-suite component is invoked, as well as making sure that `alex` is made available on $PATH and `$alex_datadir` is set accordingly before invoking `test.hs`\n  build-tools: alex\n\n  default-language: Haskell2010\n\n  build-depends:\n      base < 5\n    , process\n\ntest-suite tests-debug\n  type: exitcode-stdio-1.0\n  main-is: test-debug.hs\n  -- This line is important as it ensures that the local `exe:alex` component declared above is built before the test-suite component is invoked, as well as making sure that `alex` is made available on $PATH and `$alex_datadir` is set accordingly before invoking `test.hs`\n  build-tools: alex\n\n  default-language: Haskell2010\n\n  build-depends:\n      base < 5\n    , process\n";
  }