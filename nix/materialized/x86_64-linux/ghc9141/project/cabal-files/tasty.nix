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
    flags = { unix = true; terminal-size = true; };
    package = {
      specVersion = "1.10";
      identifier = { name = "tasty"; version = "1.5.5"; };
      license = "MIT";
      copyright = "";
      maintainer = "Roman Cheplyaka <roma@ro-che.info>";
      author = "Roman Cheplyaka <roma@ro-che.info>";
      homepage = "https://github.com/UnkindPartition/tasty";
      url = "";
      synopsis = "Modern and extensible testing framework";
      description = "Tasty is a modern testing framework for Haskell.\nIt lets you combine your unit tests, golden\ntests, QuickCheck/SmallCheck properties, and any\nother types of tests into a single test suite.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ((([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
        ] ++ pkgs.lib.optional (flags.terminal-size && !system.isWasm32) (hsPkgs."terminal-size" or (errorHandler.buildDepError "terminal-size"))) ++ pkgs.lib.optional (!system.isX86_64 && !system.isAarch64 && !system.isPpc64le && !system.isPpc64 && !system.isS390x && !system.isRiscv64 && !system.isLoongarch64) (hsPkgs."unbounded-delays" or (errorHandler.buildDepError "unbounded-delays"))) ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "8.4")) (hsPkgs."time" or (errorHandler.buildDepError "time"))) ++ pkgs.lib.optionals (!system.isWindows && !(compiler.isGhcjs && true)) (pkgs.lib.optional (flags.unix) (hsPkgs."unix" or (errorHandler.buildDepError "unix")));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tasty-1.5.5.tar.gz";
      sha256 = "5fc49a9b762691afa187c4df0df10dc95af1af712f455d20039bc63afdf34722";
    });
  }) // {
    package-description-override = "cabal-version:       >=1.10\nname:                tasty\nversion:             1.5.5\nsynopsis:            Modern and extensible testing framework\ndescription:         Tasty is a modern testing framework for Haskell.\n                     It lets you combine your unit tests, golden\n                     tests, QuickCheck/SmallCheck properties, and any\n                     other types of tests into a single test suite.\nlicense:             MIT\nlicense-file:        LICENSE\nauthor:              Roman Cheplyaka <roma@ro-che.info>\nmaintainer:          Roman Cheplyaka <roma@ro-che.info>\nhomepage:            https://github.com/UnkindPartition/tasty\nbug-reports:         https://github.com/UnkindPartition/tasty/issues\n-- copyright:\ncategory:            Testing\nbuild-type:          Simple\nextra-source-files:  CHANGELOG.md, README.md\n\nSource-repository head\n  type:     git\n  location: https://github.com/UnkindPartition/tasty.git\n  subdir:   core\n\nflag unix\n  description:\n    Depend on the unix package to install signal handlers\n  default: True\n\nflag terminal-size\n  description:\n    Depend on the terminal-size package to get terminal size\n  default: True\n\nlibrary\n  exposed-modules:\n    Test.Tasty\n    Test.Tasty.Options\n    Test.Tasty.Providers\n    Test.Tasty.Providers.ConsoleFormat\n    Test.Tasty.Runners\n    Test.Tasty.Ingredients\n    Test.Tasty.Ingredients.Basic\n    Test.Tasty.Ingredients.ConsoleReporter\n\n    -- for testing only\n    Test.Tasty.Patterns.Types\n    Test.Tasty.Patterns.Parser\n    Test.Tasty.Patterns.Printer\n    Test.Tasty.Patterns.Eval\n  other-modules:\n    Control.Concurrent.Async\n    Test.Tasty.Parallel\n    Test.Tasty.Core\n    Test.Tasty.Options.Core\n    Test.Tasty.Options.Env\n    Test.Tasty.Patterns\n    Test.Tasty.Patterns.Expr\n    Test.Tasty.Run\n    Test.Tasty.Runners.Reducers\n    Test.Tasty.Runners.Utils\n    Test.Tasty.CmdLine\n    Test.Tasty.Ingredients.ListTests\n    Test.Tasty.Ingredients.IncludingOptions\n\n  build-depends:\n    base                 >= 4.9  && < 5,\n    stm                  >= 2.3  && < 2.6,\n    containers           >= 0.5.8 && < 0.9,\n    transformers         >= 0.5  && < 0.7,\n    tagged               >= 0.5  && < 0.10,\n    optparse-applicative >= 0.14 && < 0.20,\n    ansi-terminal        >= 0.9  && < 1.2\n\n  if flag(terminal-size) && !arch(wasm32)\n    build-depends:\n      terminal-size >= 0.3 && < 0.4\n\n  -- No reason to depend on unbounded-delays on 64-bit architecture\n  if(!arch(x86_64) && !arch(aarch64) && !arch(ppc64le) && !arch(ppc64) && !arch(s390x) && !arch(riscv64) && !arch(loongarch64))\n    build-depends:\n      unbounded-delays >= 0.1 && < 0.2\n\n  if(!impl(ghc >= 8.4))\n    build-depends: time >= 1.4 && < 1.13\n\n  if !os(windows) && !impl(ghcjs)\n    cpp-options: -DUSE_WCWIDTH\n    if flag(unix)\n      build-depends: unix < 2.9\n\n  -- hs-source-dirs:\n  default-language:    Haskell2010\n  default-extensions:  CPP, ScopedTypeVariables\n  ghc-options:\n    -Wall\n    -Wno-incomplete-uni-patterns\n    -Wcompat\n";
  }