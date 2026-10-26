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
      specVersion = "2.2";
      identifier = { name = "primitive-unlifted"; version = "2.2.0.0"; };
      license = "BSD-3-Clause";
      copyright = "2019 Andrew Martin";
      maintainer = "andrew.thaddeus@gmail.com";
      author = "Andrew Martin";
      homepage = "https://github.com/haskell-primitive/primitive-unlifted";
      url = "";
      synopsis = "Primitive GHC types with unlifted types inside";
      description = "Primitive GHC types with unlifted types inside. There used\nto be a module named `Data.Primitive.UnliftedArray` in the\n`primitive` library. However, it turns out that it is impossible\nto write such an API safely in versions of GHC before 8.10.1, thanks\nto some nasty interactions between unsafe coercions and the foreign\nfunction interface. This package also uses a somewhat different,\nand more flexible, approach than that module did.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."text-short" or (errorHandler.buildDepError "text-short"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."primitive-unlifted" or (errorHandler.buildDepError "primitive-unlifted"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."quickcheck-classes-base" or (errorHandler.buildDepError "quickcheck-classes-base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/primitive-unlifted-2.2.0.0.tar.gz";
      sha256 = "c9ec46305a1c2ade05c8399e3eeb2b56cb859692d539b4f7fd4485dbca06211b";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\nname: primitive-unlifted\nversion: 2.2.0.0\nsynopsis: Primitive GHC types with unlifted types inside\ndescription:\n  Primitive GHC types with unlifted types inside. There used\n  to be a module named `Data.Primitive.UnliftedArray` in the\n  `primitive` library. However, it turns out that it is impossible\n  to write such an API safely in versions of GHC before 8.10.1, thanks\n  to some nasty interactions between unsafe coercions and the foreign\n  function interface. This package also uses a somewhat different,\n  and more flexible, approach than that module did.\nhomepage: https://github.com/haskell-primitive/primitive-unlifted\nbug-reports: https://github.com/haskell-primitive/primitive-unlifted/issues\nlicense: BSD-3-Clause\nlicense-file: LICENSE\nauthor: Andrew Martin\nmaintainer: andrew.thaddeus@gmail.com\ncopyright: 2019 Andrew Martin\ncategory: Data\nextra-source-files: CHANGELOG.md\ntested-with: GHC == 9.4.5\n\nlibrary\n  exposed-modules:\n    Data.Primitive.Unlifted.Class\n    Data.Primitive.Unlifted.Array\n    Data.Primitive.Unlifted.SmallArray\n    Data.Primitive.Unlifted.SmallArray.ST\n    Data.Primitive.Unlifted.SmallArray.Primops\n    Data.Primitive.Unlifted.Array.ST\n    Data.Primitive.Unlifted.Array.Primops\n    Data.Primitive.Unlifted.MutVar.Primops\n    Data.Primitive.Unlifted.MutVar.ST\n    Data.Primitive.Unlifted.MutVar\n    Data.Primitive.Unlifted.Box\n    Data.Primitive.Unlifted.Weak\n    Data.Primitive.Unlifted.Weak.IO\n    Data.Primitive.Unlifted.Weak.Primops\n    Data.Primitive.TArray.Classic\n    Data.Primitive.Unlifted.MVar\n    Data.Primitive.Unlifted.MVar.ST\n    Data.Primitive.Unlifted.MVar.Primops\n    Data.Primitive.Unlifted.Type\n  build-depends:\n    , base >=4.17.1.0 && <5\n    , bytestring >=0.10.8.2 && <0.13\n    , primitive >= 0.7 && <0.10\n    , text-short >=0.1.3 && <0.2\n    , array\n  hs-source-dirs: src\n  ghc-options: -Wall -O2\n  default-language: Haskell2010\n\ntest-suite test\n  type: exitcode-stdio-1.0\n  hs-source-dirs: test\n  main-is: Main.hs\n  build-depends:\n    , base\n    , primitive-unlifted\n    , primitive >=0.9\n    , quickcheck-classes-base\n    , QuickCheck\n    , tasty-quickcheck\n    , tasty\n    , stm\n  ghc-options: -Wall -O2\n  default-language: Haskell2010\n\nsource-repository head\n  type:\n    git\n  location:\n    https://github.com/haskell-primitive/primitive-unlifted.git\n";
  }