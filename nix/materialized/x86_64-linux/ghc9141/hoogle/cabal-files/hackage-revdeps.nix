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
      identifier = { name = "hackage-revdeps"; version = "0.4.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "andrew.lelechenko@gmail.com";
      author = "Bodigrim";
      homepage = "";
      url = "";
      synopsis = "List Hackage reverse dependencies";
      description = "Command-line tool to list Hackage reverse dependencies.\nIt is different from how Hackage itself tracks them:\nthis tool accounts for all package components, including\ntests and benchmarks, and counts dependencies only\nacross the latest releases. The approach is roughly\nequivalent to what <https://packdeps.haskellers.com> does.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."alfred-margaret" or (errorHandler.buildDepError "alfred-margaret"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."Cabal" or (errorHandler.buildDepError "Cabal"))
          (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."tar" or (errorHandler.buildDepError "tar"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
        ];
        buildable = true;
      };
      exes = {
        "hackage-revdeps" = {
          depends = [
            (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."Cabal" or (errorHandler.buildDepError "Cabal"))
            (hsPkgs."cabal-install" or (errorHandler.buildDepError "cabal-install"))
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hackage-revdeps" or (errorHandler.buildDepError "hackage-revdeps"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ];
          buildable = true;
        };
        "hackage-revdeps-history" = {
          depends = [
            (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."Cabal" or (errorHandler.buildDepError "Cabal"))
            (hsPkgs."cabal-install" or (errorHandler.buildDepError "cabal-install"))
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."granite" or (errorHandler.buildDepError "granite"))
            (hsPkgs."hackage-revdeps" or (errorHandler.buildDepError "hackage-revdeps"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."terminal-size" or (errorHandler.buildDepError "terminal-size"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hackage-revdeps-0.4.1.tar.gz";
      sha256 = "4035ba65894bef374a2cdce1226020c53169185519415d5fdc7c1aabd25bce9a";
    });
  }) // {
    package-description-override = "cabal-version:   2.2\nname:            hackage-revdeps\nversion:         0.4.1\nlicense:         BSD-3-Clause\nlicense-file:    LICENSE\nmaintainer:      andrew.lelechenko@gmail.com\nauthor:          Bodigrim\ntested-with:\n    ghc ==9.14.1 ghc ==9.12.2 ghc ==9.10.3 ghc ==9.8.4 ghc ==9.6.7\n    ghc ==9.4.8\n\nsynopsis:        List Hackage reverse dependencies\ndescription:\n    Command-line tool to list Hackage reverse dependencies.\n    It is different from how Hackage itself tracks them:\n    this tool accounts for all package components, including\n    tests and benchmarks, and counts dependencies only\n    across the latest releases. The approach is roughly\n    equivalent to what <https://packdeps.haskellers.com> does.\n\ncategory:        Development\nbuild-type:      Simple\nextra-doc-files:\n    CHANGELOG.md\n    README.md\n\nsource-repository head\n    type:     git\n    location: https://github.com/Bodigrim/hackage-revdeps.git\n\nlibrary\n    exposed-modules:  Hackage.RevDeps\n    hs-source-dirs:   src\n    default-language: GHC2021\n    ghc-options:      -Wall -Wunused-packages\n    build-depends:\n        alfred-margaret >=2.0 && <2.2,\n        base >=4.17 && <5,\n        bytestring <0.13,\n        Cabal >=3.8 && <3.19,\n        Cabal-syntax >=3.8 && <3.19,\n        containers >=0.5.8 && <0.9,\n        filepath <1.6,\n        tar <0.8,\n        text >=2.0 && <2.2,\n        time <1.17,\n        zlib <0.8\n\nexecutable hackage-revdeps\n    main-is:          Main.hs\n    hs-source-dirs:   app\n    default-language: GHC2021\n    ghc-options:      -Wall -Wunused-packages -rtsopts\n    build-depends:\n        ansi-terminal >=0.11.3 && <1.2,\n        base,\n        Cabal,\n        cabal-install >=3.8 && <3.19,\n        Cabal-syntax,\n        containers,\n        filepath,\n        hackage-revdeps,\n        optparse-applicative >=0.16 && <0.20,\n        time <1.17\n\nexecutable hackage-revdeps-history\n    main-is:          History.hs\n    hs-source-dirs:   app\n    default-language: GHC2021\n    ghc-options:      -Wall -Wunused-packages -rtsopts\n    build-depends:\n        ansi-terminal >=0.11.3 && <1.2,\n        base,\n        Cabal,\n        cabal-install >=3.8 && <3.19,\n        Cabal-syntax,\n        containers,\n        filepath,\n        granite >=0.7 && <0.8,\n        hackage-revdeps,\n        optparse-applicative >=0.16 && <0.20,\n        terminal-size >=0.2 && <0.4,\n        text <2.2,\n        time <1.17\n";
  }