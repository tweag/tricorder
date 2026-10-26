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
    flags = { optimised-mixer = false; };
    package = {
      specVersion = "2.4";
      identifier = { name = "splitmix"; version = "0.1.3.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "";
      homepage = "";
      url = "";
      synopsis = "Fast Splittable PRNG";
      description = "Pure Haskell implementation of SplitMix described in\n\nGuy L. Steele, Jr., Doug Lea, and Christine H. Flood. 2014.\nFast splittable pseudorandom number generators. In Proceedings\nof the 2014 ACM International Conference on Object Oriented\nProgramming Systems Languages & Applications (OOPSLA '14). ACM,\nNew York, NY, USA, 453-472. DOI:\n<https://doi.org/10.1145/2660193.2660195>\n\nThe paper describes a new algorithm /SplitMix/ for /splittable/\npseudorandom number generator that is quite fast: 9 64 bit arithmetic/logical\noperations per 64 bits generated.\n\n/SplitMix/ is tested with two standard statistical test suites (DieHarder and\nTestU01, this implementation only using the former) and it appears to be\nadequate for \"everyday\" use, such as Monte Carlo algorithms and randomized\ndata structures where speed is important.\n\nIn particular, it __should not be used for cryptographic or security applications__,\nbecause generated sequences of pseudorandom values are too predictable\n(the mixing functions are easily inverted, and two successive outputs\nsuffice to reconstruct the internal state).";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ] ++ pkgs.lib.optionals (!(compiler.isGhcjs && true)) (pkgs.lib.optional (!(compiler.isGhc && true)) (hsPkgs."time" or (errorHandler.buildDepError "time")));
        frameworks = pkgs.lib.optionals (!(compiler.isGhcjs && true)) (pkgs.lib.optionals (compiler.isGhc && true) (pkgs.lib.optionals (!system.isWindows) (pkgs.lib.optional (system.isOsx || system.isIOS) (pkgs."Security" or (errorHandler.sysDepError "Security")))));
        buildable = true;
      };
      tests = {
        "splitmix-examples" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."splitmix" or (errorHandler.buildDepError "splitmix"))
          ];
          buildable = true;
        };
        "splitmix-th-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."splitmix" or (errorHandler.buildDepError "splitmix"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/splitmix-0.1.3.2.tar.gz";
      sha256 = "a61d4e8b30f5a16526d7d31171b674ae7924d2207f378060d13363bd8794de8c";
    });
  }) // {
    package-description-override = "cabal-version:      2.4\nname:               splitmix\nversion:            0.1.3.2\nsynopsis:           Fast Splittable PRNG\ndescription:\n  Pure Haskell implementation of SplitMix described in\n  .\n  Guy L. Steele, Jr., Doug Lea, and Christine H. Flood. 2014.\n  Fast splittable pseudorandom number generators. In Proceedings\n  of the 2014 ACM International Conference on Object Oriented\n  Programming Systems Languages & Applications (OOPSLA '14). ACM,\n  New York, NY, USA, 453-472. DOI:\n  <https://doi.org/10.1145/2660193.2660195>\n  .\n  The paper describes a new algorithm /SplitMix/ for /splittable/\n  pseudorandom number generator that is quite fast: 9 64 bit arithmetic/logical\n  operations per 64 bits generated.\n  .\n  /SplitMix/ is tested with two standard statistical test suites (DieHarder and\n  TestU01, this implementation only using the former) and it appears to be\n  adequate for \"everyday\" use, such as Monte Carlo algorithms and randomized\n  data structures where speed is important.\n  .\n  In particular, it __should not be used for cryptographic or security applications__,\n  because generated sequences of pseudorandom values are too predictable\n  (the mixing functions are easily inverted, and two successive outputs\n  suffice to reconstruct the internal state).\n\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\nbug-reports:        https://github.com/haskellari/splitmix/issues\ncategory:           System, Random\nbuild-type:         Simple\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.4\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.7\n   || ==9.8.4\n   || ==9.10.2\n   || ==9.12.2\n   || ==9.14.1\n\nextra-doc-files:\n  Changelog.md\n  README.md\n\nextra-source-files:\n  make-hugs.sh\n  test-hugs.sh\n\nflag optimised-mixer\n  description: Use JavaScript for mix32\n  manual:      True\n  default:     False\n\nlibrary\n  default-language: Haskell2010\n  ghc-options:      -Wall\n  hs-source-dirs:   src\n  exposed-modules:\n    System.Random.SplitMix\n    System.Random.SplitMix32\n\n  other-modules:\n    System.Random.SplitMix.Init\n\n  -- dump-core\n  -- build-depends: dump-core\n  -- ghc-options: -fplugin=DumpCore -fplugin-opt DumpCore:core-html\n\n  build-depends:\n    , base     >=4.12.0.0 && <4.23\n    , deepseq  >=1.4.4.0  && <1.6\n\n  if flag(optimised-mixer)\n    cpp-options: -DOPTIMISED_MIX32=1\n\n  -- We don't want to depend on time, nor unix or Win32 packages\n  -- because it's valuable that splitmix and QuickCheck doesn't\n  -- depend on about anything\n\n  if impl(ghcjs)\n    cpp-options: -DSPLITMIX_INIT_GHCJS=1\n\n  else\n    if impl(ghc)\n      cpp-options: -DSPLITMIX_INIT_C=1\n\n      if os(windows)\n        c-sources: cbits-win/init.c\n\n      elif (os(osx) || os(ios))\n        c-sources:  cbits-apple/init.c\n        frameworks: Security\n\n      else\n        c-sources: cbits-unix/init.c\n\n    else\n      cpp-options:   -DSPLITMIX_INIT_COMPAT=1\n      build-depends: time >=1.2.0.3 && <1.16\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskellari/splitmix.git\n\ntest-suite splitmix-examples\n  type:             exitcode-stdio-1.0\n  default-language: Haskell2010\n  ghc-options:      -Wall\n  hs-source-dirs:   tests\n  main-is:          splitmix-examples.hs\n  build-depends:\n    , base\n    , HUnit     >=1.6.0.0 && <1.7\n    , splitmix\n\ntest-suite splitmix-th-test\n  default-language: Haskell2010\n  type:             exitcode-stdio-1.0\n  ghc-options:      -Wall -threaded -rtsopts\n  hs-source-dirs:   tests\n  main-is:          splitmix-th-test.hs\n  build-depends:\n    , base\n    , template-haskell\n    , splitmix\n";
  }