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
    flags = { debug = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "enummapset"; version = "0.7.3.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Mikolaj Konarski <mikolaj.konarski@funktory.com>";
      author = "Michal Terepeta and others";
      homepage = "https://github.com/Mikolaj/enummapset";
      url = "";
      synopsis = "IntMap and IntSet with Enum keys/elements.";
      description = "This package contains simple wrappers around 'Data.IntMap' and\n'Data.IntSet' with 'Enum' keys and elements respectively.\nEspecially useful for 'Int's wrapped with `newtype`.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8.0") (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"));
        buildable = true;
      };
      tests = {
        "intset-properties" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."test-framework" or (errorHandler.buildDepError "test-framework"))
            (hsPkgs."test-framework-hunit" or (errorHandler.buildDepError "test-framework-hunit"))
            (hsPkgs."test-framework-quickcheck2" or (errorHandler.buildDepError "test-framework-quickcheck2"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8.0") (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"));
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/enummapset-0.7.3.0.tar.gz";
      sha256 = "74c805415005f065379d644b2f2530d297b1cff650e5ef269a479220afdf7070";
    });
  }) // {
    package-description-override = "name:           enummapset\r\nversion:        0.7.3.0\r\nx-revision: 2\r\nsynopsis:       IntMap and IntSet with Enum keys/elements.\r\ndescription:    This package contains simple wrappers around 'Data.IntMap' and\r\n                'Data.IntSet' with 'Enum' keys and elements respectively.\r\n                Especially useful for 'Int's wrapped with `newtype`.\r\nhomepage:       https://github.com/Mikolaj/enummapset\r\nbug-reports:    https://github.com/Mikolaj/enummapset/issues\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\ntested-with:\r\n    GHC==8.4.4\r\n  , GHC==8.6.5\r\n  , GHC==8.8.4\r\n  , GHC==8.10.7\r\n  , GHC==9.0.2\r\n  , GHC==9.2.8\r\n  , GHC==9.4.8\r\n  , GHC==9.6.6\r\n  , GHC==9.8.2\r\nauthor:         Michal Terepeta and others\r\nmaintainer:     Mikolaj Konarski <mikolaj.konarski@funktory.com>\r\ncategory:       Data Structures\r\nbuild-type:     Simple\r\n\r\ncabal-version:  >=1.10\r\n\r\nextra-source-files: README.md\r\n\r\nsource-repository head\r\n  type:         git\r\n  location:     https://github.com/Mikolaj/enummapset.git\r\n\r\nflag debug\r\n  description:  Debug build (more warnings, etc.)\r\n  default:      False\r\n\r\nLibrary\r\n  exposed-modules:\r\n    Data.EnumMap\r\n    Data.EnumMap.Lazy\r\n    Data.EnumMap.Strict\r\n    Data.EnumSet\r\n\r\n  other-modules:\r\n    Data.EnumMap.Base\r\n\r\n  build-depends:\r\n    base >= 4.6 && < 5,\r\n    aeson >= 1.3 && < 2.4,\r\n    containers >= 0.5.11 && < 0.9,\r\n    deepseq >= 1.2 && < 1.7\r\n\r\n  if impl(ghc < 8.0)\r\n    build-depends: semigroups >=0.1 && <1.0\r\n\r\n  if flag(debug)\r\n    ghc-options: -Wall\r\n\r\n  default-language: Haskell2010\r\n\r\n  other-extensions: CPP, BangPatterns,\r\n                    DataKinds, FlexibleContexts, FlexibleInstances,\r\n                    KindSignatures, TypeFamilies, UndecidableInstances\r\n\r\nTest-suite intset-properties\r\n  hs-source-dirs: tests, .\r\n  main-is: intset-properties.hs\r\n  other-modules:\r\n      Data.EnumSet\r\n      Data.EnumMap.Lazy\r\n      Data.EnumMap.Base\r\n      Data.EnumMap\r\n      IntSetValidity\r\n      Json\r\n  type: exitcode-stdio-1.0\r\n  cpp-options: -DTESTING\r\n\r\n  ghc-options: -O2\r\n  default-language: Haskell2010\r\n  other-extensions: CPP, BangPatterns,\r\n                    DataKinds, FlexibleContexts, FlexibleInstances,\r\n                    KindSignatures, TypeFamilies, UndecidableInstances\r\n\r\n  build-depends:\r\n    base >= 4.6 && < 5,\r\n    aeson,\r\n    array >= 0.4.0.0,\r\n    containers,\r\n    deepseq,\r\n    ghc-prim,\r\n\r\n    HUnit,\r\n    QuickCheck >= 2.7.1,\r\n    test-framework,\r\n    test-framework-hunit,\r\n    test-framework-quickcheck2\r\n\r\n  if impl(ghc < 8.0)\r\n    build-depends: semigroups\r\n";
  }