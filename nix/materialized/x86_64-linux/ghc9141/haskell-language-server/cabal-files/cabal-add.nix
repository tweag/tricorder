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
      identifier = { name = "cabal-add"; version = "0.2.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "andrew.lelechenko@gmail.com";
      author = "Bodigrim";
      homepage = "";
      url = "";
      synopsis = "Extend Cabal build-depends from the command line";
      description = "Extend Cabal @build-depends@ from the command line.\nIt works on any sectioned Cabal file,\nsupports stanzas and conditional blocks,\nand preserves original formatting.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."Cabal" or (errorHandler.buildDepError "Cabal"))
          (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
        ];
        buildable = true;
      };
      exes = {
        "cabal-add" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."cabal-add" or (errorHandler.buildDepError "cabal-add"))
            (hsPkgs."Cabal" or (errorHandler.buildDepError "Cabal"))
            (hsPkgs."cabal-install" or (errorHandler.buildDepError "cabal-install"))
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          ];
          buildable = true;
        };
      };
      tests = {
        "cabal-add-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."Diff" or (errorHandler.buildDepError "Diff"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."file-io" or (errorHandler.buildDepError "file-io"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."temporary-ospath" or (errorHandler.buildDepError "temporary-ospath"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.cabal-add.components.exes.cabal-add or (pkgs.pkgsBuildBuild.cabal-add or (errorHandler.buildToolDepError "cabal-add:cabal-add")))
          ];
          buildable = true;
        };
        "cabal-add-unit-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."Cabal" or (errorHandler.buildDepError "Cabal"))
            (hsPkgs."cabal-add" or (errorHandler.buildDepError "cabal-add"))
            (hsPkgs."Diff" or (errorHandler.buildDepError "Diff"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/cabal-add-0.2.1.tar.gz";
      sha256 = "3c20f936f5a80c2ea6261b81a5b4070bd90b0531672d247f1dfd38aadf0ff894";
    });
  }) // {
    package-description-override = "cabal-version:   3.0\nname:            cabal-add\nversion:         0.2.1\nlicense:         BSD-3-Clause\nlicense-file:    LICENSE\nmaintainer:      andrew.lelechenko@gmail.com\nauthor:          Bodigrim\ntested-with:\n    ghc ==9.14.1 ghc ==9.12.2 ghc ==9.10.3 ghc ==9.8.4 ghc ==9.6.7\n    ghc ==9.4.8\n\nsynopsis:        Extend Cabal build-depends from the command line\ndescription:\n    Extend Cabal @build-depends@ from the command line.\n    It works on any sectioned Cabal file,\n    supports stanzas and conditional blocks,\n    and preserves original formatting.\n\ncategory:        Development\nbuild-type:      Simple\nextra-doc-files:\n    README.md\n    CHANGELOG.md\n\nsource-repository head\n    type:     git\n    location: https://github.com/Bodigrim/cabal-add.git\n\nlibrary\n    exposed-modules:\n        Distribution.Client.Add\n        Distribution.Client.Rename\n\n    hs-source-dirs:   src\n    other-modules:    Distribution.Client.Common\n    default-language: GHC2021\n    ghc-options:      -Wall\n    build-depends:\n        base <5,\n        bytestring <0.13,\n        Cabal >=3.8 && <3.19,\n        Cabal-syntax >=3.8 && <3.19,\n        containers <0.9,\n        mtl <2.4\n\nexecutable cabal-add\n    main-is:          Main.hs\n    hs-source-dirs:   app\n    default-language: GHC2021\n    ghc-options:      -Wall\n    build-depends:\n        base <5,\n        bytestring <0.13,\n        cabal-add,\n        Cabal,\n        cabal-install >=3.12 && <3.19,\n        Cabal-syntax,\n        directory <1.4,\n        filepath <1.6,\n        optparse-applicative >=0.16 && <0.20\n\ntest-suite cabal-add-tests\n    type:               exitcode-stdio-1.0\n    main-is:            Main.hs\n    build-tool-depends: cabal-add:cabal-add\n    hs-source-dirs:     tests\n    default-language:   GHC2021\n    other-extensions:   MultilineStrings\n    ghc-options:        -Wall\n    build-depends:\n        base <5,\n        bytestring >=0.11.2,\n        Diff >=0.4,\n        directory,\n        file-io,\n        filepath,\n        process,\n        tasty,\n        temporary-ospath <1.4\n\ntest-suite cabal-add-unit-tests\n    type:             exitcode-stdio-1.0\n    main-is:          UnitTests.hs\n    hs-source-dirs:   tests/\n    default-language: GHC2021\n    other-extensions: MultilineStrings\n    ghc-options:      -Wall\n    build-depends:\n        base <5,\n        bytestring,\n        Cabal,\n        cabal-add,\n        Diff >=0.4,\n        tasty\n";
  }