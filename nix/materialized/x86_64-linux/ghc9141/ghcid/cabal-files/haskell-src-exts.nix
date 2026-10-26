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
      identifier = { name = "haskell-src-exts"; version = "1.24.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Dan Burton <danburton.email@gmail.com>";
      author = "Niklas Broberg";
      homepage = "https://github.com/haskell-suite/haskell-src-exts";
      url = "";
      synopsis = "Manipulating Haskell source: abstract syntax, lexer, parser, and pretty-printer";
      description = "Haskell-Source with Extensions (HSE, haskell-src-exts)\nis a standalone parser for Haskell. In addition to\nstandard Haskell, all extensions implemented in GHC are supported.\n\nApart from these standard extensions,\nit also handles regular patterns as per the HaRP extension\nas well as HSX-style embedded XML syntax.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
        ] ++ pkgs.lib.optionals (!(compiler.isGhc && compiler.version.ge "8.0")) [
          (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))
          (hsPkgs."fail" or (errorHandler.buildDepError "fail"))
        ];
        build-tools = [
          (hsPkgs.pkgsBuildBuild.happy.components.exes.happy or (pkgs.pkgsBuildBuild.happy or (errorHandler.buildToolDepError "happy:happy")))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."haskell-src-exts" or (errorHandler.buildDepError "haskell-src-exts"))
            (hsPkgs."smallcheck" or (errorHandler.buildDepError "smallcheck"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-smallcheck" or (errorHandler.buildDepError "tasty-smallcheck"))
            (hsPkgs."tasty-golden" or (errorHandler.buildDepError "tasty-golden"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."pretty-show" or (errorHandler.buildDepError "pretty-show"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/haskell-src-exts-1.24.0.tar.gz";
      sha256 = "7e097074efb235115a7af03b14d9f99be8e8f8213a092c1e66870387b86c42bd";
    });
  }) // {
    package-description-override = "Name:                   haskell-src-exts\nVersion:                1.24.0\nLicense:                BSD3\nLicense-File:           LICENSE\nBuild-Type:             Simple\nAuthor:                 Niklas Broberg\nMaintainer:             Dan Burton <danburton.email@gmail.com>\nCategory:               Language\nSynopsis:               Manipulating Haskell source: abstract syntax, lexer, parser, and pretty-printer\nDescription:            Haskell-Source with Extensions (HSE, haskell-src-exts)\n                        is a standalone parser for Haskell. In addition to\n                        standard Haskell, all extensions implemented in GHC are supported.\n                        .\n                        Apart from these standard extensions,\n                        it also handles regular patterns as per the HaRP extension\n                        as well as HSX-style embedded XML syntax.\nHomepage:               https://github.com/haskell-suite/haskell-src-exts\nBug-Reports:            https://github.com/haskell-suite/haskell-src-exts/issues\nStability:              Stable\nCabal-Version:          >= 1.10\nTested-With:            GHC == 9.14.1\n\nExtra-Source-Files:\n                        README.md\n                        CHANGELOG\n                        RELEASENOTES-1.17.0\n                        tests/examples/*.hs\n                        tests/examples/*.lhs\n                        tests/examples/*.hs.parser.golden\n                        tests/examples/*.lhs.parser.golden\n                        tests/examples/*.hs.exactprinter.golden\n                        tests/examples/*.lhs.exactprinter.golden\n                        tests/examples/*.hs.prettyprinter.golden\n                        tests/examples/*.lhs.prettyprinter.golden\n                        tests/examples/*.hs.prettyparser.golden\n                        tests/examples/*.lhs.prettyparser.golden\n                        tests/Runner.hs\n                        tests/Extensions.hs\n\nLibrary\n  Default-language:     Haskell98\n  Build-Tools:          happy >= 1.19\n  Build-Depends:        array >= 0.1 && < 0.6,\n                        pretty >= 1.0 && < 1.2,\n                        base >= 4.5 && < 5,\n                        -- this is needed to access GHC.Generics on GHC 7.4\n                        ghc-prim < 0.14\n  -- this is needed to access Data.Semigroup and Control.Monad.Fail on GHCs\n  -- before 8.0\n  if !impl(ghc >= 8.0)\n    Build-Depends:\n                        semigroups >= 0.18.3 && < 0.21,\n                        fail == 4.9.*\n\n  Exposed-modules:      Language.Haskell.Exts,\n                        Language.Haskell.Exts.Lexer,\n                        Language.Haskell.Exts.Pretty,\n                        Language.Haskell.Exts.Extension,\n                        Language.Haskell.Exts.Build,\n                        Language.Haskell.Exts.SrcLoc,\n\n                        Language.Haskell.Exts.Syntax,\n                        Language.Haskell.Exts.Fixity,\n                        Language.Haskell.Exts.ExactPrint,\n                        Language.Haskell.Exts.Parser,\n                        Language.Haskell.Exts.Comments\n\n  Other-modules:        Language.Haskell.Exts.ExtScheme,\n                        Language.Haskell.Exts.ParseMonad,\n                        Language.Haskell.Exts.ParseSyntax,\n                        Language.Haskell.Exts.InternalLexer,\n                        Language.Haskell.Exts.ParseUtils,\n                        Language.Haskell.Exts.InternalParser\n                        Language.Preprocessor.Unlit\n  Hs-source-dirs:       src\n  Ghc-options:          -Wall\n\nSource-Repository head\n        Type:           git\n        Location:       https://github.com/haskell-suite/haskell-src-exts.git\n\nTest-Suite test\n  type:                exitcode-stdio-1.0\n  hs-source-dirs:      tests\n  main-is:             Runner.hs\n  other-modules:       Extensions\n  GHC-Options:         -threaded -Wall\n  Default-language:    Haskell2010\n  Build-depends:       base,\n                       mtl,\n                       containers,\n                       haskell-src-exts,\n                       smallcheck >= 1.0,\n                       tasty >= 0.3,\n                       tasty-smallcheck,\n                       tasty-golden >= 2.2.2,\n                       filepath,\n                       directory,\n                       pretty-show >= 1.6.16\n";
  }