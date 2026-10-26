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
      identifier = { name = "crypton-connection"; version = "0.4.5"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/kazu-yamamoto/crypton-connection";
      url = "";
      synopsis = "Simple and easy network connection API";
      description = "Simple network library for all your connection needs.\n\nFeatures: Really simple to use, SSL/TLS, SOCKS.\n\nThis library provides a very simple api to create sockets\nto a destination with the choice of SSL/TLS, and SOCKS.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
          (hsPkgs."crypton-socks" or (errorHandler.buildDepError "crypton-socks"))
          (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
          (hsPkgs."crypton-x509-system" or (errorHandler.buildDepError "crypton-x509-system"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-connection-0.4.5.tar.gz";
      sha256 = "bcddb9f095eb7f13526bcbd4c20001b4bec737c1e6b2dcb6939f643fb83225de";
    });
  }) // {
    package-description-override = "Name:                crypton-connection\r\nVersion:             0.4.5\r\nx-revision: 1\r\nDescription:\r\n    Simple network library for all your connection needs.\r\n    .\r\n    Features: Really simple to use, SSL/TLS, SOCKS.\r\n    .\r\n    This library provides a very simple api to create sockets\r\n    to a destination with the choice of SSL/TLS, and SOCKS.\r\nLicense:             BSD3\r\nLicense-file:        LICENSE\r\nCopyright:           Vincent Hanquez <vincent@snarc.org>\r\nAuthor:              Vincent Hanquez <vincent@snarc.org>\r\nMaintainer:          Kazu Yamamoto <kazu@iij.ad.jp>\r\nSynopsis:            Simple and easy network connection API\r\nBuild-Type:          Simple\r\nCategory:            Network\r\nstability:           experimental\r\nCabal-Version:       >=1.10\r\nHomepage:            https://github.com/kazu-yamamoto/crypton-connection\r\nextra-source-files:  README.md\r\n                     CHANGELOG.md\r\n\r\nLibrary\r\n  Default-Language:  Haskell2010\r\n  Build-Depends:     base >= 3 && < 5\r\n                   , bytestring\r\n                   , containers\r\n                   , data-default\r\n                   , network >= 2.6.3\r\n                   , tls >= 1.7 && < 2.3\r\n                   , crypton-socks >= 0.6\r\n                   , crypton-x509-store >= 1.5\r\n                   , crypton-x509-system >= 1.5\r\n  Exposed-modules:   Network.Connection\r\n                     Network.Connection.Internal\r\n  Other-modules:     Network.Connection.Types\r\n  ghc-options:       -Wall\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/kazu-yamamoto/crypton-connection\r\n";
  }