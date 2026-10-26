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
      identifier = { name = "vty-unix"; version = "0.5.0.0"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2023-2026 Jonathan Daugherty";
      maintainer = "cygnus@foobox.com";
      author = "Jonathan Daugherty";
      homepage = "";
      url = "";
      synopsis = "Unix backend for Vty";
      description = "This package provides Unix terminal support for Vty.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          (hsPkgs."terminfo" or (errorHandler.buildDepError "terminfo"))
          (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."parsec" or (errorHandler.buildDepError "parsec"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
          (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
          (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
        ];
        buildable = true;
      };
      exes = {
        "vty-unix-build-width-table" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
          ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "8.0")) (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"));
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/vty-unix-0.5.0.0.tar.gz";
      sha256 = "0326dce8f7ab4280306ce8ff852b12889a3031587b76def5a6ee8aa10143e07c";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\nname:               vty-unix\nversion:            0.5.0.0\nsynopsis:           Unix backend for Vty\ndescription:        This package provides Unix terminal support for Vty.\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nauthor:             Jonathan Daugherty\nmaintainer:         cygnus@foobox.com\ncategory:           User Interfaces\ncopyright:          (c) 2023-2026 Jonathan Daugherty\nbuild-type:         Simple\nextra-doc-files:    CHANGELOG.md\nextra-source-files: cbits/gwinsz.h\n                    cbits/gwinsz.c\n                    cbits/set_term_timing.c\n\nsource-repository head\n  type: git\n  location: https://github.com/jtdaugherty/vty-unix.git\n\ncommon warnings\n    ghc-options: -Wall\n\nlibrary\n    import:           warnings\n    hs-source-dirs:   src\n    default-language: Haskell2010\n    includes:         cbits/gwinsz.h\n    c-sources:        cbits/set_term_timing.c\n                      cbits/gwinsz.c\n    exposed-modules:  Data.Terminfo.Eval\n                      Data.Terminfo.Parse\n                      Graphics.Vty.Platform.Unix\n                      Graphics.Vty.Platform.Unix.Input\n                      Graphics.Vty.Platform.Unix.Input.Classify\n                      Graphics.Vty.Platform.Unix.Input.Classify.Parse\n                      Graphics.Vty.Platform.Unix.Input.Classify.Types\n                      Graphics.Vty.Platform.Unix.Input.Focus\n                      Graphics.Vty.Platform.Unix.Input.Loop\n                      Graphics.Vty.Platform.Unix.Input.Mouse\n                      Graphics.Vty.Platform.Unix.Input.Paste\n                      Graphics.Vty.Platform.Unix.Input.Terminfo\n                      Graphics.Vty.Platform.Unix.Input.Terminfo.ANSIVT\n                      Graphics.Vty.Platform.Unix.Output\n                      Graphics.Vty.Platform.Unix.Output.Color\n                      Graphics.Vty.Platform.Unix.Output.TerminfoBased\n                      Graphics.Vty.Platform.Unix.Output.XTermColor\n                      Graphics.Vty.Platform.Unix.Settings\n    build-depends:    base >= 4.8 && < 5,\n                      blaze-builder,\n                      bytestring,\n                      mtl >= 2.3,\n                      unix,\n                      terminfo,\n                      vty >= 6.6,\n                      deepseq,\n                      vector,\n                      parsec,\n                      containers,\n                      utf8-string,\n                      transformers,\n                      stm,\n                      microlens,\n                      microlens-mtl,\n                      microlens-th\n\nexecutable vty-unix-build-width-table\n  main-is:             BuildWidthTable.hs\n  hs-source-dirs:      tools\n  default-language:    Haskell2010\n  ghc-options:         -threaded -Wall\n\n  if !impl(ghc >= 8.0)\n    build-depends:     semigroups >= 0.16\n\n  build-depends:       base >= 4.8 && < 5,\n                       vty,\n                       ansi-terminal\n";
  }