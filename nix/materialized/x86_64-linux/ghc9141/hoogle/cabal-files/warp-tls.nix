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
      identifier = { name = "warp-tls"; version = "3.4.9"; };
      license = "MIT";
      copyright = "";
      maintainer = "michael@snoyman.com";
      author = "Michael Snoyman";
      homepage = "http://github.com/yesodweb/wai";
      url = "";
      synopsis = "HTTP over TLS support for Warp via the TLS package";
      description = "SSLv1 and SSLv2 are obsoleted by IETF.\nWe should use TLS 1.2 (or TLS 1.1 or TLS 1.0 if necessary).\nHTTP/2 can be negotiated by ALPN.\nAPI docs and the README are available at\n<http://www.stackage.org/package/warp-tls>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
          (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."streaming-commons" or (errorHandler.buildDepError "streaming-commons"))
          (hsPkgs."tls-session-manager" or (errorHandler.buildDepError "tls-session-manager"))
          (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
          (hsPkgs."recv" or (errorHandler.buildDepError "recv"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/warp-tls-3.4.9.tar.gz";
      sha256 = "eeed64ec43d4070ffc96fd672565f934c130b98339c4bbf59cee387d0eb3b705";
    });
  }) // {
    package-description-override = "Name:                warp-tls\r\nVersion:             3.4.9\r\nx-revision: 1\r\nSynopsis:            HTTP over TLS support for Warp via the TLS package\r\nLicense:             MIT\r\nLicense-file:        LICENSE\r\nAuthor:              Michael Snoyman\r\nMaintainer:          michael@snoyman.com\r\nHomepage:            http://github.com/yesodweb/wai\r\nCategory:            Web, Yesod\r\nBuild-Type:          Simple\r\nCabal-Version:       >= 1.10\r\nStability:           Stable\r\ndescription:         SSLv1 and SSLv2 are obsoleted by IETF.\r\n                     We should use TLS 1.2 (or TLS 1.1 or TLS 1.0 if necessary).\r\n                     HTTP/2 can be negotiated by ALPN.\r\n                     API docs and the README are available at\r\n                     <http://www.stackage.org/package/warp-tls>.\r\nextra-source-files:  ChangeLog.md README.md\r\n\r\nLibrary\r\n  Build-Depends:     base                          >= 4.12     && < 5\r\n                   , bytestring                    >= 0.9\r\n                   , wai                           >= 3.2      && < 3.3\r\n                   , warp                          >= 3.3.29   && < 3.4.13\r\n                   , data-default\r\n                   , tls                           >= 1.7      && < 2.2\r\n                   , network                       >= 2.2.1\r\n                   , streaming-commons\r\n                   , tls-session-manager           >= 0.0.4\r\n                   , unliftio\r\n                   , recv                          >= 0.1.0   && < 0.2.0\r\n  Exposed-modules:   Network.Wai.Handler.WarpTLS\r\n                     Network.Wai.Handler.WarpTLS.Internal\r\n  ghc-options:       -Wall\r\n  if os(windows)\r\n      Cpp-Options:   -DWINDOWS\r\n  if impl(ghc >= 8)\r\n      Default-Extensions:  Strict StrictData\r\n  Default-Language:     Haskell2010\r\n\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: git://github.com/yesodweb/wai.git\r\n";
  }