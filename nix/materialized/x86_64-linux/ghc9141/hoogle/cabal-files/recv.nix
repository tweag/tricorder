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
      identifier = { name = "recv"; version = "0.1.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "kazu@iij.ad.jp";
      author = "Kazu Yamamoto";
      homepage = "http://github.com/yesodweb/wai";
      url = "";
      synopsis = "Efficient network recv";
      description = "Network recv based on buffer pools";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."recv" or (errorHandler.buildDepError "recv"))
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
      url = "http://hackage.haskell.org/package/recv-0.1.2.tar.gz";
      sha256 = "4a1d9923646619911d7f5e162ef01be88de981c122e31e4d733df56f319e9aa5";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               recv\nversion:            0.1.2\nlicense:            BSD3\nlicense-file:       LICENSE\nmaintainer:         kazu@iij.ad.jp\nauthor:             Kazu Yamamoto\nstability:          Stable\nhomepage:           http://github.com/yesodweb/wai\nsynopsis:           Efficient network recv\ndescription:        Network recv based on buffer pools\ncategory:           Network\nbuild-type:         Simple\nextra-source-files: ChangeLog.md\n\nlibrary\n    exposed-modules:  Network.Socket.BufferPool\n    other-modules:\n        Network.Socket.BufferPool.Buffer\n        Network.Socket.BufferPool.Recv\n        Network.Socket.BufferPool.Types\n\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=4.12 && <5,\n        bytestring >=0.9.1.4,\n        network >=3.2.9\n\n    if impl(ghc >=8)\n        default-extensions: Strict StrictData\n\ntest-suite spec\n    type:               exitcode-stdio-1.0\n    main-is:            Spec.hs\n    build-tool-depends: hspec-discover:hspec-discover\n    hs-source-dirs:     test .\n    other-modules:\n        BufferPoolSpec\n        Network.Socket.BufferPool\n        Network.Socket.BufferPool.Buffer\n        Network.Socket.BufferPool.Recv\n        Network.Socket.BufferPool.Types\n\n    default-language:   Haskell2010\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.12 && <5,\n        bytestring >=0.9.1.4,\n        network >=3.2.9,\n        hspec,\n        recv\n";
  }