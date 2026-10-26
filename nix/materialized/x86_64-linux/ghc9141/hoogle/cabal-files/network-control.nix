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
      identifier = { name = "network-control"; version = "0.1.7"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "kazu@iij.ad.jp";
      author = "Kazu Yamamoto";
      homepage = "";
      url = "";
      synopsis = "Library to control network protocols";
      description = "Common parts to control network protocols";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."psqueues" or (errorHandler.buildDepError "psqueues"))
          (hsPkgs."unix-time" or (errorHandler.buildDepError "unix-time"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."network-control" or (errorHandler.buildDepError "network-control"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."pretty-simple" or (errorHandler.buildDepError "pretty-simple"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/network-control-0.1.7.tar.gz";
      sha256 = "05d40d381e5c72beefb209b7e82877b457fbca2880e60ed849bad480b6795b10";
    });
  }) // {
    package-description-override = "cabal-version:   3.0\nname:            network-control\nversion:         0.1.7\nlicense:         BSD-3-Clause\nlicense-file:    LICENSE\nmaintainer:      kazu@iij.ad.jp\nauthor:          Kazu Yamamoto\nsynopsis:        Library to control network protocols\ndescription:     Common parts to control network protocols\ncategory:        Network\nbuild-type:      Simple\nextra-doc-files: Changelog.md\n\nlibrary\n    exposed-modules:    Network.Control\n    other-modules:\n        Network.Control.Flow\n        Network.Control.LRUCache\n        Network.Control.Rate\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.14 && <5,\n        psqueues,\n        unix-time\n\ntest-suite spec\n    type:               exitcode-stdio-1.0\n    main-is:            Spec.hs\n    build-tool-depends: hspec-discover:hspec-discover\n    hs-source-dirs:     test\n    other-modules:\n        Network.Control.FlowSpec\n        Network.Control.LRUCacheSpec\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall -threaded\n    build-depends:\n        base,\n        hspec >=1.3,\n        network-control,\n        QuickCheck,\n        pretty-simple,\n        text\n";
  }