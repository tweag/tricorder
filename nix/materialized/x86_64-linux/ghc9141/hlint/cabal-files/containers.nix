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
      identifier = { name = "containers"; version = "0.7"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "libraries@haskell.org";
      author = "";
      homepage = "";
      url = "";
      synopsis = "Assorted concrete container types";
      description = "\nThis package contains efficient general-purpose implementations\nof various immutable container types including sets, maps, sequences,\ntrees, and graphs.\n\nFor a walkthrough of what this package provides with examples of common\noperations see the [containers\nintroduction](https://haskell-containers.readthedocs.io).\n\nThe declared cost of each operation is either worst-case or amortized, but\nremains valid even if structures are shared.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/containers-0.7.tar.gz";
      sha256 = "cf6902d4d27158f0b8643673a230a75c98169d388295f9b641686c83ce15e324";
    });
  }) // {
    package-description-override = "name: containers\nversion: 0.7\nlicense: BSD3\nlicense-file: LICENSE\nmaintainer: libraries@haskell.org\nbug-reports: https://github.com/haskell/containers/issues\nsynopsis: Assorted concrete container types\ncategory: Data Structures\ndescription:\n    .\n    This package contains efficient general-purpose implementations\n    of various immutable container types including sets, maps, sequences,\n    trees, and graphs.\n    .\n    For a walkthrough of what this package provides with examples of common\n    operations see the [containers\n    introduction](https://haskell-containers.readthedocs.io).\n    .\n    The declared cost of each operation is either worst-case or amortized, but\n    remains valid even if structures are shared.\n\nbuild-type: Simple\ncabal-version:  >=1.10\nextra-source-files:\n    include/containers.h\n    changelog.md\n    mkappend.hs\n\ntested-with:\n  GHC ==8.2.2 || ==8.4.4 || ==8.6.5 || ==8.8.4 || ==8.10.7 || ==9.0.2 || ==9.2.8 ||\n      ==9.4.5 || ==9.6.2 || ==9.8.1\n\nsource-repository head\n    type:     git\n    location: http://github.com/haskell/containers.git\n\nLibrary\n    default-language: Haskell2010\n    build-depends: base >= 4.10 && < 5, array >= 0.4.0.0, deepseq >= 1.2 && < 1.6, template-haskell\n    hs-source-dirs: src\n    ghc-options: -O2 -Wall -fwarn-incomplete-uni-patterns -fwarn-incomplete-record-updates\n\n    other-extensions: CPP, BangPatterns\n\n    exposed-modules:\n        Data.Containers.ListUtils\n        Data.IntMap\n        Data.IntMap.Lazy\n        Data.IntMap.Strict\n        Data.IntMap.Strict.Internal\n        Data.IntMap.Internal\n        Data.IntMap.Internal.Debug\n        Data.IntMap.Merge.Lazy\n        Data.IntMap.Merge.Strict\n        Data.IntSet.Internal\n        Data.IntSet\n        Data.Map\n        Data.Map.Lazy\n        Data.Map.Merge.Lazy\n        Data.Map.Strict.Internal\n        Data.Map.Strict\n        Data.Map.Merge.Strict\n        Data.Map.Internal\n        Data.Map.Internal.Debug\n        Data.Set.Internal\n        Data.Set\n        Data.Graph\n        Data.Sequence\n        Data.Sequence.Internal\n        Data.Sequence.Internal.Sorting\n        Data.Tree\n        Utils.Containers.Internal.BitUtil\n        Utils.Containers.Internal.BitQueue\n        Utils.Containers.Internal.StrictPair\n\n    other-modules:\n        Utils.Containers.Internal.Prelude\n        Utils.Containers.Internal.State\n        Utils.Containers.Internal.StrictMaybe\n        Utils.Containers.Internal.PtrEquality\n        Utils.Containers.Internal.Coercions\n    if impl(ghc)\n      other-modules:\n        Utils.Containers.Internal.TypeError\n        Data.Map.Internal.DeprecatedShowTree\n        Data.IntMap.Internal.DeprecatedDebug\n\n    include-dirs: include\n";
  }