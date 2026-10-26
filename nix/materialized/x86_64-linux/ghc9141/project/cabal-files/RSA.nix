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
      specVersion = "1.8";
      identifier = { name = "RSA"; version = "2.4.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Adam Wick <awick@galois.com>";
      author = "Adam Wick <awick@galois.com>";
      homepage = "";
      url = "";
      synopsis = "Implementation of RSA, using the padding schemes of PKCS#1 v2.1.";
      description = "This library implements the RSA encryption and signature\nalgorithms for arbitrarily-sized ByteStrings. While the\nimplementations work, they are not necessarily the fastest ones\non the planet. Particularly key generation. The algorithms\nincluded are based of RFC 3447, or the Public-Key Cryptography\nStandard for RSA, version 2.1 (a.k.a, PKCS#1 v2.1).";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."crypto-api" or (errorHandler.buildDepError "crypto-api"))
          (hsPkgs."crypto-pubkey-types" or (errorHandler.buildDepError "crypto-pubkey-types"))
          (hsPkgs."SHA" or (errorHandler.buildDepError "SHA"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8.0") (hsPkgs."cipher-aes128" or (errorHandler.buildDepError "cipher-aes128"));
        buildable = true;
      };
      tests = {
        "test-rsa" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypto-api" or (errorHandler.buildDepError "crypto-api"))
            (hsPkgs."crypto-pubkey-types" or (errorHandler.buildDepError "crypto-pubkey-types"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
            (hsPkgs."test-framework" or (errorHandler.buildDepError "test-framework"))
            (hsPkgs."test-framework-quickcheck2" or (errorHandler.buildDepError "test-framework-quickcheck2"))
            (hsPkgs."SHA" or (errorHandler.buildDepError "SHA"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/RSA-2.4.1.tar.gz";
      sha256 = "72c5d8c45ef1013e0e8aff763bb8894df0f022f28e698e33ae87bbdb33d69041";
    });
  }) // {
    package-description-override = "name:       RSA\r\ncategory:   Cryptography, Codec\r\nversion:    2.4.1\r\nx-revision: 2\r\nlicense:    BSD3\r\nlicense-file: LICENSE\r\nauthor:     Adam Wick <awick@galois.com>\r\nmaintainer: Adam Wick <awick@galois.com>\r\nstability:  stable\r\nbuild-type: Simple\r\ncabal-version: >= 1.8\r\ntested-with: GHC ==7.8.0\r\nsynopsis: Implementation of RSA, using the padding schemes of PKCS#1 v2.1.\r\ndescription: This library implements the RSA encryption and signature \r\n             algorithms for arbitrarily-sized ByteStrings. While the \r\n             implementations work, they are not necessarily the fastest ones\r\n             on the planet. Particularly key generation. The algorithms\r\n             included are based of RFC 3447, or the Public-Key Cryptography\r\n             Standard for RSA, version 2.1 (a.k.a, PKCS#1 v2.1).   \r\n\r\nLibrary\r\n  hs-source-dirs:  src\r\n  build-depends:   base                >= 4.6     && < 7.0,\r\n                   binary              >  0.7     && < 1.0,\r\n                   bytestring          >  0.8     && < 0.13,\r\n                   crypto-api          >= 0.10    && < 0.14,\r\n                   crypto-pubkey-types >= 0.2     && < 0.6,\r\n                   SHA                 >= 1.6.4.1 && < 2.0\r\n  if impl(ghc < 8.0)\r\n    build-depends: cipher-aes128       < 0.7.0.4\r\n  exposed-modules: Codec.Crypto.RSA,\r\n                   Codec.Crypto.RSA.Exceptions,\r\n                   Codec.Crypto.RSA.Pure\r\n  GHC-Options:     -Wall -fno-warn-orphans\r\n  extensions:      DeriveDataTypeable, MultiWayIf\r\n\r\ntest-suite test-rsa\r\n  type:           exitcode-stdio-1.0\r\n  Main-Is:        Test.hs\r\n  hs-source-dirs: src,.\r\n  other-modules:  Codec.Crypto.RSA.Pure\r\n  build-depends:  base,\r\n                  binary,\r\n                  bytestring,\r\n                  crypto-api,\r\n                  crypto-pubkey-types,\r\n                  QuickCheck                 >= 2.5     && < 3,\r\n                  tagged                     >= 0.2     && < 0.9,\r\n                  test-framework             >= 0.8.0.3 && < 0.10,\r\n                  test-framework-quickcheck2 >= 0.3.0.2 && < 0.5,\r\n                  SHA                        >= 1.6.4.1 && < 2.0\r\n  GHC-Options:    -Wall -fno-warn-orphans\r\n  extensions:     DeriveDataTypeable, MultiWayIf, ScopedTypeVariables\r\n\r\nsource-repository head\r\n  type: git\r\n  location: git://github.com/GaloisInc/RSA.git\r\n\r\n";
  }