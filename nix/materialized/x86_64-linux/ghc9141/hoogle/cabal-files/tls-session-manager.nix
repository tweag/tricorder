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
      identifier = { name = "tls-session-manager"; version = "0.0.4"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "kazu@iij.ad.jp";
      author = "Kazu Yamamoto";
      homepage = "";
      url = "";
      synopsis = "In-memory TLS session manager";
      description = "TLS session manager with limitation, automatic pruning, energy saving and replay resistance";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."auto-update" or (errorHandler.buildDepError "auto-update"))
          (hsPkgs."basement" or (errorHandler.buildDepError "basement"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."clock" or (errorHandler.buildDepError "clock"))
          (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
          (hsPkgs."psqueues" or (errorHandler.buildDepError "psqueues"))
          (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tls-session-manager-0.0.4.tar.gz";
      sha256 = "ba207f79b4536a65625063106c621e8bafc0dc7928bd9273270e19f36d59938c";
    });
  }) // {
    package-description-override = "name:                tls-session-manager\r\nversion:             0.0.4\r\nx-revision: 1\r\nsynopsis:            In-memory TLS session manager\r\ndescription:         TLS session manager with limitation, automatic pruning, energy saving and replay resistance\r\nlicense:             BSD3\r\nlicense-file:        LICENSE\r\nauthor:              Kazu Yamamoto\r\nmaintainer:          kazu@iij.ad.jp\r\n-- copyright:\r\ncategory:            Web\r\nbuild-type:          Simple\r\nextra-source-files:  ChangeLog.md\r\ncabal-version:       >= 1.10\r\n\r\nlibrary\r\n  exposed-modules:     Network.TLS.SessionManager\r\n  other-modules:       Network.TLS.Imports\r\n  -- other-extensions:\r\n  build-depends:       base >= 4.7 && < 5\r\n                     , auto-update\r\n                     , basement\r\n                     , bytestring\r\n                     , clock\r\n                     , memory\r\n                     , psqueues >= 0.2.3\r\n                     , tls < 2.0\r\n  -- hs-source-dirs:\r\n  default-language:    Haskell2010\r\n  ghc-options:       -Wall\r\n  if impl(ghc >= 8)\r\n      default-extensions:  Strict StrictData\r\n";
  }