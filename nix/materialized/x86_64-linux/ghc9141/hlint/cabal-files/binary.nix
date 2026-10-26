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
      identifier = { name = "binary"; version = "0.8.9.3"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Lennart Kolmodin, Don Stewart <dons00@gmail.com>";
      author = "Lennart Kolmodin <kolmodin@gmail.com>";
      homepage = "https://github.com/kolmodin/binary";
      url = "";
      synopsis = "Binary serialisation for Haskell values using lazy ByteStrings";
      description = "Efficient, pure binary serialisation using lazy ByteStrings.\nHaskell values may be encoded to and from binary formats,\nwritten to disk as binary, or sent over the network.\nThe format used can be automatically generated, or\nyou can choose to implement a custom format if needed.\nSerialisation speeds of over 1 G\\/sec have been observed,\nso this library should be suitable for high performance\nscenarios.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.le "7.6") (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
        buildable = true;
      };
      tests = {
        "qc" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base-orphans" or (errorHandler.buildDepError "base-orphans"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."test-framework" or (errorHandler.buildDepError "test-framework"))
            (hsPkgs."test-framework-quickcheck2" or (errorHandler.buildDepError "test-framework-quickcheck2"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.le "7.6") (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
          buildable = true;
        };
        "read-write-file" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."Cabal" or (errorHandler.buildDepError "Cabal"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.le "7.6") (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.le "7.6") (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
          buildable = true;
        };
        "get" = {
          depends = [
            (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."cereal" or (errorHandler.buildDepError "cereal"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.le "7.6") (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
          buildable = true;
        };
        "put" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.le "7.6") (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
          buildable = true;
        };
        "generics-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."generic-deriving" or (errorHandler.buildDepError "generic-deriving"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.le "7.6") (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
          buildable = true;
        };
        "builder" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.le "7.6") (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/binary-0.8.9.3.tar.gz";
      sha256 = "977bc800fb22c85b2c257ef48c9a7236581e859dc76c7e6b7743f6ad55647bef";
    });
  }) // {
    package-description-override = "cabal-version:  3.0\n\n-- To run tests and binaries you'll need to rename the name of the library\n-- and all the local dependencies on it. If not, cabal is unable to come up\n-- with a build plan.\n--\n-- Try this;\n--   sed -i 's/\\(name:\\s*binary\\)/\\1-cabal-is-broken/' binary.cabal\n--   sed -i 's/\\(binary\\),/\\1-cabal-is-broken,/' binary.cabal\n\nname:            binary\nversion:         0.8.9.3\nlicense:         BSD-3-Clause\nlicense-file:    LICENSE\nauthor:          Lennart Kolmodin <kolmodin@gmail.com>\nmaintainer:      Lennart Kolmodin, Don Stewart <dons00@gmail.com>\nhomepage:        https://github.com/kolmodin/binary\ndescription:     Efficient, pure binary serialisation using lazy ByteStrings.\n                 Haskell values may be encoded to and from binary formats,\n                 written to disk as binary, or sent over the network.\n                 The format used can be automatically generated, or\n                 you can choose to implement a custom format if needed.\n                 Serialisation speeds of over 1 G\\/sec have been observed,\n                 so this library should be suitable for high performance\n                 scenarios.\nsynopsis:        Binary serialisation for Haskell values using lazy ByteStrings\ncategory:        Data, Parsing\nstability:       provisional\nbuild-type:      Simple\ntested-with:     GHC == 8.0.2, GHC ==8.2.2, GHC == 8.4.4, GHC == 8.6.5, GHC == 8.8.4, GHC == 8.10.7, GHC == 9.0.2, GHC == 9.2.6, GHC == 9.4.4, GHC == 9.6.3, GHC == 9.8.1\nextra-source-files:\n  tools/derive/*.hs\n-- from the benchmark 'bench'\nextra-source-files:\n  benchmarks/CBenchmark.h\nextra-doc-files:\n  README.md changelog.md docs/hcar/binary-Lb.tex\n\nsource-repository head\n  type: git\n  location: git://github.com/kolmodin/binary.git\n\nlibrary\n  build-depends:   base >= 4.5.0.0 && < 5, bytestring >= 0.10.4, containers, array\n  hs-source-dirs:  src\n  exposed-modules: Data.Binary,\n                   Data.Binary.Put,\n                   Data.Binary.Get,\n                   Data.Binary.Get.Internal,\n                   Data.Binary.Builder\n\n  other-modules:   Data.Binary.Class,\n                   Data.Binary.Internal,\n                   Data.Binary.Generic,\n                   Data.Binary.FloatCast\n  if impl(ghc <= 7.6)\n    -- prior to ghc-7.4 generics lived in ghc-prim\n    build-depends: ghc-prim\n\n  ghc-options:     -O2 -Wall -fliberate-case-threshold=1000\n\n  if impl(ghc >= 8.0)\n    ghc-options: -Wcompat -Wnoncanonical-monad-instances\n  default-language: Haskell2010\n\ntest-suite qc\n  type:  exitcode-stdio-1.0\n  hs-source-dirs: tests\n  main-is: QC.hs\n  other-modules:\n    Action\n    Arbitrary\n  build-depends:\n    base >= 4.5.0.0 && < 5,\n    base-orphans >=0.8.1 && <0.9,\n    binary,\n    bytestring >= 0.10.4,\n    random>=1.0.1.0,\n    test-framework,\n    test-framework-quickcheck2 >= 0.3,\n    QuickCheck >= 2.9\n\n  -- build dependencies from using binary source rather than depending on the library\n  build-depends: array, containers\n  ghc-options: -Wall -O2 -threaded\n  if impl(ghc <= 7.6)\n    -- prior to ghc-7.4 generics lived in ghc-prim\n    build-depends: ghc-prim\n  default-language: Haskell2010\n\n\ntest-suite read-write-file\n  type:  exitcode-stdio-1.0\n  hs-source-dirs: tests\n  main-is: File.hs\n  build-depends:\n    base >= 4.5.0.0 && < 5,\n    binary,\n    bytestring >= 0.10.4,\n    Cabal,\n    directory,\n    filepath,\n    HUnit\n\n  -- build dependencies from using binary source rather than depending on the library\n  build-depends: array, containers\n  ghc-options: -Wall\n  if impl(ghc <= 7.6)\n    -- prior to ghc-7.4 generics lived in ghc-prim\n    build-depends: ghc-prim\n  default-language: Haskell2010\n\n\nbenchmark bench\n  type: exitcode-stdio-1.0\n  hs-source-dirs: benchmarks\n  main-is: Benchmark.hs\n  other-modules:\n    MemBench\n  build-depends:\n    base >= 4.5.0.0 && < 5,\n    binary,\n    bytestring >= 0.10.4\n  -- build dependencies from using binary source rather than depending on the library\n  build-depends: array, containers\n  c-sources: benchmarks/CBenchmark.c\n  include-dirs: benchmarks\n  ghc-options: -O2\n  if impl(ghc <= 7.6)\n    -- prior to ghc-7.4 generics lived in ghc-prim\n    build-depends: ghc-prim\n  default-language: Haskell2010\n\n\nbenchmark get\n  type: exitcode-stdio-1.0\n  hs-source-dirs: benchmarks\n  main-is: Get.hs\n  build-depends:\n    attoparsec,\n    base >= 4.5.0.0 && < 5,\n    binary,\n    bytestring >= 0.10.4,\n    cereal,\n    criterion == 1.*,\n    deepseq,\n    mtl\n  -- build dependencies from using binary source rather than depending on the library\n  build-depends: array, containers\n  ghc-options: -O2 -Wall\n  if impl(ghc <= 7.6)\n    -- prior to ghc-7.4 generics lived in ghc-prim\n    build-depends: ghc-prim\n  default-language: Haskell2010\n\n\nbenchmark put\n  type: exitcode-stdio-1.0\n  hs-source-dirs: benchmarks\n  main-is: Put.hs\n  build-depends:\n    base >= 4.5.0.0 && < 5,\n    binary,\n    bytestring >= 0.10.4,\n    criterion == 1.*,\n    deepseq\n  -- build dependencies from using binary source rather than depending on the library\n  build-depends: array, containers\n  ghc-options: -O2 -Wall\n  if impl(ghc <= 7.6)\n    -- prior to ghc-7.4 generics lived in ghc-prim\n    build-depends: ghc-prim\n  default-language: Haskell2010\n\nbenchmark generics-bench\n  type: exitcode-stdio-1.0\n  hs-source-dirs: benchmarks\n  main-is: GenericsBench.hs\n  build-depends:\n    base >= 4.5.0.0 && < 5,\n    binary,\n    bytestring >= 0.10.4,\n    -- The benchmark already depended on 'generic-deriving' transitively. That's\n    -- what caused one of the problems, as both 'generic-deriving' and\n    -- 'GenericsBenchTypes' used to define 'instance Generic Version'.\n    generic-deriving >= 0.10,\n    directory,\n    filepath,\n    unordered-containers,\n    zlib,\n    criterion\n    \n  other-modules:\n    Cabal24\n    GenericsBenchCache\n    GenericsBenchTypes\n  -- build dependencies from using binary source rather than depending on the library\n  build-depends: array, containers\n  ghc-options: -O2 -Wall\n  if impl(ghc <= 7.6)\n    -- prior to ghc-7.4 generics lived in ghc-prim\n    build-depends: ghc-prim\n  default-language: Haskell2010\n\nbenchmark builder\n  type: exitcode-stdio-1.0\n  hs-source-dirs: benchmarks\n  main-is: Builder.hs\n  build-depends:\n    base >= 4.5.0.0 && < 5,\n    binary,\n    bytestring >= 0.10.4,\n    criterion == 1.*,\n    deepseq,\n    mtl\n  -- build dependencies from using binary source rather than depending on the library\n  build-depends: array, containers\n  ghc-options: -O2\n  if impl(ghc <= 7.6)\n    -- prior to ghc-7.4 generics lived in ghc-prim\n    build-depends: ghc-prim\n  default-language: Haskell2010\n";
  }