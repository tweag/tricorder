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
    flags = { dev = false; no-cmm = false; };
    package = {
      specVersion = "3.0";
      identifier = { name = "atomic-counter"; version = "0.1.2.4"; };
      license = "Apache-2.0";
      copyright = "(c) Sergey Vinokurov 2022";
      maintainer = "Sergey Vinokurov <serg.foo@gmail.com>";
      author = "Sergey Vinokurov";
      homepage = "https://github.com/sergv/atomic-counter";
      url = "";
      synopsis = "Mutable counters that can be modified with atomic operatinos";
      description = "This package defines Counter type that can be safely modified\nconcurrently from multiple threads. The type supports only few\noperations, namely read, write, cas (compare and swap), add,\nsubtract and a few bitwise ones like or, and xor.\n\nMost common use case is having a shared counter that multiple\nthreads increment. Another potential use case is lightweight locks.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."atomic-counter" or (errorHandler.buildDepError "atomic-counter"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."atomic-counter" or (errorHandler.buildDepError "atomic-counter"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/atomic-counter-0.1.2.4.tar.gz";
      sha256 = "b101e8dedc66da051a16022287d9b05c2dcb2f54f973fb09298b3486cd63ec2f";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\n\n-- Created : 29 December 2022\n\nname:\n  atomic-counter\nversion:\n  0.1.2.4\nsynopsis:\n  Mutable counters that can be modified with atomic operatinos\n\ndescription:\n  This package defines Counter type that can be safely modified\n  concurrently from multiple threads. The type supports only few\n  operations, namely read, write, cas (compare and swap), add,\n  subtract and a few bitwise ones like or, and xor.\n\n  Most common use case is having a shared counter that multiple\n  threads increment. Another potential use case is lightweight locks.\n\ncopyright:\n  (c) Sergey Vinokurov 2022\nlicense:\n  Apache-2.0\nlicense-file:\n  LICENSE\nauthor:\n  Sergey Vinokurov\nmaintainer:\n  Sergey Vinokurov <serg.foo@gmail.com>\ncategory:\n  Concurrency, Data, Data Structures\n\ntested-with:\n  GHC == 8.6,\n  GHC == 8.8,\n  GHC == 8.10,\n  GHC == 9.2,\n  GHC == 9.4,\n  GHC == 9.6,\n  GHC == 9.8,\n  GHC == 9.10,\n  GHC == 9.12,\n\nbuild-type:\n  Simple\n\nextra-doc-files:\n  Changelog.md\n  Readme.md\n\nhomepage:\n  https://github.com/sergv/atomic-counter\nbug-reports:\n  https://github.com/sergv/atomic-counter/issues\n\nsource-repository head\n  type: git\n  location: https://github.com/sergv/atomic-counter.git\n\nflag dev\n  description:\n    Enable development flags like -Werror and linting\n  default:\n    False\n  manual:\n    True\n\nflag no-cmm\n  description:\n    Don't use cmm implementation\n  default:\n    False\n  manual:\n    True\n\ncommon ghc-options\n  default-language:\n    Haskell2010\n\n  ghc-options:\n    -Weverything\n    -Wno-all-missed-specialisations\n    -Wno-implicit-prelude\n    -Wno-missed-specialisations\n    -Wno-missing-import-lists\n    -Wno-missing-local-signatures\n    -Wno-safe\n    -Wno-type-defaults\n    -Wno-unsafe\n\n  if impl(ghc >= 8.8)\n    ghc-options:\n      -Wno-missing-deriving-strategies\n\n  if impl(ghc >= 8.10)\n    ghc-options:\n      -Wno-missing-safe-haskell-mode\n      -Wno-prepositive-qualified-module\n\n  if impl(ghc >= 9.2)\n    ghc-options:\n      -Wno-missing-kind-signatures\n\n  if impl(ghc >= 9.8)\n    ghc-options:\n      -Wno-missing-role-annotations\n      -Wno-missing-poly-kind-signatures\n\nlibrary\n  import: ghc-options\n  exposed-modules:\n    Control.Concurrent.Counter\n    Control.Concurrent.Counter.Lifted.IO\n    Control.Concurrent.Counter.Lifted.ST\n    Control.Concurrent.Counter.Unlifted\n  hs-source-dirs:\n    src\n  build-depends:\n    , base >= 4.12 && < 5\n  if impl(ghc >= 9.4) && !arch(javascript) && !arch(i386) && !flag(no-cmm)\n    cmm-sources:\n      Counter.cmm\n    cpp-options:\n      -DUSE_CMM\n    if flag(dev)\n      ghc-options:\n        -dcmm-lint\n\ntest-suite test\n  import: ghc-options\n  type:\n    exitcode-stdio-1.0\n  main-is:\n    test/TestMain.hs\n  other-modules:\n    TestUtils\n  hs-source-dirs:\n    .\n    test\n  build-depends:\n    , QuickCheck\n    , async >= 2\n    , atomic-counter\n    , base >= 4.12\n    , tasty\n    , tasty-quickcheck\n  ghc-options:\n    -rtsopts\n    -threaded\n    \"-with-rtsopts=-N -A32M\"\n    -main-is TestMain\n\nbenchmark bench\n  import: ghc-options\n  type:\n    exitcode-stdio-1.0\n  main-is:\n    bench/BenchMain.hs\n  other-modules:\n    TestUtils\n  hs-source-dirs:\n    .\n    test\n  build-depends:\n    , QuickCheck\n    , async >= 2\n    , atomic-counter\n    , base >= 4.12\n    , primitive\n    , stm\n    , tasty >= 1.4.2\n    , tasty-bench >= 0.3.4\n    , tasty-quickcheck\n  ghc-options:\n    -rtsopts\n    -threaded\n    \"-with-rtsopts=-N -A32M\"\n    -main-is BenchMain\n";
  }