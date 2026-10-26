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
      identifier = { name = "these"; version = "1.2.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "C. McCann, Oleg Grenrus";
      homepage = "https://github.com/haskellari/these";
      url = "";
      synopsis = "An either-or-both data type.";
      description = "This package provides a data type @These a b@ which can hold a value of either\ntype or values of each type. This is usually thought of as an \"inclusive or\"\ntype (contrasting @Either a b@ as \"exclusive or\") or as an \"outer join\" type\n(contrasting @(a, b)@ as \"inner join\").\n\n@\ndata These a b = This a | That b | These a b\n@\n\nSince version 1, this package was split into parts:\n\n* <https://hackage.haskell.org/package/semialign semialign> For @Align@ and @Zip@ type-classes.\n\n* <https://hackage.haskell.org/package/semialign-indexed semialign-indexed> For @SemialignWithIndex@ class, providing @ialignWith@ and @izipWith@.\n\n* <https://hackage.haskell.org/package/these-lens these-lens> For lens combinators.\n\n* <http://hackage.haskell.org/package/monad-chronicle monad-chronicle> For transformers variant of @These@.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."assoc" or (errorHandler.buildDepError "assoc"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
        ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "9.6")) (hsPkgs."foldable1-classes-compat" or (errorHandler.buildDepError "foldable1-classes-compat"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/these-1.2.1.tar.gz";
      sha256 = "17d6d933365edabf801a16842c1403bdd37cc5300faa2fcca980decdab22e4de";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\r\nname:               these\r\nversion:            1.2.1\r\nx-revision:         3\r\nsynopsis:           An either-or-both data type.\r\nhomepage:           https://github.com/haskellari/these\r\nlicense:            BSD3\r\nlicense-file:       LICENSE\r\nauthor:             C. McCann, Oleg Grenrus\r\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\r\ncategory:           Data, These\r\nbuild-type:         Simple\r\nextra-source-files: CHANGELOG.md\r\ndescription:\r\n  This package provides a data type @These a b@ which can hold a value of either\r\n  type or values of each type. This is usually thought of as an \"inclusive or\"\r\n  type (contrasting @Either a b@ as \"exclusive or\") or as an \"outer join\" type\r\n  (contrasting @(a, b)@ as \"inner join\").\r\n  .\r\n  @\r\n  data These a b = This a | That b | These a b\r\n  @\r\n  .\r\n  Since version 1, this package was split into parts:\r\n  .\r\n  * <https://hackage.haskell.org/package/semialign semialign> For @Align@ and @Zip@ type-classes.\r\n  .\r\n  * <https://hackage.haskell.org/package/semialign-indexed semialign-indexed> For @SemialignWithIndex@ class, providing @ialignWith@ and @izipWith@.\r\n  .\r\n  * <https://hackage.haskell.org/package/these-lens these-lens> For lens combinators.\r\n  .\r\n  * <http://hackage.haskell.org/package/monad-chronicle monad-chronicle> For transformers variant of @These@.\r\n\r\ntested-with:\r\n  GHC ==8.6.5\r\n   || ==8.8.4\r\n   || ==8.10.7\r\n   || ==9.0.2\r\n   || ==9.2.8\r\n   || ==9.4.8\r\n   || ==9.6.6\r\n   || ==9.8.4\r\n   || ==9.10.1\r\n   || ==9.12.4\r\n   || ==9.14.1\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/haskellari/these.git\r\n  subdir:   these\r\n\r\nlibrary\r\n  default-language:         Haskell2010\r\n  ghc-options:              -Wall -Wno-trustworthy-safe\r\n  hs-source-dirs:           src\r\n  exposed-modules:\r\n    Data.Functor.These\r\n    Data.These\r\n    Data.These.Combinators\r\n\r\n  -- ghc boot libs\r\n  build-depends:\r\n      base     >=4.12.0.0 && <4.23\r\n    , binary   >=0.8.6.0  && <0.10\r\n    , deepseq  >=1.4.4.0  && <1.6\r\n\r\n  -- other dependencies\r\n  -- note: we need to depend on assoc-1.1 to be sure that\r\n  -- Bifunctor type class comes from bifunctor-classes-compat\r\n  build-depends:\r\n      assoc     >=1.1.1   && <1.2\r\n    , hashable  >=1.4.4.0 && <1.6\r\n\r\n  if !impl(ghc >=9.6)\r\n    build-depends: foldable1-classes-compat >=0.1 && <0.2\r\n\r\n  x-docspec-extra-packages: lens";
  }