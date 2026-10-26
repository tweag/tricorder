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
    flags = {
      boundschecks = true;
      unsafechecks = false;
      internalchecks = false;
      bench = true;
      llvm = false;
    };
    package = {
      specVersion = "1.10";
      identifier = { name = "vector-algorithms"; version = "0.9.1.0"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2008,2009,2010,2011,2012,2013,2014,2015 Dan Doel\n(c) 2015 Tim Baumann";
      maintainer = "Dan Doel <dan.doel@gmail.com>\nErik de Castro Lopo <erikd@mega-nerd.com>";
      author = "Dan Doel";
      homepage = "https://github.com/erikd/vector-algorithms/";
      url = "";
      synopsis = "Efficient algorithms for vector arrays";
      description = "Efficient algorithms for sorting vector arrays. At some stage\nother vector algorithms may be added.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bitvec" or (errorHandler.buildDepError "bitvec"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
        ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "7.8")) (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"));
        buildable = true;
      };
      tests = {
        "properties" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."vector-algorithms" or (errorHandler.buildDepError "vector-algorithms"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "simple-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."mwc-random" or (errorHandler.buildDepError "mwc-random"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."vector-algorithms" or (errorHandler.buildDepError "vector-algorithms"))
          ];
          buildable = if !flags.bench then false else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/vector-algorithms-0.9.1.0.tar.gz";
      sha256 = "d2b674676802670d8a682b357da6b6b5741b4a33b191f0ffe5f2b2bc40558eb2";
    });
  }) // {
    package-description-override = "cabal-version:     >= 1.10\r\nname:              vector-algorithms\r\nversion:           0.9.1.0\r\nx-revision: 1\r\nlicense:           BSD3\r\nlicense-file:      LICENSE\r\nauthor:            Dan Doel\r\nmaintainer:        Dan Doel <dan.doel@gmail.com>\r\n                   Erik de Castro Lopo <erikd@mega-nerd.com>\r\ncopyright:         (c) 2008,2009,2010,2011,2012,2013,2014,2015 Dan Doel\r\n                   (c) 2015 Tim Baumann\r\nhomepage:          https://github.com/erikd/vector-algorithms/\r\ncategory:          Data\r\nsynopsis:          Efficient algorithms for vector arrays\r\ndescription:       Efficient algorithms for sorting vector arrays. At some stage\r\n                   other vector algorithms may be added.\r\nbuild-type:        Simple\r\n\r\nextra-source-files: CHANGELOG.md\r\n\r\ntested-with:\r\n  GHC == 9.12.1\r\n  GHC == 9.10.1\r\n  GHC == 9.8.2\r\n  GHC == 9.6.3\r\n  GHC == 9.4.7\r\n  GHC == 9.2.8\r\n  GHC == 9.0.2\r\n  GHC == 8.10.7\r\n  GHC == 8.8.4\r\n  GHC == 8.6.5\r\n  GHC == 8.4.4\r\n  GHC == 8.2.2\r\n\r\nflag BoundsChecks\r\n  description: Enable bounds checking\r\n  default: True\r\n\r\nflag UnsafeChecks\r\n  description: Enable bounds checking in unsafe operations at the cost of a\r\n               significant performance penalty.\r\n  default: False\r\n\r\nflag InternalChecks\r\n  description: Enable internal consistency checks at the cost of a\r\n               significant performance penalty.\r\n  default: False\r\n\r\nflag bench\r\n  description: Build a benchmarking program to test vector-algorithms\r\n               performance\r\n  default: True\r\n\r\n-- flag dump-simpl\r\n--   description: Dumps the simplified core during compilation\r\n--   default: False\r\n\r\nflag llvm\r\n  description: Build using llvm\r\n  default: False\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/erikd/vector-algorithms/\r\n\r\nlibrary\r\n  hs-source-dirs: src\r\n  default-language: Haskell2010\r\n\r\n  build-depends: base >= 4.8 && < 5,\r\n                 bitvec >= 1.0 && < 1.2,\r\n                 vector >= 0.6 && < 0.14,\r\n                 primitive >= 0.6.2.0 && < 0.10,\r\n                 bytestring >= 0.9 && < 1\r\n\r\n  if ! impl (ghc >= 7.8)\r\n    build-depends: tagged >= 0.4 && < 0.9\r\n\r\n  exposed-modules:\r\n    Data.Vector.Algorithms\r\n    Data.Vector.Algorithms.Optimal\r\n    Data.Vector.Algorithms.Insertion\r\n    Data.Vector.Algorithms.Intro\r\n    Data.Vector.Algorithms.Merge\r\n    Data.Vector.Algorithms.Radix\r\n    Data.Vector.Algorithms.Search\r\n    Data.Vector.Algorithms.Heap\r\n    Data.Vector.Algorithms.AmericanFlag\r\n    Data.Vector.Algorithms.Tim\r\n\r\n  other-modules:\r\n    Data.Vector.Algorithms.Common\r\n\r\n  ghc-options:\r\n    -funbox-strict-fields\r\n\r\n  -- Cabal/Hackage complains about these\r\n  -- if flag(dump-simpl)\r\n  --   ghc-options: -ddump-simpl -ddump-to-file\r\n\r\n  if flag(llvm)\r\n    ghc-options: -fllvm\r\n\r\n  include-dirs:\r\n    include\r\n\r\n  install-includes:\r\n    vector.h\r\n\r\n  if flag(BoundsChecks)\r\n    cpp-options: -DVECTOR_BOUNDS_CHECKS\r\n\r\n  if flag(UnsafeChecks)\r\n    cpp-options: -DVECTOR_UNSAFE_CHECKS\r\n\r\n  if flag(InternalChecks)\r\n    cpp-options: -DVECTOR_INTERNAL_CHECKS\r\n\r\nbenchmark simple-bench\r\n  hs-source-dirs: bench/simple\r\n  type: exitcode-stdio-1.0\r\n  default-language: Haskell2010\r\n\r\n  if !flag(bench)\r\n    buildable: False\r\n\r\n  main-is: Main.hs\r\n\r\n  other-modules:\r\n    Blocks\r\n\r\n  build-depends: base, mwc-random, vector, vector-algorithms\r\n  ghc-options: -Wall\r\n\r\n  -- Cabal/Hackage complains about these\r\n  -- if flag(dump-simpl)\r\n  --   ghc-options: -ddump-simpl -ddump-to-file\r\n\r\n  if flag(llvm)\r\n    ghc-options: -fllvm\r\n\r\ntest-suite properties\r\n  hs-source-dirs: tests/properties\r\n  type: exitcode-stdio-1.0\r\n  main-is: Tests.hs\r\n  default-language: Haskell2010\r\n\r\n  other-modules:\r\n    Optimal\r\n    Properties\r\n    Util\r\n\r\n  build-depends:\r\n    base >= 4.9,\r\n    bytestring,\r\n    containers,\r\n    QuickCheck > 2.9 && < 2.19,\r\n    vector,\r\n    vector-algorithms\r\n\r\n  if flag(llvm)\r\n    ghc-options: -fllvm\r\n";
  }