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
    flags = { compare-benchmarks = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "unagi-chan"; version = "0.4.1.4"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "brandon.m.simmons@gmail.com";
      author = "Brandon Simmons";
      homepage = "";
      url = "";
      synopsis = "Fast concurrent queues with a Chan-like API, and more";
      description = "This library provides implementations of concurrent FIFO queues (for both\ngeneral boxed and primitive unboxed values) that are fast, perform well\nunder contention, and offer a Chan-like interface. The library may be of\nlimited usefulness outside of x86 architectures where the fetch-and-add\ninstruction is not available.\n\nWe export several variations of our design; some support additional\nfunctionality while others try for lower latency by removing features or\nmaking them more restrictive (e.g. in the @Unboxed@ variants).\n\n- @Unagi@: a general-purpose near drop-in replacement for @Chan@.\n\n- @Unagi.Unboxed@: like @Unagi@ but specialized for primitive types; this\nmay perform better if a queue grows very large.\n\n- @Unagi.Bounded@: a bounded variant with blocking and non-blocking writes,\nand other functionality where a notion of the queue's capacity is\nrequired.\n\n- @Unagi.NoBlocking@: lowest latency implementations for when blocking\nreads aren't required.\n\n- @Unagi.NoBlocking.Unboxed@: like @Unagi.NoBlocking@ but for primitive\ntypes.\n\nSome of these may be deprecated in the future if they are found to provide\nlittle performance benefit, or no unique features; you should benchmark and\nexperiment with them for your use cases, and please submit pull requests\nfor additions to the benchmark suite that reflect what you find.\n\nHere is an example benchmark measuring the time taken to concurrently write\nand read 100,000 messages, with work divided amongst increasing number of\nreaders and writers, comparing against the top-performing queues in the\nstandard libraries. The inset graph shows a zoomed-in view on the\nimplementations here.\n\n<<http://i.imgur.com/J5rLUFn.png>>\n";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."atomic-primops" or (errorHandler.buildDepError "atomic-primops"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."atomic-primops" or (errorHandler.buildDepError "atomic-primops"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "single" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unagi-chan" or (errorHandler.buildDepError "unagi-chan"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
          ] ++ pkgs.lib.optional (flags.compare-benchmarks) (hsPkgs."stm" or (errorHandler.buildDepError "stm"));
          buildable = true;
        };
        "multi" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unagi-chan" or (errorHandler.buildDepError "unagi-chan"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
          ] ++ pkgs.lib.optional (flags.compare-benchmarks) (hsPkgs."stm" or (errorHandler.buildDepError "stm"));
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/unagi-chan-0.4.1.4.tar.gz";
      sha256 = "d9d6f4ab07def8e84a942bb23791830a61faf89166cb7185a3b2f97cb45128b5";
    });
  }) // {
    package-description-override = "name:                unagi-chan\nversion:             0.4.1.4\n\nsynopsis:            Fast concurrent queues with a Chan-like API, and more\n\ndescription:\n    This library provides implementations of concurrent FIFO queues (for both\n    general boxed and primitive unboxed values) that are fast, perform well\n    under contention, and offer a Chan-like interface. The library may be of\n    limited usefulness outside of x86 architectures where the fetch-and-add\n    instruction is not available.\n    .\n    We export several variations of our design; some support additional\n    functionality while others try for lower latency by removing features or\n    making them more restrictive (e.g. in the @Unboxed@ variants). \n    .\n    - @Unagi@: a general-purpose near drop-in replacement for @Chan@.\n    .\n    - @Unagi.Unboxed@: like @Unagi@ but specialized for primitive types; this\n      may perform better if a queue grows very large.\n    .\n    - @Unagi.Bounded@: a bounded variant with blocking and non-blocking writes,\n      and other functionality where a notion of the queue's capacity is\n      required.\n    .\n    - @Unagi.NoBlocking@: lowest latency implementations for when blocking\n      reads aren't required.\n    .\n    - @Unagi.NoBlocking.Unboxed@: like @Unagi.NoBlocking@ but for primitive\n      types.\n    .\n    Some of these may be deprecated in the future if they are found to provide\n    little performance benefit, or no unique features; you should benchmark and\n    experiment with them for your use cases, and please submit pull requests\n    for additions to the benchmark suite that reflect what you find.\n    .\n    Here is an example benchmark measuring the time taken to concurrently write\n    and read 100,000 messages, with work divided amongst increasing number of\n    readers and writers, comparing against the top-performing queues in the\n    standard libraries. The inset graph shows a zoomed-in view on the\n    implementations here.\n    .\n    <<http://i.imgur.com/J5rLUFn.png>>\n    .\n    \nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              Brandon Simmons\nmaintainer:          brandon.m.simmons@gmail.com\ncategory:            Concurrency\nbuild-type:          Simple\ncabal-version:       >=1.10\n-- currently uploaded to imgur; move to this eventually\n--extra-doc-files:     images/*.png\n--cabal-version:       >=1.18\nextra-source-files: CHANGELOG.markdown\nTested-With: GHC ==7.8.4 || ==7.10.3 || ==8.0.2 || ==8.2.2 || ==8.4.4 || ==8.6.4 || ==8.8.1 || ==8.10.7\n\nsource-repository head   \n    type:     git\n    location: https://github.com/jberryman/unagi-chan.git\n    branch:   master\n\nlibrary\n  hs-source-dirs:      src\n  exposed-modules:     Control.Concurrent.Chan.Unagi\n                     , Control.Concurrent.Chan.Unagi.Unboxed\n                     , Control.Concurrent.Chan.Unagi.Bounded\n                     , Control.Concurrent.Chan.Unagi.NoBlocking\n                     , Control.Concurrent.Chan.Unagi.NoBlocking.Unboxed\n\n  other-modules:       Control.Concurrent.Chan.Unagi.Internal\n                     , Control.Concurrent.Chan.Unagi.Unboxed.Internal\n                     , Control.Concurrent.Chan.Unagi.Bounded.Internal\n                     , Control.Concurrent.Chan.Unagi.NoBlocking.Internal\n                     , Control.Concurrent.Chan.Unagi.NoBlocking.Types\n                     , Control.Concurrent.Chan.Unagi.NoBlocking.Unboxed.Internal\n                     , Control.Concurrent.Chan.Unagi.Constants\n                     , Utilities\n                     , Data.Atomics.Counter.Fat\n\n  ghc-options:        -Wall -funbox-strict-fields\n  build-depends:       base >= 4.7 && < 5\n                     , atomic-primops >= 0.8\n                     , primitive>=0.5.3\n                     , ghc-prim\n  default-language:    Haskell2010\n  \n  if !arch(i386) && !arch(x86_64) && !arch(aarch64)\n    cpp-options: -DNOT_optimised\n  -- TODO: more complete list of 64-bit archs:\n  if arch(x86_64) || arch(aarch64)\n    cpp-options: -DIS_64_BIT\n\n  -- tryReadMVar is only available and non-broken on ghc >= 7.8.3\n  if impl(ghc >= 7.8.3)\n    cpp-options: -DTRYREADMVAR\n  \n-- TODO\n--   For v0,4:\n--   - More benchmarks, and test code we can analyze with ghc-events-analyze.\n--   - Explore faster single-threaded write (see #11)\n--   - Explore Stream interface for variants other than NoBlocking (see #11)\n--   - Experiments w/ new GHC 7.10 stuff, and at least make sure buildable\n--  -------\n--  - For GHC 7.10+\n--     - look at small arrays (w/out card-marking)\n--     - re-benchmark array creation and adjust next segment wait\n--  - Do a benchmark of multiple queues running in parallel, to see if we are\n--     affected by global allocator issues with pinned memory:\n--     http://thread.gmane.org/gmane.comp.lang.haskell.parallel/218\n--\n-- Possibly-similar prior work to look at:\n--\n--   - maybe implement \"Fast Concurrent Queues for x86 Processors\" by Morrison & Afek (non-blocking, probably more clever)\n--   - Also looks like a similar (but lockfree, as above) counter-based queue has been developed by FB:\n--       https://github.com/facebook/folly/blob/master/folly/MPMCQueue.h\n\n\n-- Please just build tests and run:\n--     $ time ./dist/build/test/test\n-- Doing `cabal test` takes forever for some reason.\ntest-suite test\n  type: exitcode-stdio-1.0\n  ghc-options: -Wall -funbox-strict-fields\n  ghc-options: -O2  -rtsopts  -threaded \n  -- NOTE: configure --enable-profiling overrides this:\n  ghc-options: -with-rtsopts=-N\n  ghc-options: -fno-ignore-asserts\n  -- for some hacks for Addr:\n  ghc-options: -fno-warn-orphans \n  ghc-options: -fno-warn-missing-methods\n  -- I guess we need to put 'src' here to get access to Internal modules\n  hs-source-dirs: tests, src\n  main-is: Main.hs\n  other-modules:\n      Atomics\n    , Deadlocks\n    , DupChan\n    , Implementations\n    , IndexedMVar\n    , Smoke\n    , Unagi\n    , UnagiUnboxed\n    , UnagiBounded\n    , UnagiNoBlocking\n    , UnagiNoBlockingUnboxed\n  build-depends:       base\n                     , primitive>=0.5.3\n                     , atomic-primops >= 0.8\n                     , containers\n                     , ghc-prim\n  default-language:    Haskell2010\n  \n  -- These have to be copied from 'library' section too!\n  if !arch(i386) && !arch(x86_64) && !arch(aarch64)\n    cpp-options: -DNOT_optimised\n  if arch(x86_64) || arch(aarch64)\n    cpp-options: -DIS_64_BIT\n \n  if impl(ghc >= 7.8.3)\n    cpp-options: -DTRYREADMVAR\n\n-- compare benchmarks with Chan, TQueue, and (eventually) lockfree-queue?\nflag compare-benchmarks\n  default: False\n  manual:  True\n\nbenchmark single\n  type:               exitcode-stdio-1.0\n  ghc-options:        -Wall -O2 -threaded -funbox-strict-fields -fforce-recomp -rtsopts\n  hs-source-dirs:     benchmarks\n  default-language:   Haskell2010\n  default-extensions: CPP\n  build-depends: base\n               , unagi-chan\n               , criterion\n  if flag(compare-benchmarks)\n      cpp-options: -DCOMPARE_BENCHMARKS\n      build-depends: stm\n                -- , lockfree-queue\n\n  main-is:        single.hs\n  ghc-options:    -with-rtsopts=-N1\n\n-- To run comparison benchmark used in graph above, run:\n--     $ cabal configure --enable-benchmarks -fcompare-benchmarks\n--     $ cabal bench multi --benchmark-option=-omulti3.html --benchmark-option='Demo'\nbenchmark multi\n  type:               exitcode-stdio-1.0\n  ghc-options:        -Wall -O2 -threaded -funbox-strict-fields -fforce-recomp -rtsopts\n  hs-source-dirs:     benchmarks\n  default-language:   Haskell2010\n  default-extensions: CPP\n  build-depends: base\n               , unagi-chan\n               , criterion\n  if flag(compare-benchmarks)\n      cpp-options: -DCOMPARE_BENCHMARKS\n      build-depends: stm\n                -- , lockfree-queue\n\n  main-is:       multi.hs\n  ghc-options:   -with-rtsopts=-N\n  build-depends: async\n\n\n-- flag dev\n--   default: False\n--   manual: True\n\n-- for profiling, checking out core, etc\n-- executable dev-example\n--  -- for n in `find dist/build/dev-example/dev-example-tmp -name '*dump-simpl'`; do cp $n \"core-example/$(basename $n).$(git rev-parse --abbrev-ref HEAD)\"; done\n--  if !flag(dev)\n--    buildable: False\n--  else\n--    build-depends:       \n--        base\n--      , stm\n--      , unagi-chan\n--\n--  ghc-options: -ddump-to-file -ddump-simpl -dsuppress-module-prefixes -dsuppress-uniques -ddump-core-stats -ddump-inlinings\n--  ghc-options: -O2  -rtsopts  \n--  \n--  -- Either do threaded for eventlogging and simple timing...\n--  ghc-options: -threaded -eventlog\n--  -- and run e.g. with +RTS -N -l\n--\n--  -- ...or do non-threaded runtime\n--  --ghc-prof-options: -fprof-auto\n--  --Relevant profiling RTS settings:  -xt\n--  -- TODO also check out +RTS -A10m, and look at output of -sstderr\n--\n--  hs-source-dirs: core-example\n--  main-is: Main.hs\n--  default-language:    Haskell2010\n";
  }