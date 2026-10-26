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
    flags = { bounds-checking-enabled = false; };
    package = {
      specVersion = "2.2";
      identifier = { name = "hw-prim"; version = "0.6.3.2"; };
      license = "BSD-3-Clause";
      copyright = "2016-2021 John Ky";
      maintainer = "newhoggy@gmail.com";
      author = "John Ky";
      homepage = "http://github.com/haskell-works/hw-prim#readme";
      url = "";
      synopsis = "Primitive functions and data types";
      description = "Primitive functions and data types.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."mmap" or (errorHandler.buildDepError "mmap"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "hw-prim-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hw-hspec-hedgehog" or (errorHandler.buildDepError "hw-hspec-hedgehog"))
            (hsPkgs."hw-prim" or (errorHandler.buildDepError "hw-prim"))
            (hsPkgs."mmap" or (errorHandler.buildDepError "mmap"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
        "doctest" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."doctest" or (errorHandler.buildDepError "doctest"))
            (hsPkgs."doctest-discover" or (errorHandler.buildDepError "doctest-discover"))
            (hsPkgs."hw-prim" or (errorHandler.buildDepError "hw-prim"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.doctest-discover.components.exes.doctest-discover or (pkgs.pkgsBuildBuild.doctest-discover or (errorHandler.buildToolDepError "doctest-discover:doctest-discover")))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."hw-prim" or (errorHandler.buildDepError "hw-prim"))
            (hsPkgs."mmap" or (errorHandler.buildDepError "mmap"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hw-prim-0.6.3.2.tar.gz";
      sha256 = "1fa05fdc46c72ed4b28aabcee69695ce810d451bbd263fbe75f94b179e20441d";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\r\n\r\nname:                   hw-prim\r\nversion:                0.6.3.2\r\nx-revision: 4\r\nsynopsis:               Primitive functions and data types\r\ndescription:            Primitive functions and data types.\r\ncategory:               Data\r\nstability:              Experimental\r\nhomepage:               http://github.com/haskell-works/hw-prim#readme\r\nbug-reports:            https://github.com/haskell-works/hw-prim/issues\r\nauthor:                 John Ky\r\nmaintainer:             newhoggy@gmail.com\r\ncopyright:              2016-2021 John Ky\r\nlicense:                BSD-3-Clause\r\nlicense-file:           LICENSE\r\ntested-with:            GHC == 9.12.1, GHC == 9.10.1, GHC == 9.8.4, GHC == 9.6.6, GHC == 9.4.8, GHC == 9.2.8, GHC == 9.0.2, GHC == 8.10.7, GHC == 8.8.4\r\nbuild-type:             Simple\r\nextra-source-files:     README.md\r\n\r\nsource-repository head\r\n  type:                 git\r\n  location:             https://github.com/haskell-works/hw-prim\r\n\r\nflag bounds-checking-enabled\r\n  description:          Enable bmi2 instruction set\r\n  manual:               False\r\n  default:              False\r\n\r\ncommon base                       { build-depends: base                       >= 4.11       && < 5      }\r\n\r\ncommon bytestring                 { build-depends: bytestring                 >= 0.9        && < 0.13   }\r\ncommon criterion                  { build-depends: criterion                  >= 1.2        && < 1.7    }\r\ncommon deepseq                    { build-depends: deepseq                    >= 1.4        && < 1.6    }\r\ncommon directory                  { build-depends: directory                  >= 1.2        && < 1.4    }\r\ncommon doctest                    { build-depends: doctest                    >= 0.16.2     && < 0.26   }\r\ncommon doctest-discover           { build-depends: doctest-discover           >= 0.2        && < 0.3    }\r\ncommon exceptions                 { build-depends: exceptions                 >= 0.8        && < 0.11   }\r\ncommon ghc-prim                   { build-depends: ghc-prim                   >= 0.5        && < 0.14   }\r\ncommon hedgehog                   { build-depends: hedgehog                   >= 1.0        && < 1.8    }\r\ncommon hspec                      { build-depends: hspec                      >= 2.4        && < 3      }\r\ncommon hw-hspec-hedgehog          { build-depends: hw-hspec-hedgehog          >= 0.1        && < 0.2    }\r\ncommon mmap                       { build-depends: mmap                       >= 0.5        && < 0.6    }\r\ncommon QuickCheck                 { build-depends: QuickCheck                 >= 2.10       && < 2.19   }\r\ncommon semigroups                 { build-depends: semigroups                 >= 0.8.4      && < 0.21   }\r\ncommon transformers               { build-depends: transformers               >= 0.4        && < 0.7    }\r\ncommon unliftio-core              { build-depends: unliftio-core              >= 0.1.2.0    && < 0.3    }\r\ncommon vector                     { build-depends: vector                     >= 0.12       && < 0.14   }\r\n\r\ncommon hw-prim\r\n  build-depends:        hw-prim\r\n\r\ncommon config\r\n  default-language:     Haskell2010\r\n  ghc-options:          -Wall -O2 -msse4.2\r\n  if flag(bounds-checking-enabled)\r\n    cpp-options:        -DBOUNDS_CHECKING_ENABLED\r\n\r\nlibrary\r\n  import:               base, config\r\n                      , bytestring\r\n                      , deepseq\r\n                      , ghc-prim\r\n                      , mmap\r\n                      , transformers\r\n                      , unliftio-core\r\n                      , vector\r\n  exposed-modules:      HaskellWorks.Control.Monad.Lazy\r\n                        HaskellWorks.Data.AtIndex\r\n                        HaskellWorks.Data.Branchless\r\n                        HaskellWorks.Data.ByteString\r\n                        HaskellWorks.Data.ByteString.Builder\r\n                        HaskellWorks.Data.ByteString.Lazy\r\n                        HaskellWorks.Data.Char\r\n                        HaskellWorks.Data.Char.IsChar\r\n                        HaskellWorks.Data.Concat\r\n                        HaskellWorks.Data.Cons\r\n                        HaskellWorks.Data.Container\r\n                        HaskellWorks.Data.Decode\r\n                        HaskellWorks.Data.Drop\r\n                        HaskellWorks.Data.Empty\r\n                        HaskellWorks.Data.Filter\r\n                        HaskellWorks.Data.Foldable\r\n                        HaskellWorks.Data.FromByteString\r\n                        HaskellWorks.Data.FromForeignRegion\r\n                        HaskellWorks.Data.FromString\r\n                        HaskellWorks.Data.Generate\r\n                        HaskellWorks.Data.Head\r\n                        HaskellWorks.Data.Length\r\n                        HaskellWorks.Data.Naive\r\n                        HaskellWorks.Data.Null\r\n                        HaskellWorks.Data.Ops\r\n                        HaskellWorks.Data.Positioning\r\n                        HaskellWorks.Data.Product\r\n                        HaskellWorks.Data.Search\r\n                        HaskellWorks.Data.Sign\r\n                        HaskellWorks.Data.Snoc\r\n                        HaskellWorks.Data.Take\r\n                        HaskellWorks.Data.TreeCursor\r\n                        HaskellWorks.Data.Uncons\r\n                        HaskellWorks.Data.Unsign\r\n                        HaskellWorks.Data.Unsnoc\r\n                        HaskellWorks.Data.Vector.AsVector64\r\n                        HaskellWorks.Data.Vector.AsVector64ns\r\n                        HaskellWorks.Data.Vector.AsVector64s\r\n                        HaskellWorks.Data.Vector.AsVector8\r\n                        HaskellWorks.Data.Vector.AsVector8ns\r\n                        HaskellWorks.Data.Vector.AsVector8s\r\n                        HaskellWorks.Data.Vector.BoxedVectorLike\r\n                        HaskellWorks.Data.Vector.Storable\r\n                        HaskellWorks.Data.Vector.StorableVectorLike\r\n                        HaskellWorks.Data.Word\r\n                        HaskellWorks.Foreign\r\n  other-modules:        Paths_hw_prim\r\n  autogen-modules:      Paths_hw_prim\r\n  hs-source-dirs:       src\r\n\r\ntest-suite hw-prim-test\r\n  import:               base, config\r\n                      , QuickCheck\r\n                      , bytestring\r\n                      , directory\r\n                      , exceptions\r\n                      , hedgehog\r\n                      , hspec\r\n                      , hw-hspec-hedgehog\r\n                      , hw-prim\r\n                      , mmap\r\n                      , transformers\r\n                      , vector\r\n  type:                 exitcode-stdio-1.0\r\n  main-is:              Spec.hs\r\n  other-modules:        HaskellWorks.Data.ByteStringSpec\r\n                        HaskellWorks.Data.FoldableSpec\r\n                        HaskellWorks.Data.FromByteStringSpec\r\n                        HaskellWorks.Data.FromForeignRegionSpec\r\n                        HaskellWorks.Data.SearchSpec\r\n                        HaskellWorks.Data.Vector.AsVector64nsSpec\r\n                        HaskellWorks.Data.Vector.AsVector64sSpec\r\n                        HaskellWorks.Data.Vector.AsVector8nsSpec\r\n                        HaskellWorks.Data.Vector.AsVector8sSpec\r\n                        HaskellWorks.Data.Vector.StorableSpec\r\n  hs-source-dirs:       test\r\n  ghc-options:          -threaded -rtsopts -with-rtsopts=-N\r\n  build-tool-depends:   hspec-discover:hspec-discover\r\n\r\nbenchmark bench\r\n  import:               base, config\r\n                      , bytestring\r\n                      , criterion\r\n                      , hw-prim\r\n                      , mmap\r\n                      , transformers\r\n                      , vector\r\n  type:                 exitcode-stdio-1.0\r\n  main-is:              Main.hs\r\n  hs-source-dirs:       bench\r\n  build-depends:        hw-prim\r\n\r\ntest-suite doctest\r\n  import:               base, config\r\n                      , doctest\r\n                      , doctest-discover\r\n                      , hw-prim\r\n  default-language:     Haskell2010\r\n  type:                 exitcode-stdio-1.0\r\n  ghc-options:          -threaded -rtsopts -with-rtsopts=-N\r\n  main-is:              DoctestDriver.hs\r\n  HS-Source-Dirs:       doctest\r\n  build-tool-depends:   doctest-discover:doctest-discover\r\n";
  }