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
      identifier = { name = "crypton-x509-validation"; version = "1.6.14"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/kazu-yamamoto/crypton-certificate";
      url = "";
      synopsis = "X.509 Certificate and CRL validation";
      description = "X.509 Certificate and CRL validation. please see README";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."hourglass" or (errorHandler.buildDepError "hourglass"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."pem" or (errorHandler.buildDepError "pem"))
          (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
          (hsPkgs."asn1-encoding" or (errorHandler.buildDepError "asn1-encoding"))
          (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
          (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
        ];
        buildable = true;
      };
      tests = {
        "test-x509-validation" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."hourglass" or (errorHandler.buildDepError "hourglass"))
            (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
            (hsPkgs."asn1-encoding" or (errorHandler.buildDepError "asn1-encoding"))
            (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
            (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
            (hsPkgs."crypton-x509-validation" or (errorHandler.buildDepError "crypton-x509-validation"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-x509-validation-1.6.14.tar.gz";
      sha256 = "ed0e394127db59d66a0a8e4bde28fa0b8cc67cc9a810793b54a58e96df4c601d";
    });
  }) // {
    package-description-override = "Name:                crypton-x509-validation\r\nversion:             1.6.14\r\nx-revision: 1\r\nDescription:         X.509 Certificate and CRL validation. please see README\r\nLicense:             BSD3\r\nLicense-file:        LICENSE\r\nCopyright:           Vincent Hanquez <vincent@snarc.org>\r\nAuthor:              Vincent Hanquez <vincent@snarc.org>\r\nMaintainer:          Kazu Yamamoto <kazu@iij.ad.jp>\r\nSynopsis:            X.509 Certificate and CRL validation\r\nBuild-Type:          Simple\r\nCategory:            Data\r\nstability:           experimental\r\nHomepage:            https://github.com/kazu-yamamoto/crypton-certificate\r\nCabal-Version:       >= 1.10\r\n\r\nLibrary\r\n  Default-Language:  Haskell2010\r\n  Build-Depends:     base >= 3 && < 5\r\n                   , bytestring\r\n                   , memory\r\n                   , mtl\r\n                   , containers\r\n                   , hourglass\r\n                   , data-default\r\n                   , pem >= 0.1\r\n                   , asn1-types >= 0.3 && < 0.4\r\n                   , asn1-encoding >= 0.9 && < 0.10\r\n                   , crypton-x509 >= 1.7.5 && < 1.8\r\n                   , crypton-x509-store >= 1.6\r\n                   , crypton >= 0.24 && < 1.1\r\n                   , iproute >= 1.2.2\r\n  Exposed-modules:   Data.X509.Validation\r\n  Other-modules:     Data.X509.Validation.Signature\r\n                     Data.X509.Validation.Fingerprint\r\n                     Data.X509.Validation.Cache\r\n                     Data.X509.Validation.Types\r\n  ghc-options:       -Wall\r\n\r\nTest-Suite test-x509-validation\r\n  Default-Language:  Haskell2010\r\n  type:              exitcode-stdio-1.0\r\n  hs-source-dirs:    Tests\r\n  Main-is:           Tests.hs\r\n  Other-modules:     Certificate\r\n  Build-Depends:     base >= 3 && < 5\r\n                   , bytestring\r\n                   , memory\r\n                   , data-default\r\n                   , tasty\r\n                   , tasty-hunit\r\n                   , hourglass\r\n                   , asn1-types\r\n                   , asn1-encoding\r\n                   , crypton-x509 >= 1.7.1\r\n                   , crypton-x509-store\r\n                   , crypton-x509-validation\r\n                   , crypton\r\n  ghc-options:       -Wall\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/kazu-yamamoto/crypton-certificate\r\n  subdir:   x509-validation\r\n";
  }