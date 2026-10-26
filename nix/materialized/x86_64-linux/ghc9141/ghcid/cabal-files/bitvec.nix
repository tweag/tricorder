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
    flags = { simd = true; };
    package = {
      specVersion = "2.0";
      identifier = { name = "bitvec"; version = "1.1.6.0"; };
      license = "BSD-3-Clause";
      copyright = "2019-2022 Andrew Lelechenko, 2012-2016 James Cook";
      maintainer = "Andrew Lelechenko <andrew.lelechenko@gmail.com>";
      author = "Andrew Lelechenko <andrew.lelechenko@gmail.com>,\nJames Cook <mokus@deepbondi.net>";
      homepage = "https://github.com/Bodigrim/bitvec";
      url = "";
      synopsis = "Space-efficient bit vectors";
      description = "A newtype over 'Bool' with a better 'Vector' instance: 8x less memory, up to 3500x faster.\n\nThe <https://hackage.haskell.org/package/vector vector>\npackage represents unboxed arrays of 'Bool's\nspending 1 byte (8 bits) per boolean.\nThis library provides a newtype wrapper 'Bit' and a custom instance\nof an unboxed 'Vector', which packs bits densely,\nachieving an __8x smaller memory footprint.__\nThe performance stays mostly the same;\nthe most significant degradation happens for random writes\n(up to 10% slower).\nOn the other hand, for certain bulk bit operations\n'Vector' 'Bit' is up to 3500x faster than 'Vector' 'Bool'.\n\n=== Thread safety\n\n* \"Data.Bit\" is faster, but writes and flips are not thread-safe.\nThis is because naive updates are not atomic:\nthey read the whole word from memory,\nthen modify a bit, then write the whole word back.\nConcurrently modifying non-intersecting slices of the same underlying array\nmay also lead to unexpected results, since they can share a word in memory.\n* \"Data.Bit.ThreadSafe\" is slower (usually 10-20%),\nbut writes and flips are thread-safe.\nAdditionally, concurrently modifying non-intersecting slices of the same underlying array\nworks as expected. However, operations that affect multiple elements are not\nguaranteed to be atomic.\n\n=== Similar packages\n\n* <https://hackage.haskell.org/package/bv bv> and\n<https://hackage.haskell.org/package/bv-little bv-little>\ndo not offer mutable vectors.\n\n* <https://hackage.haskell.org/package/array array>\nis memory-efficient for 'Bool', but lacks\na handy 'Vector' interface and is not thread-safe.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."ghc-bignum" or (errorHandler.buildDepError "ghc-bignum"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "bitvec-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bitvec" or (errorHandler.buildDepError "bitvec"))
            (hsPkgs."ghc-bignum" or (errorHandler.buildDepError "ghc-bignum"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."quickcheck-classes-base" or (errorHandler.buildDepError "quickcheck-classes-base"))
            (hsPkgs."quickcheck-classes" or (errorHandler.buildDepError "quickcheck-classes"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bitvec-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bitvec" or (errorHandler.buildDepError "bitvec"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."ghc-bignum" or (errorHandler.buildDepError "ghc-bignum"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/bitvec-1.1.6.0.tar.gz";
      sha256 = "1a42d33ce341973f4e4f3f0e10d00760056a0aca0e2a57180994bf2ac26c4e2b";
    });
  }) // {
    package-description-override = "name: bitvec\nversion: 1.1.6.0\ncabal-version: 2.0\nbuild-type: Simple\nlicense: BSD3\nlicense-file: LICENSE\ncopyright: 2019-2022 Andrew Lelechenko, 2012-2016 James Cook\nmaintainer: Andrew Lelechenko <andrew.lelechenko@gmail.com>\nhomepage: https://github.com/Bodigrim/bitvec\nsynopsis: Space-efficient bit vectors\ndescription:\n  A newtype over 'Bool' with a better 'Vector' instance: 8x less memory, up to 3500x faster.\n  .\n  The <https://hackage.haskell.org/package/vector vector>\n  package represents unboxed arrays of 'Bool's\n  spending 1 byte (8 bits) per boolean.\n  This library provides a newtype wrapper 'Bit' and a custom instance\n  of an unboxed 'Vector', which packs bits densely,\n  achieving an __8x smaller memory footprint.__\n  The performance stays mostly the same;\n  the most significant degradation happens for random writes\n  (up to 10% slower).\n  On the other hand, for certain bulk bit operations\n  'Vector' 'Bit' is up to 3500x faster than 'Vector' 'Bool'.\n  .\n  === Thread safety\n  .\n  * \"Data.Bit\" is faster, but writes and flips are not thread-safe.\n    This is because naive updates are not atomic:\n    they read the whole word from memory,\n    then modify a bit, then write the whole word back.\n    Concurrently modifying non-intersecting slices of the same underlying array\n    may also lead to unexpected results, since they can share a word in memory.\n  * \"Data.Bit.ThreadSafe\" is slower (usually 10-20%),\n    but writes and flips are thread-safe.\n    Additionally, concurrently modifying non-intersecting slices of the same underlying array\n    works as expected. However, operations that affect multiple elements are not\n    guaranteed to be atomic.\n  .\n  === Similar packages\n  .\n  * <https://hackage.haskell.org/package/bv bv> and\n    <https://hackage.haskell.org/package/bv-little bv-little>\n    do not offer mutable vectors.\n  .\n  * <https://hackage.haskell.org/package/array array>\n    is memory-efficient for 'Bool', but lacks\n    a handy 'Vector' interface and is not thread-safe.\n\ncategory: Data, Bit Vectors\nauthor: Andrew Lelechenko <andrew.lelechenko@gmail.com>,\n        James Cook <mokus@deepbondi.net>\n\ntested-with: GHC ==9.0.2 GHC ==9.2.8 GHC ==9.4.8 GHC ==9.6.7 GHC ==9.8.4 GHC ==9.10.3 GHC ==9.12.2 GHC ==9.14.1\nextra-doc-files:\n  changelog.md\n  README.md\n\nsource-repository head\n  type: git\n  location: https://github.com/Bodigrim/bitvec.git\n\nflag simd\n  description:\n    Use a C SIMD implementation for the ultimate performance of `zipBits`, `invertBits` and `countBits`.\n    Disable this flag if there are problems with the C FFI.\n  default: True\n  manual: True\n\nlibrary\n  exposed-modules:\n    Data.Bit\n    Data.Bit.ThreadSafe\n  build-depends:\n    base >=4.15 && <5,\n    bytestring >=0.10 && <0.13,\n    deepseq <1.6,\n    ghc-bignum <1.5,\n    primitive >=0.5 && <0.10,\n    vector >=0.13 && <0.14\n  default-language: Haskell2010\n  hs-source-dirs: src\n  other-modules:\n    Data.Bit.F2Poly\n    Data.Bit.F2PolyTS\n    Data.Bit.Immutable\n    Data.Bit.ImmutableTS\n    Data.Bit.Internal\n    Data.Bit.InternalTS\n    Data.Bit.Mutable\n    Data.Bit.MutableTS\n    Data.Bit.PdepPext\n    Data.Bit.Utils\n  ghc-options: -O2 -Wall -Wcompat\n  include-dirs: src\n  if flag(simd) && !arch(javascript) && !arch(wasm32)\n    c-sources: cbits/bitvec_simd.c\n    cc-options: -fopenmp-simd\n    cpp-options: -DUseSIMD\n    other-modules:\n      Data.Bit.SIMD\n\ntest-suite bitvec-tests\n  type: exitcode-stdio-1.0\n  main-is: Main.hs\n  build-depends:\n    base,\n    bitvec,\n    ghc-bignum,\n    primitive >=0.5 && <0.10,\n    quickcheck-classes-base <0.7,\n    quickcheck-classes >=0.6.1 && <0.7,\n    vector >=0.11,\n    tasty <1.6,\n    tasty-quickcheck <0.12\n  default-language: Haskell2010\n  hs-source-dirs: test\n  other-modules:\n    Support\n    Tests.Conc\n    Tests.F2Poly\n    Tests.MVector\n    Tests.MVectorTS\n    Tests.SetOps\n    Tests.SetOpsTS\n    Tests.Vector\n  ghc-options: -Wall -Wcompat\n  if !arch(wasm32)\n    ghc-options: -threaded -rtsopts\n  include-dirs: test\n\nbenchmark bitvec-bench\n  build-depends:\n    base,\n    bitvec,\n    containers <0.9,\n    ghc-bignum,\n    random <1.4,\n    tasty,\n    tasty-bench >=0.4 && <0.6,\n    vector\n  type: exitcode-stdio-1.0\n  main-is: Bench.hs\n  default-language: Haskell2010\n  hs-source-dirs: bench\n  other-modules:\n    Bench.BitIndex\n    Bench.Common\n    Bench.GCD\n    Bench.Invert\n    Bench.Intersection\n    Bench.Product\n    Bench.RandomFlip\n    Bench.RandomRead\n    Bench.RandomWrite\n    Bench.Remainder\n    Bench.Reverse\n    Bench.Sum\n    Bench.Union\n  ghc-options: -O2 -Wall -Wcompat\n";
  }