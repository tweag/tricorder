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
      specVersion = "2.0";
      identifier = { name = "generic-lens-core"; version = "2.3.0.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "kiss.csongor.kiss@gmail.com";
      author = "Csongor Kiss";
      homepage = "https://github.com/kcsongor/generic-lens";
      url = "";
      synopsis = "Generically derive traversals, lenses and prisms.";
      description = "This library uses GHC.Generics to derive efficient optics (traversals, lenses and prisms) for algebraic data types in a type-directed way, with a focus on good type inference and error messages when possible.\n\nThis package is the shared internal logic of the\n@<https://hackage.haskell.org/package/generic-lens generic-lens>@\nand\n@<https://hackage.haskell.org/package/generic-optics generic-optics>@\nlibraries.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."indexed-profunctors" or (errorHandler.buildDepError "indexed-profunctors"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/generic-lens-core-2.3.0.0.tar.gz";
      sha256 = "1d31236d072e408e59bfa1dd88659293646ee381f639f33b6a49bce48d525ae0";
    });
  }) // {
    package-description-override = "cabal-version:        2.0\nname:                 generic-lens-core\nversion:              2.3.0.0\nsynopsis:             Generically derive traversals, lenses and prisms.\ndescription:          This library uses GHC.Generics to derive efficient optics (traversals, lenses and prisms) for algebraic data types in a type-directed way, with a focus on good type inference and error messages when possible.\n                      .\n                      This package is the shared internal logic of the\n                      @<https://hackage.haskell.org/package/generic-lens generic-lens>@\n                      and\n                      @<https://hackage.haskell.org/package/generic-optics generic-optics>@\n                      libraries.\n\nhomepage:             https://github.com/kcsongor/generic-lens\nlicense:              BSD3\nlicense-file:         LICENSE\nauthor:               Csongor Kiss\nmaintainer:           kiss.csongor.kiss@gmail.com\ncategory:             Generics, Records, Lens\nbuild-type:           Simple\n\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.2\n  GHC == 9.10.2\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n\nextra-doc-files:      ChangeLog.md\n\nlibrary\n  exposed-modules:    Data.Generics.Internal.GenericN\n\n                    , Data.Generics.Internal.Profunctor.Lens\n                    , Data.Generics.Internal.Profunctor.Prism\n                    , Data.Generics.Internal.Profunctor.Iso\n\n                    , Data.Generics.Internal.VL.Traversal\n\n                    , Data.GenericLens.Internal\n\n                    , Data.Generics.Internal.Families\n                    , Data.Generics.Internal.Families.Changing\n                    , Data.Generics.Internal.Families.Collect\n                    , Data.Generics.Internal.Families.Has\n                    , Data.Generics.Internal.Errors\n                    , Data.Generics.Internal.Void\n\n                    , Data.Generics.Internal.Wrapped\n\n                    , Data.Generics.Sum.Internal.Constructors\n                    , Data.Generics.Sum.Internal.Typed\n                    , Data.Generics.Sum.Internal.Subtype\n\n                    , Data.Generics.Product.Internal.Param\n                    , Data.Generics.Product.Internal.Types\n\n                    , Data.Generics.Product.Internal.Fields\n                    , Data.Generics.Product.Internal.Typed\n                    , Data.Generics.Product.Internal.Positions\n                    , Data.Generics.Product.Internal.GLens\n                    , Data.Generics.Product.Internal.Subtype\n\n                    , Data.Generics.Product.Internal.HList\n\n  build-depends:      base        >= 4.11 && < 5\n                    , text        >= 1.2 && < 1.3 || >= 2.0 && < 2.2\n                    , indexed-profunctors >= 0.1 && < 1\n\n  hs-source-dirs:     src\n  default-language:   Haskell2010\n  default-extensions: TypeOperators\n  ghc-options:        -Wall\n\nsource-repository head\n  type:               git\n  location:           https://github.com/kcsongor/generic-lens\n";
  }