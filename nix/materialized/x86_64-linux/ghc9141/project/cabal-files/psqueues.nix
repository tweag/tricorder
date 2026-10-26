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
      identifier = { name = "psqueues"; version = "0.2.8.3"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Jasper Van der Jeugt <jaspervdj@gmail.com>";
      author = "";
      homepage = "";
      url = "";
      synopsis = "Pure priority search queues";
      description = "The psqueues package provides\n<http://en.wikipedia.org/wiki/Priority_queue Priority Search Queues> in\nthree different flavors.\n\n* @OrdPSQ k p v@, which uses the @Ord k@ instance to provide fast insertion,\ndeletion and lookup. This implementation is based on Ralf Hinze's\n<http://citeseer.ist.psu.edu/hinze01simple.html A Simple Implementation Technique for Priority Search Queues>.\nHence, it is similar to the\n<http://hackage.haskell.org/package/PSQueue PSQueue> library, although it is\nconsiderably faster and provides a slightly different API.\n\n* @IntPSQ p v@ is a far more efficient implementation. It fixes the key type\nto @Int@ and uses a <http://en.wikipedia.org/wiki/Radix_tree radix tree>\n(like @IntMap@) with an additional min-heap property.\n\n* @HashPSQ k p v@ is a fairly straightforward extension of @IntPSQ@: it\nsimply uses the keys' hashes as indices in the @IntPSQ@. If there are any\nhash collisions, it uses an @OrdPSQ@ to resolve those. The performance of\nthis implementation is comparable to that of @IntPSQ@, but it is more widely\napplicable since the keys are not restricted to @Int@, but rather to any\n@Hashable@ datatype.\n\nEach of the three implementations provides the same API, so they can be used\ninterchangeably. The benchmarks show how they perform relative to one\nanother, and also compared to the other Priority Search Queue\nimplementations on Hackage:\n<http://hackage.haskell.org/package/PSQueue PSQueue>\nand\n<http://hackage.haskell.org/package/fingertree-psqueue fingertree-psqueue>.\n\n<<http://i.imgur.com/KmbDKR6.png>>\n\n<<http://i.imgur.com/ClT181D.png>>\n\nTypical applications of Priority Search Queues include:\n\n* Caches, and more specifically LRU Caches;\n\n* Schedulers;\n\n* Pathfinding algorithms, such as Dijkstra's and A*.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
        ];
        buildable = true;
      };
      tests = {
        "psqueues-tests" = {
          depends = [
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."psqueues" or (errorHandler.buildDepError "psqueues"))
            (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "psqueues-benchmarks" = {
          depends = [
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."PSQueue" or (errorHandler.buildDepError "PSQueue"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."psqueues" or (errorHandler.buildDepError "psqueues"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/psqueues-0.2.8.3.tar.gz";
      sha256 = "10bcbe9aeb3ca00d72e86d940cf91b021b83f908885375120d4d51d0240ad076";
    });
  }) // {
    package-description-override = "Name:          psqueues\r\nVersion:       0.2.8.3\r\nX-revision:    2\r\nLicense:       BSD3\r\nLicense-file:  LICENSE\r\nMaintainer:    Jasper Van der Jeugt <jaspervdj@gmail.com>\r\nBug-reports:   https://github.com/jaspervdj/psqueues/issues\r\nSynopsis:      Pure priority search queues\r\nCategory:      Data Structures\r\nBuild-type:    Simple\r\nCabal-version: >=1.10\r\nTested-with:   GHC==9.6.4, GHC==9.4.2, GHC==9.2.2, GHC==9.0.2, GHC==8.10.7, GHC==8.8.4, GHC==8.6.5, GHC==8.4.4, GHC==8.2.2, GHC==8.0.2\r\n\r\nDescription:\r\n    The psqueues package provides\r\n    <http://en.wikipedia.org/wiki/Priority_queue Priority Search Queues> in\r\n    three different flavors.\r\n    .\r\n    * @OrdPSQ k p v@, which uses the @Ord k@ instance to provide fast insertion,\r\n    deletion and lookup. This implementation is based on Ralf Hinze's\r\n    <http://citeseer.ist.psu.edu/hinze01simple.html A Simple Implementation Technique for Priority Search Queues>.\r\n    Hence, it is similar to the\r\n    <http://hackage.haskell.org/package/PSQueue PSQueue> library, although it is\r\n    considerably faster and provides a slightly different API.\r\n    .\r\n    * @IntPSQ p v@ is a far more efficient implementation. It fixes the key type\r\n    to @Int@ and uses a <http://en.wikipedia.org/wiki/Radix_tree radix tree>\r\n    (like @IntMap@) with an additional min-heap property.\r\n    .\r\n    * @HashPSQ k p v@ is a fairly straightforward extension of @IntPSQ@: it\r\n    simply uses the keys' hashes as indices in the @IntPSQ@. If there are any\r\n    hash collisions, it uses an @OrdPSQ@ to resolve those. The performance of\r\n    this implementation is comparable to that of @IntPSQ@, but it is more widely\r\n    applicable since the keys are not restricted to @Int@, but rather to any\r\n    @Hashable@ datatype.\r\n    .\r\n    Each of the three implementations provides the same API, so they can be used\r\n    interchangeably. The benchmarks show how they perform relative to one\r\n    another, and also compared to the other Priority Search Queue\r\n    implementations on Hackage:\r\n    <http://hackage.haskell.org/package/PSQueue PSQueue>\r\n    and\r\n    <http://hackage.haskell.org/package/fingertree-psqueue fingertree-psqueue>.\r\n    .\r\n    <<http://i.imgur.com/KmbDKR6.png>>\r\n    .\r\n    <<http://i.imgur.com/ClT181D.png>>\r\n    .\r\n    Typical applications of Priority Search Queues include:\r\n    .\r\n    * Caches, and more specifically LRU Caches;\r\n    .\r\n    * Schedulers;\r\n    .\r\n    * Pathfinding algorithms, such as Dijkstra's and A*.\r\n\r\nExtra-source-files:\r\n    CHANGELOG\r\n\r\nSource-repository head\r\n    type:     git\r\n    location: http://github.com/jaspervdj/psqueues.git\r\n\r\nLibrary\r\n    Default-language: Haskell2010\r\n    Ghc-options:      -O2 -Wall\r\n    Hs-source-dirs:   src\r\n\r\n    Build-depends:\r\n          base     >= 4.2     && < 5\r\n        , deepseq  >= 1.2     && < 1.6\r\n        , hashable >= 1.1.2.3 && < 1.6\r\n\r\n    Exposed-modules:\r\n        Data.HashPSQ\r\n        Data.IntPSQ\r\n        Data.OrdPSQ\r\n    Other-modules:\r\n        Data.BitUtil\r\n        Data.HashPSQ.Internal\r\n        Data.IntPSQ.Internal\r\n        Data.OrdPSQ.Internal\r\n\r\nBenchmark psqueues-benchmarks\r\n    Default-language: Haskell2010\r\n    Ghc-options:      -Wall\r\n    Hs-source-dirs:   src benchmarks\r\n    Main-is:          Main.hs\r\n    Type:             exitcode-stdio-1.0\r\n\r\n    Other-modules:\r\n        BenchmarkTypes\r\n        Data.BitUtil\r\n        Data.HashPSQ\r\n        Data.HashPSQ.Benchmark\r\n        Data.HashPSQ.Internal\r\n        Data.IntPSQ\r\n        Data.IntPSQ.Benchmark\r\n        Data.IntPSQ.Internal\r\n        Data.OrdPSQ\r\n        Data.OrdPSQ.Benchmark\r\n        Data.OrdPSQ.Internal\r\n        Data.PSQueue.Benchmark\r\n\r\n    Build-depends:\r\n          criterion            >= 0.8\r\n        , PSQueue              >= 1.1\r\n        , random               >= 1.0\r\n\r\n        , base\r\n        , deepseq\r\n        , hashable\r\n        , psqueues\r\n\r\nTest-suite psqueues-tests\r\n    Cpp-options:      -DTESTING -DSTRICT\r\n    Default-language: Haskell2010\r\n    Ghc-options:      -Wall\r\n    Hs-source-dirs:   src tests\r\n    Main-is:          Main.hs\r\n    Type:             exitcode-stdio-1.0\r\n\r\n    Other-modules:\r\n        Data.BitUtil\r\n        Data.HashPSQ\r\n        Data.HashPSQ.Internal\r\n        Data.HashPSQ.Tests\r\n        Data.IntPSQ\r\n        Data.IntPSQ.Internal\r\n        Data.IntPSQ.Tests\r\n        Data.OrdPSQ\r\n        Data.OrdPSQ.Internal\r\n        Data.OrdPSQ.Tests\r\n        Data.PSQ.Class\r\n        Data.PSQ.Class.Gen\r\n        Data.PSQ.Class.Tests\r\n        Data.PSQ.Class.Util\r\n\r\n    Build-depends:\r\n          HUnit            >= 1.2 && < 1.7\r\n        , QuickCheck       >= 2.7 && < 2.19\r\n        , tasty            >= 1.2 && < 1.6\r\n        , tasty-hunit      >= 0.9 && < 0.11\r\n        , tasty-quickcheck >= 0.8 && < 0.12\r\n\r\n        , base\r\n        , deepseq\r\n        , hashable\r\n        , psqueues\r\n        , tagged\r\n";
  }