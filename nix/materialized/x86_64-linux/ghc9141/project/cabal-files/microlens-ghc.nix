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
      identifier = { name = "microlens-ghc"; version = "0.4.15.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Steven Fontanella <steven.fontanella@gmail.com>";
      author = "Edward Kmett, Artyom Kazak";
      homepage = "http://github.com/stevenfontanella/microlens";
      url = "";
      synopsis = "microlens + array, bytestring, containers, transformers";
      description = "Use this package instead of <http://hackage.haskell.org/package/microlens microlens> if you don't mind depending on all dependencies here – @Lens.Micro.GHC@ reexports everything from @Lens.Micro@ and additionally provides orphan instances of microlens classes for packages coming with GHC (<http://hackage.haskell.org/package/array array>, <http://hackage.haskell.org/package/bytestring bytestring>, <http://hackage.haskell.org/package/containers containers>, <http://hackage.haskell.org/package/transfromers transformers>).\n\nThe minor and major versions of microlens-ghc are incremented whenever the minor and major versions of microlens are incremented, so you can depend on the exact version of microlens-ghc without specifying the version of microlens you need.\n\nThis package is a part of the <http://hackage.haskell.org/package/microlens microlens> family; see the readme <https://github.com/stevenfontanella/microlens#readme on Github>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/microlens-ghc-0.4.15.2.tar.gz";
      sha256 = "6ba4de60779eb1989db5ceb445059fd2b2e58c293c3d25b9d5548c02ff6b36b0";
    });
  }) // {
    package-description-override = "name:                microlens-ghc\nversion:             0.4.15.2\nsynopsis:            microlens + array, bytestring, containers, transformers\ndescription:\n  Use this package instead of <http://hackage.haskell.org/package/microlens microlens> if you don't mind depending on all dependencies here – @Lens.Micro.GHC@ reexports everything from @Lens.Micro@ and additionally provides orphan instances of microlens classes for packages coming with GHC (<http://hackage.haskell.org/package/array array>, <http://hackage.haskell.org/package/bytestring bytestring>, <http://hackage.haskell.org/package/containers containers>, <http://hackage.haskell.org/package/transfromers transformers>).\n  .\n  The minor and major versions of microlens-ghc are incremented whenever the minor and major versions of microlens are incremented, so you can depend on the exact version of microlens-ghc without specifying the version of microlens you need.\n  .\n  This package is a part of the <http://hackage.haskell.org/package/microlens microlens> family; see the readme <https://github.com/stevenfontanella/microlens#readme on Github>.\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              Edward Kmett, Artyom Kazak\nmaintainer:          Steven Fontanella <steven.fontanella@gmail.com>\nhomepage:            http://github.com/stevenfontanella/microlens\nbug-reports:         http://github.com/stevenfontanella/microlens/issues\ncategory:            Data, Lenses\nbuild-type:          Simple\nextra-source-files:\n  CHANGELOG.md\ncabal-version:       >=1.10\ntested-with:\n                     GHC==9.12.1\n                     GHC==9.10.1\n                     GHC==9.8.4\n                     GHC==9.6.6\n                     GHC==9.4.8\n                     GHC==9.2.8\n                     GHC==9.0.2\n                     GHC==8.10.7\n                     GHC==8.8.4\n                     GHC==8.6.5\n                     GHC==8.4.4\n                     GHC==8.2.2\n                     GHC==8.0.2\n\nsource-repository head\n  type:                git\n  location:            https://github.com/stevenfontanella/microlens.git\n\nlibrary\n  exposed-modules:     Lens.Micro.GHC\n                       Lens.Micro.GHC.Internal\n  -- other-modules:\n  -- other-extensions:\n  build-depends:       array >=0.3.0.2 && <0.6\n                     , base >=4.5 && <5\n                     , bytestring >=0.9.2.1 && <0.13\n                     , containers >=0.4.0 && <0.9\n                     , microlens ==0.5.0.*\n                     , transformers >=0.2 && <0.7\n\n  ghc-options:\n    -Wall -fwarn-tabs\n    -O2 -fdicts-cheap -funbox-strict-fields\n    -fmax-simplifier-iterations=10\n\n  hs-source-dirs:      src\n  default-language:    Haskell2010\n  default-extensions:  TypeOperators\n";
  }