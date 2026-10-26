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
    flags = { integer-gmp = true; check-bounds = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "integer-logarithms"; version = "1.0.5"; };
      license = "MIT";
      copyright = "(c) 2011 Daniel Fischer, 2017-2020 Oleg Grenrus, Andrew Lelechenko";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Daniel Fischer";
      homepage = "https://github.com/haskellari/integer-logarithms";
      url = "";
      synopsis = "Integer logarithms.";
      description = "\"Math.NumberTheory.Logarithms\" and \"Math.NumberTheory.Powers.Integer\"\nfrom the arithmoi package.\n\nAlso provides \"GHC.Integer.Logarithms.Compat\" and\n\"Math.NumberTheory.Power.Natural\" modules, as well as some\nadditional functions in migrated modules.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "7.10")) (hsPkgs."nats" or (errorHandler.buildDepError "nats"))) ++ (if compiler.isGhc && compiler.version.ge "9.0"
          then [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
          ] ++ pkgs.lib.optional (!flags.integer-gmp) (hsPkgs."invalid-cabal-flag-settings" or (errorHandler.buildDepError "invalid-cabal-flag-settings"))
          else [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
          ] ++ (if flags.integer-gmp
            then [
              (hsPkgs."integer-gmp" or (errorHandler.buildDepError "integer-gmp"))
            ]
            else [
              (hsPkgs."integer-simple" or (errorHandler.buildDepError "integer-simple"))
            ]));
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."integer-logarithms" or (errorHandler.buildDepError "integer-logarithms"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."smallcheck" or (errorHandler.buildDepError "smallcheck"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty-smallcheck" or (errorHandler.buildDepError "tasty-smallcheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/integer-logarithms-1.0.5.tar.gz";
      sha256 = "66dff6f1f778fe1ec689139fe125cd4e6a95643734c651c891eafa2c50669459";
    });
  }) // {
    package-description-override = "name:               integer-logarithms\nversion:            1.0.5\ncabal-version:      >=1.10\nauthor:             Daniel Fischer\ncopyright:\n  (c) 2011 Daniel Fischer, 2017-2020 Oleg Grenrus, Andrew Lelechenko\n\nlicense:            MIT\nlicense-file:       LICENSE\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\nbuild-type:         Simple\nstability:          Provisional\nhomepage:           https://github.com/haskellari/integer-logarithms\nbug-reports:        https://github.com/haskellari/integer-logarithms/issues\nsynopsis:           Integer logarithms.\ndescription:\n  \"Math.NumberTheory.Logarithms\" and \"Math.NumberTheory.Powers.Integer\"\n  from the arithmoi package.\n  .\n  Also provides \"GHC.Integer.Logarithms.Compat\" and\n  \"Math.NumberTheory.Power.Natural\" modules, as well as some\n  additional functions in migrated modules.\n\ncategory:           Math, Algorithms, Number Theory\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.4\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.2\n   || ==9.12.2\n   || ==9.14.1\n\nextra-source-files:\n  changelog.md\n  readme.md\n\nflag integer-gmp\n  description: integer-gmp or integer-simple\n  default:     True\n  manual:      False\n\nflag check-bounds\n  description: Replace unsafe array operations with safe ones\n  default:     False\n  manual:      True\n\nlibrary\n  default-language: Haskell2010\n  hs-source-dirs:   src\n  build-depends:\n      array  >=0.5.3.0  && <0.6\n    , base   >=4.12.0.0 && <4.23\n\n  if !impl(ghc >=7.10)\n    build-depends: nats >=1.1.2 && <1.2\n\n  if impl(ghc >=9.0)\n    build-depends: base >=4.15\n\n    if !flag(integer-gmp)\n      build-depends: invalid-cabal-flag-settings <0\n\n  else\n    build-depends: base <4.15\n\n    if flag(integer-gmp)\n      build-depends: integer-gmp <1.1\n\n    else\n      build-depends: integer-simple\n\n  exposed-modules:\n    Math.NumberTheory.Logarithms\n    Math.NumberTheory.Powers.Integer\n    Math.NumberTheory.Powers.Natural\n\n  -- compat module\n  exposed-modules:  GHC.Integer.Logarithms.Compat\n  other-extensions:\n    BangPatterns\n    CPP\n    MagicHash\n\n  ghc-options:      -O2 -Wall\n\n  if flag(check-bounds)\n    cpp-options: -DCheckBounds\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskellari/integer-logarithms\n\ntest-suite spec\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   test-suite\n  ghc-options:      -Wall\n  main-is:          Test.hs\n  default-language: Haskell2010\n  other-extensions:\n    FlexibleContexts\n    FlexibleInstances\n    GeneralizedNewtypeDeriving\n    MultiParamTypeClasses\n    StandaloneDeriving\n\n  build-depends:\n      base\n    , integer-logarithms\n    , QuickCheck          >=2.16.0.0 && <2.18\n    , smallcheck          >=1.2      && <1.3\n    , tasty               >=1.4      && <1.6\n    , tasty-quickcheck    >=0.10     && <0.12\n    , tasty-smallcheck    >=0.8      && <0.9\n\n  other-modules:\n    Math.NumberTheory.LogarithmsTests\n    Math.NumberTheory.TestUtils\n    Orphans\n";
  }