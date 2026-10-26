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
      identifier = { name = "wai-logger"; version = "2.5.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Kazu Yamamoto <kazu@iij.ad.jp>";
      homepage = "";
      url = "";
      synopsis = "A logging system for WAI";
      description = "A logging system for WAI(Web Application Interface)";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."byteorder" or (errorHandler.buildDepError "byteorder"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."fast-logger" or (errorHandler.buildDepError "fast-logger"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/wai-logger-2.5.0.tar.gz";
      sha256 = "5cfbd3076b1f94aca3bd2def06b136b36a22d37974f31c7732b8526ebec3e184";
    });
  }) // {
    package-description-override = "cabal-version: >=1.10\nname:          wai-logger\nversion:       2.5.0\nlicense:       BSD3\nlicense-file:  LICENSE\nmaintainer:    Kazu Yamamoto <kazu@iij.ad.jp>\nauthor:        Kazu Yamamoto <kazu@iij.ad.jp>\ntested-with:\n    ghc ==7.8.4 || ==7.10.3 || ==8.0.2 || ==8.2.2 || ==8.4.4 || ==8.6.3\n\nsynopsis:      A logging system for WAI\ndescription:   A logging system for WAI(Web Application Interface)\ncategory:      Web, Yesod\nbuild-type:    Simple\n\nsource-repository head\n    type:     git\n    location: https://github.com/kazu-yamamoto/logger.git\n\nlibrary\n    exposed-modules:  Network.Wai.Logger\n    other-modules:\n        Network.Wai.Logger.Apache\n        Network.Wai.Logger.IP\n        Network.Wai.Logger.IORef\n\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=4 && <5,\n        byteorder,\n        bytestring,\n        fast-logger >=3,\n        http-types,\n        network,\n        wai >=2.0.0\n\n    if impl(ghc >=8)\n        default-extensions: Strict StrictData\n";
  }