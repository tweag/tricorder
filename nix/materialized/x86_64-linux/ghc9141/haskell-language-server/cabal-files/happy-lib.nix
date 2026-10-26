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
      specVersion = "3.0";
      identifier = { name = "happy-lib"; version = "2.1.7"; };
      license = "BSD-2-Clause";
      copyright = "(c) Andy Gill, Simon Marlow";
      maintainer = "https://github.com/haskell/happy";
      author = "Andy Gill and Simon Marlow";
      homepage = "https://www.haskell.org/happy/";
      url = "";
      synopsis = "Happy is a parser generator for Haskell implemented using this library";
      description = "Happy is a parser generator for Haskell.  Given a grammar\nspecification in BNF, Happy generates Haskell code to parse the\ngrammar.  Happy works in a similar way to the @yacc@ tool for C.\n\nThis library provides the following functionality:\n\n  * Data type definitions for the Grammar AST type, capturing the information in .y-files (Happy.Grammar)\n\n  * A parser for happy grammar files (.y) to produce a Grammar (Happy.Frontend.*)\n\n  * Implementations of the text book algorithms that compute the LR action and\n    goto tables for the given 'Grammar' (Happy.Tabular.*)\n\n  * An LALR code generator to produce table-driven, deterministic parsing code\n    in Haskell (Happy.Backend.LALR.*)\n\n  * A (less maintained) GLR code generator to produce table-driven,\n    non-deterministic parsing code in Haskell, where ambiguous parses produce\n    multiple parse trees (Happy.Backend.GLR.*)";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."happy-lib".components.sublibs.grammar or (errorHandler.buildDepError "happy-lib:grammar"))
          (hsPkgs."happy-lib".components.sublibs.tabular or (errorHandler.buildDepError "happy-lib:tabular"))
          (hsPkgs."happy-lib".components.sublibs.frontend or (errorHandler.buildDepError "happy-lib:frontend"))
          (hsPkgs."happy-lib".components.sublibs.backend-lalr or (errorHandler.buildDepError "happy-lib:backend-lalr"))
          (hsPkgs."happy-lib".components.sublibs.backend-glr or (errorHandler.buildDepError "happy-lib:backend-glr"))
        ];
        buildable = true;
      };
      sublibs = {
        "grammar" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
          ];
          buildable = true;
        };
        "frontend" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."happy-lib".components.sublibs.grammar or (errorHandler.buildDepError "happy-lib:grammar"))
          ];
          buildable = true;
        };
        "tabular" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."happy-lib".components.sublibs.grammar or (errorHandler.buildDepError "happy-lib:grammar"))
          ];
          buildable = true;
        };
        "backend-lalr" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."happy-lib".components.sublibs.grammar or (errorHandler.buildDepError "happy-lib:grammar"))
            (hsPkgs."happy-lib".components.sublibs.tabular or (errorHandler.buildDepError "happy-lib:tabular"))
          ];
          buildable = true;
        };
        "backend-glr" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."happy-lib".components.sublibs.grammar or (errorHandler.buildDepError "happy-lib:grammar"))
            (hsPkgs."happy-lib".components.sublibs.tabular or (errorHandler.buildDepError "happy-lib:tabular"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/happy-lib-2.1.7.tar.gz";
      sha256 = "f625b2c4a3f2b5fafa3c560fa8757502cc8de83d9a84c2692fc943380900f269";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: happy-lib\nversion: 2.1.7\nlicense: BSD-2-Clause\ncopyright: (c) Andy Gill, Simon Marlow\nauthor: Andy Gill and Simon Marlow\nmaintainer: https://github.com/haskell/happy\nbug-reports: https://github.com/haskell/happy/issues\nstability: stable\nhomepage: https://www.haskell.org/happy/\nsynopsis: Happy is a parser generator for Haskell implemented using this library\ncategory: Development\nbuild-type: Simple\n\nDescription:\n  Happy is a parser generator for Haskell.  Given a grammar\n  specification in BNF, Happy generates Haskell code to parse the\n  grammar.  Happy works in a similar way to the @yacc@ tool for C.\n\n  This library provides the following functionality:\n\n    * Data type definitions for the Grammar AST type, capturing the information in .y-files (Happy.Grammar)\n\n    * A parser for happy grammar files (.y) to produce a Grammar (Happy.Frontend.*)\n\n    * Implementations of the text book algorithms that compute the LR action and\n      goto tables for the given 'Grammar' (Happy.Tabular.*)\n\n    * An LALR code generator to produce table-driven, deterministic parsing code\n      in Haskell (Happy.Backend.LALR.*)\n\n    * A (less maintained) GLR code generator to produce table-driven,\n      non-deterministic parsing code in Haskell, where ambiguous parses produce\n      multiple parse trees (Happy.Backend.GLR.*)\n\ntested-with:\n        GHC == 9.12.2\n        GHC == 9.10.2\n        GHC == 9.8.4\n        GHC == 9.6.7\n        GHC == 9.4.8\n        GHC == 9.2.8\n        GHC == 9.0.2\n        GHC == 8.10.7\n        GHC == 8.8.4\n        GHC == 8.6.5\n        GHC == 8.4.4\n        GHC == 8.2.2\n        GHC == 8.0.2\n\nextra-doc-files:\n        ChangeLog.md\n        README.md\n\nextra-source-files:\n        frontend/bootstrap.sh\n        frontend/boot-src/Parser.ly\n        frontend/boot-src/AttrGrammarParser.ly\n\ndata-dir: data\n\ndata-files:\n        HappyTemplate.hs\n        GLR_Base.hs\n        GLR_Lib.hs\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell/happy.git\n\ncommon common-stanza\n  default-language:    Haskell98\n  default-extensions:  CPP, MagicHash, FlexibleContexts, NamedFieldPuns, PatternGuards\n  ghc-options: -Wall -Wno-incomplete-uni-patterns\n\nlibrary grammar\n  import: common-stanza\n  hs-source-dirs:      grammar/src\n  exposed-modules:\n       Happy.Grammar\n       Happy.Grammar.ExpressionWithHole\n  build-depends:       base < 5, array\n\nlibrary frontend\n  import: common-stanza\n  hs-source-dirs:      frontend/src\n  exposed-modules:     Happy.Frontend,\n                       Happy.Frontend.AbsSyn,\n                       Happy.Frontend.Mangler,\n                       Happy.Frontend.PrettyGrammar\n  build-depends:       base < 5, array, transformers, containers, mtl, grammar\n  other-modules:\n        Happy.Frontend.ParseMonad\n        Happy.Frontend.ParseMonad.Class\n        Happy.Frontend.Mangler.Monad\n        Happy.Frontend.Parser\n        Happy.Frontend.Lexer\n        Happy.Frontend.ParamRules\n        Happy.Frontend.AttrGrammar\n        Happy.Frontend.AttrGrammar.Parser\n        Happy.Frontend.AttrGrammar.Mangler\n\nlibrary tabular\n  import: common-stanza\n  hs-source-dirs:      tabular/src\n  exposed-modules:     Happy.Tabular,\n                       Happy.Tabular.First,\n                       Happy.Tabular.Info,\n                       Happy.Tabular.LALR,\n                       Happy.Tabular.NameSet,\n  -- The following 3 lines constitute a workaround for cabal#10687, triggered by #328.\n  -- The setup in #328 triggers a clashing use of Paths_happy_lib between\n  -- `backend-lalr` and `backend-glr` in the presence of --libsubdir.\n  -- The workaround moves Paths_happy_lib into `tabular` where it can be shared.\n  -- However, in order to really refer to the Paths_happy_lib from `tabular`,\n  -- we have to reexport it under a different name, because otherwise we get\n  --\n  --    These modules are needed for compilation but not listed in your .cabal file's other-modules for ‘happy-lib-2.1.3-inplace-backend-lalr’ :\n  --        Paths_happy_libsuppress\n  --\n                       Paths_happy_lib\n  reexported-modules:  Paths_happy_lib as Happy.Paths\n  autogen-modules:     Paths_happy_lib\n  -- end of workaround. Delete the workaround and use the bash script posted at\n  -- https://github.com/haskell/happy/issues/328#issuecomment-2597598320\n  -- to test whether the workaround is still needed.\n  build-depends:       base < 5, array, containers, grammar\n\n\nlibrary backend-lalr\n  import: common-stanza\n  hs-source-dirs:      backend-lalr/src\n  exposed-modules:     Happy.Backend.LALR,\n                       Happy.Backend.LALR.ProduceCode\n  build-depends:       base < 5, array, grammar, tabular\n\nlibrary backend-glr\n  import: common-stanza\n  hs-source-dirs:      backend-glr/src\n  exposed-modules:     Happy.Backend.GLR,\n                       Happy.Backend.GLR.ProduceCode\n  build-depends:       base < 5, array, grammar, tabular\n\nlibrary\n  import: common-stanza\n  reexported-modules:  Happy.Grammar,\n                       Happy.Grammar.ExpressionWithHole,\n                       Happy.Frontend,\n                       Happy.Frontend.AbsSyn,\n                       Happy.Frontend.Mangler,\n                       Happy.Frontend.PrettyGrammar,\n                       Happy.Tabular,\n                       Happy.Tabular.First,\n                       Happy.Tabular.Info,\n                       Happy.Tabular.LALR,\n                       Happy.Tabular.NameSet,\n                       Happy.Backend.LALR,\n                       Happy.Backend.LALR.ProduceCode,\n                       Happy.Backend.GLR,\n                       Happy.Backend.GLR.ProduceCode\n  build-depends: base >= 4.9 && < 5,\n                 array >= 0.5,\n                 containers >= 0.4.2,\n                 transformers >= 0.5.6.2,\n                 mtl >= 2.2.1,\n                 -- NB: omit the `happy-lib:` prefix in happy-lib:grammar.\n                 -- Otherwise we unnecessarily break Cabal < 3.4\n                 grammar,\n                 tabular,\n                 frontend,\n                 backend-lalr,\n                 backend-glr\n";
  }