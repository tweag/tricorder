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
      identifier = { name = "happy"; version = "2.1.7"; };
      license = "BSD-2-Clause";
      copyright = "(c) Andy Gill, Simon Marlow";
      maintainer = "https://github.com/haskell/happy";
      author = "Andy Gill and Simon Marlow";
      homepage = "https://www.haskell.org/happy/";
      url = "";
      synopsis = "Happy is a parser generator for Haskell";
      description = "Happy is a parser generator for Haskell.  Given a grammar\nspecification in BNF, Happy generates Haskell code to parse the\ngrammar.  Happy works in a similar way to the @yacc@ tool for C.";
      buildType = "Simple";
    };
    components = {
      exes = {
        "happy" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."happy-lib" or (errorHandler.buildDepError "happy-lib"))
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
            (hsPkgs.pkgsBuildBuild.happy.components.exes.happy or (pkgs.pkgsBuildBuild.happy or (errorHandler.buildToolDepError "happy:happy")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/happy-2.1.7.tar.gz";
      sha256 = "9e390f0ab082d11d46598f6215b2f6e8253059721860f81082409091532d7e2a";
    });
  }) // {
    package-description-override = "name: happy\nversion: 2.1.7\nlicense: BSD2\nlicense-file: LICENSE\ncopyright: (c) Andy Gill, Simon Marlow\nauthor: Andy Gill and Simon Marlow\nmaintainer: https://github.com/haskell/happy\nbug-reports: https://github.com/haskell/happy/issues\nstability: stable\nhomepage: https://www.haskell.org/happy/\nsynopsis: Happy is a parser generator for Haskell\ncategory: Development\ncabal-version: >= 1.10\nbuild-type: Simple\n\nDescription:\n  Happy is a parser generator for Haskell.  Given a grammar\n  specification in BNF, Happy generates Haskell code to parse the\n  grammar.  Happy works in a similar way to the @yacc@ tool for C.\n\ntested-with:\n        GHC == 9.12.2\n        GHC == 9.10.2\n        GHC == 9.8.4\n        GHC == 9.6.7\n        GHC == 9.4.8\n        GHC == 9.2.8\n        GHC == 9.0.2\n        GHC == 8.10.7\n        GHC == 8.8.4\n        GHC == 8.6.5\n        GHC == 8.4.4\n        GHC == 8.2.2\n        GHC == 8.0.2\n\nextra-source-files:\n        ChangeLog.md\n        Makefile\n        README.md\n        examples/glr/nlp/Main.lhs\n        examples/glr/nlp/Makefile\n        examples/glr/nlp/README\n        examples/glr/nlp/English.y\n        examples/glr/nlp/Hugs.lhs\n        examples/glr/Makefile\n        examples/glr/Makefile.defs\n        examples/glr/expr-eval/Main.lhs\n        examples/glr/expr-eval/Makefile\n        examples/glr/expr-eval/Expr.y\n        examples/glr/expr-eval/README\n        examples/glr/expr-eval/Hugs.lhs\n        examples/glr/expr-tree/Main.lhs\n        examples/glr/expr-tree/Makefile\n        examples/glr/expr-tree/Expr.y\n        examples/glr/expr-tree/README\n        examples/glr/expr-tree/Tree.lhs\n        examples/glr/expr-tree/Hugs.lhs\n        examples/glr/highly-ambiguous/Main.lhs\n        examples/glr/highly-ambiguous/Makefile\n        examples/glr/highly-ambiguous/Expr.y\n        examples/glr/highly-ambiguous/README\n        examples/glr/highly-ambiguous/Hugs.lhs\n        examples/glr/hidden-leftrec/Main.lhs\n        examples/glr/hidden-leftrec/Makefile\n        examples/glr/hidden-leftrec/Expr.y\n        examples/glr/hidden-leftrec/README\n        examples/glr/hidden-leftrec/Hugs.lhs\n        examples/glr/expr-monad/Main.lhs\n        examples/glr/expr-monad/Makefile\n        examples/glr/expr-monad/Expr.y\n        examples/glr/expr-monad/README\n        examples/glr/expr-monad/Hugs.lhs\n        examples/glr/bio-eg/Main.lhs\n        examples/glr/bio-eg/Makefile\n        examples/glr/bio-eg/Bio.y\n        examples/glr/bio-eg/README\n        examples/glr/bio-eg/1-1200.dna\n        examples/glr/bio-eg/1-600.dna\n        examples/glr/common/DV_lhs\n        examples/glr/common/DaVinciTypes.hs\n        examples/glr/packing/Main.lhs\n        examples/glr/packing/Makefile\n        examples/glr/packing/Expr.y\n        examples/glr/packing/README\n        examples/glr/packing/Hugs.lhs\n        examples/PgnParser.ly\n        examples/MonadTest.ly\n        examples/igloo/ParserM.hs\n        examples/igloo/Makefile\n        examples/igloo/Parser.y\n        examples/igloo/Foo.hs\n        examples/igloo/README\n        examples/igloo/Lexer.x\n        examples/README\n        examples/Calc.ly\n        examples/DavesExample.ly\n        examples/ErrorTest.ly\n        examples/ErlParser.ly\n        examples/SimonsExample.ly\n        examples/LexerTest.ly\n        tests/AttrGrammar001.y\n        tests/AttrGrammar002.y\n        tests/Makefile\n        tests/Partial.ly\n        tests/Test.ly\n        tests/TestMulti.ly\n        tests/TestPrecedence.ly\n        tests/bogus-token.y\n        tests/bug001.ly\n        tests/bug002.y\n        tests/error001.stderr\n        tests/error001.stdout\n        tests/error001.y\n        tests/monad001.y\n        tests/monad002.ly\n        tests/monaderror.y\n        tests/Pragma.y\n        tests/precedence001.ly\n        tests/precedence002.y\n        tests/test_rules.y\n        tests/issue91.y\n        tests/issue93.y\n        tests/issue94.y\n        tests/issue95.y\n        tests/monaderror-explist.y\n        tests/typeclass_monad001.y\n        tests/typeclass_monad002.ly\n        tests/typeclass_monad_lexer.y\n        tests/rank2.y\n        tests/shift01.y\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell/happy.git\n\nexecutable happy\n  hs-source-dirs: app\n  main-is: Main.lhs\n\n  build-depends: base >= 4.9 && < 5,\n                 array,\n                 containers >= 0.4.2,\n                 mtl >= 2.2.1,\n                 happy-lib == 2.1.7\n\n  default-language: Haskell98\n  default-extensions: CPP, MagicHash, FlexibleContexts, NamedFieldPuns\n  ghc-options: -Wall -Wno-incomplete-uni-patterns\n  other-modules:\n        Paths_happy\n\ntest-suite tests\n  type: exitcode-stdio-1.0\n  main-is: test.hs\n  -- This line is important as it ensures that the local `exe:happy` component declared above is built before the test-suite component is invoked, as well as making sure that `happy` is made available on $PATH and `$happy_datadir` is set accordingly before invoking `test.hs`\n  build-tools: happy\n  ghc-options: -threaded\n\n  build-depends: base >= 4.9 && < 5, process < 1.7\n  default-language: Haskell98\n";
  }