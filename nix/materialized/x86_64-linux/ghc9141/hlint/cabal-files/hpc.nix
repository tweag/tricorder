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
      specVersion = "2.2";
      identifier = { name = "hpc"; version = "0.7.0.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "ghc-devs@haskell.org";
      author = "Andy Gill";
      homepage = "";
      url = "";
      synopsis = "Code Coverage Library for Haskell";
      description = "This package provides the code coverage library for Haskell.\n\nSee <https://www.haskell.org/haskellwiki/Haskell_program_coverage> for more\ninformation.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hpc-0.7.0.2.tar.gz";
      sha256 = "f081380becd2836416eaa7cca507a124e1207bb2f825427ddf9151ca8f76b69d";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\nname:         hpc\nversion:      0.7.0.2\n-- NOTE: Don't forget to update ./changelog.md\nlicense:      BSD-3-Clause\nlicense-file: LICENSE\nauthor:       Andy Gill\nmaintainer:   ghc-devs@haskell.org\nbug-reports:  https://gitlab.haskell.org/ghc/ghc/issues/new\ncategory:     Control\nsynopsis:     Code Coverage Library for Haskell\nbuild-type:   Simple\ndescription:\n    This package provides the code coverage library for Haskell.\n    .\n    See <https://www.haskell.org/haskellwiki/Haskell_program_coverage> for more\n    information.\n\nextra-doc-files:\n    changelog.md\n\nsource-repository head\n    type:     git\n    location: https://gitlab.haskell.org/ghc/packages/hpc.git\n\nLibrary\n    default-language: Haskell98\n\n    exposed-modules:\n        Trace.Hpc.Util\n        Trace.Hpc.Mix\n        Trace.Hpc.Tix\n        Trace.Hpc.Reflect\n\n    Build-Depends:\n        base       >= 4.12  && < 4.21,\n        containers >= 0.4.1 && < 0.8,\n        deepseq    >= 1.1   && < 1.6,\n        directory  >= 1.1   && < 1.4,\n        filepath   >= 1     && < 1.6,\n        time       >= 1.2   && < 1.15\n    ghc-options: -Wall\n";
  }