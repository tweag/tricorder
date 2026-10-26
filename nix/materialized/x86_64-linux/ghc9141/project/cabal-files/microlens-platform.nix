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
      identifier = { name = "microlens-platform"; version = "0.4.4.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Steven Fontanella <steven.fontanella@gmail.com>";
      author = "Edward Kmett, Artyom Kazak";
      homepage = "http://github.com/stevenfontanella/microlens";
      url = "";
      synopsis = "microlens + all batteries included (best for apps)";
      description = "This package exports a module which is the recommended starting point for using <http://hackage.haskell.org/package/microlens microlens> if you aren't trying to keep your dependencies minimal. By importing @Lens.Micro.Platform@ you get all functions and instances from <http://hackage.haskell.org/package/microlens microlens>, <http://hackage.haskell.org/package/microlens-th microlens-th>, <http://hackage.haskell.org/package/microlens-mtl microlens-mtl>, <http://hackage.haskell.org/package/microlens-ghc microlens-ghc>, as well as instances for @Vector@, @Text@, and @HashMap@.\n\nThe minor and major versions of microlens-platform are incremented whenever the minor and major versions of any other microlens package are incremented, so you can depend on the exact version of microlens-platform without specifying the version of microlens (microlens-mtl, etc) you need.\n\nThis package is a part of the <http://hackage.haskell.org/package/microlens microlens> family; see the readme <https://github.com/stevenfontanella/microlens#readme on Github>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
          (hsPkgs."microlens-ghc" or (errorHandler.buildDepError "microlens-ghc"))
          (hsPkgs."microlens-mtl" or (errorHandler.buildDepError "microlens-mtl"))
          (hsPkgs."microlens-th" or (errorHandler.buildDepError "microlens-th"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/microlens-platform-0.4.4.2.tar.gz";
      sha256 = "60f3a814d2313f08e03e43d89870fa0bc83ff0b7a59674d71015a64e2badc023";
    });
  }) // {
    package-description-override = "name:                microlens-platform\nversion:             0.4.4.2\nsynopsis:            microlens + all batteries included (best for apps)\ndescription:\n  This package exports a module which is the recommended starting point for using <http://hackage.haskell.org/package/microlens microlens> if you aren't trying to keep your dependencies minimal. By importing @Lens.Micro.Platform@ you get all functions and instances from <http://hackage.haskell.org/package/microlens microlens>, <http://hackage.haskell.org/package/microlens-th microlens-th>, <http://hackage.haskell.org/package/microlens-mtl microlens-mtl>, <http://hackage.haskell.org/package/microlens-ghc microlens-ghc>, as well as instances for @Vector@, @Text@, and @HashMap@.\n  .\n  The minor and major versions of microlens-platform are incremented whenever the minor and major versions of any other microlens package are incremented, so you can depend on the exact version of microlens-platform without specifying the version of microlens (microlens-mtl, etc) you need.\n  .\n  This package is a part of the <http://hackage.haskell.org/package/microlens microlens> family; see the readme <https://github.com/stevenfontanella/microlens#readme on Github>.\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              Edward Kmett, Artyom Kazak\nmaintainer:          Steven Fontanella <steven.fontanella@gmail.com>\nhomepage:            http://github.com/stevenfontanella/microlens\nbug-reports:         http://github.com/stevenfontanella/microlens/issues\ncategory:            Data, Lenses\nbuild-type:          Simple\nextra-source-files:\n  CHANGELOG.md\ncabal-version:       >=1.10\ntested-with:\n                     GHC==9.12.1\n                     GHC==9.10.1\n                     GHC==9.8.4\n                     GHC==9.6.6\n                     GHC==9.4.8\n                     GHC==9.2.8\n                     GHC==9.0.2\n                     GHC==8.10.7\n                     GHC==8.8.4\n                     GHC==8.6.5\n                     GHC==8.4.4\n                     GHC==8.2.2\n                     GHC==8.0.2\n\nsource-repository head\n  type:                git\n  location:            https://github.com/stevenfontanella/microlens.git\n\nlibrary\n  exposed-modules:     Lens.Micro.Platform\n                       Lens.Micro.Platform.Internal\n  -- other-modules:\n  -- other-extensions:\n  build-depends:       base >=4.5 && <5\n                     , hashable >=1.1.2.3 && <1.6\n                     , microlens ==0.5.0.*\n                     , microlens-ghc ==0.4.15.*\n                     , microlens-mtl ==0.2.1.*\n                     , microlens-th ==0.4.3.*\n                     , text >=0.11 && <1.3 || >=2.0 && <2.2\n                     , unordered-containers >=0.2.4 && <0.3\n                     , vector >=0.9 && <0.14\n\n  ghc-options:\n    -Wall -fwarn-tabs\n    -O2 -fdicts-cheap -funbox-strict-fields\n    -fmax-simplifier-iterations=10\n\n  hs-source-dirs:      src\n  default-language:    Haskell2010\n  default-extensions:  TypeOperators\n";
  }