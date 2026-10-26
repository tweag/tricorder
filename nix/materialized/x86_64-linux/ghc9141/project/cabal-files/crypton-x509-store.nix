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
      identifier = { name = "crypton-x509-store"; version = "1.6.14"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/kazu-yamamoto/crypton-certificate";
      url = "";
      synopsis = "X.509 collection accessing and storing methods";
      description = "X.509 collection accessing and storing methods for certificate, crl, exception list";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."pem" or (errorHandler.buildDepError "pem"))
          (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
          (hsPkgs."asn1-encoding" or (errorHandler.buildDepError "asn1-encoding"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
        ] ++ pkgs.lib.optional (!system.isWindows) (hsPkgs."unix" or (errorHandler.buildDepError "unix"));
        buildable = true;
      };
      tests = {
        "test-x509-store" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
            (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-x509-store-1.6.14.tar.gz";
      sha256 = "68deba7d647a376b1c68086b37edefe4df19b90ee3293542921ff975d48d8db4";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\r\nname:               crypton-x509-store\r\nversion:            1.6.14\r\nx-revision: 1\r\nlicense:            BSD3\r\nlicense-file:       LICENSE\r\ncopyright:          Vincent Hanquez <vincent@snarc.org>\r\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\r\nauthor:             Vincent Hanquez <vincent@snarc.org>\r\nstability:          experimental\r\nhomepage:           https://github.com/kazu-yamamoto/crypton-certificate\r\nsynopsis:           X.509 collection accessing and storing methods\r\ndescription:\r\n    X.509 collection accessing and storing methods for certificate, crl, exception list\r\n\r\ncategory:           Data\r\nbuild-type:         Simple\r\nextra-source-files: ChangeLog.md\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/kazu-yamamoto/crypton-certificate\r\n    subdir:   x509-store\r\n\r\nlibrary\r\n    exposed-modules:\r\n        Data.X509.CertificateStore\r\n        Data.X509.File\r\n        Data.X509.Memory\r\n\r\n    default-language: Haskell2010\r\n    ghc-options:      -Wall\r\n    build-depends:\r\n        base >=3 && <5,\r\n        bytestring,\r\n        mtl,\r\n        containers,\r\n        directory,\r\n        filepath,\r\n        pem >=0.1 && <0.3,\r\n        asn1-types >=0.3 && <0.4,\r\n        asn1-encoding >=0.9 && <0.10,\r\n        crypton,\r\n        crypton-x509 >=1.7.2 && <1.8\r\n\r\n    if !os(windows)\r\n        build-depends: unix\r\n\r\ntest-suite test-x509-store\r\n    type:             exitcode-stdio-1.0\r\n    main-is:          Tests.hs\r\n    hs-source-dirs:   Tests\r\n    default-language: Haskell2010\r\n    ghc-options:      -Wall\r\n    build-depends:\r\n        base >=3 && <5,\r\n        bytestring,\r\n        tasty,\r\n        tasty-hunit,\r\n        crypton-x509,\r\n        crypton-x509-store\r\n";
  }