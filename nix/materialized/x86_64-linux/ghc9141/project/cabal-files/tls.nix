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
    flags = { compat = true; network = true; hans = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "tls"; version = "1.9.0"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/haskell-tls/hs-tls";
      url = "";
      synopsis = "TLS/SSL protocol native implementation (Server and Client)";
      description = "Native Haskell TLS and SSL protocol implementation for server and client.\n\nThis provides a high-level implementation of a sensitive security protocol,\neliminating a common set of security issues through the use of the advanced\ntype system, high level constructions and common Haskell features.\n\nCurrently implement the TLS1.0, TLS1.1, TLS1.2 and TLS 1.3 protocol,\nand support RSA and Ephemeral (Elliptic curve and regular) Diffie Hellman key exchanges,\nand many extensions.\n\nSome debug tools linked with tls, are available through the\n<http://hackage.haskell.org/package/tls-debug/>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."cereal" or (errorHandler.buildDepError "cereal"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."data-default-class" or (errorHandler.buildDepError "data-default-class"))
          (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
          (hsPkgs."asn1-encoding" or (errorHandler.buildDepError "asn1-encoding"))
          (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
          (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
          (hsPkgs."crypton-x509-validation" or (errorHandler.buildDepError "crypton-x509-validation"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."unix-time" or (errorHandler.buildDepError "unix-time"))
        ] ++ pkgs.lib.optional (flags.network) (hsPkgs."network" or (errorHandler.buildDepError "network"))) ++ pkgs.lib.optional (flags.hans) (hsPkgs."hans" or (errorHandler.buildDepError "hans"));
        buildable = true;
      };
      tests = {
        "test-tls" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."data-default-class" or (errorHandler.buildDepError "data-default-class"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
            (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
            (hsPkgs."crypton-x509-validation" or (errorHandler.buildDepError "crypton-x509-validation"))
            (hsPkgs."hourglass" or (errorHandler.buildDepError "hourglass"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench-tls" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
            (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
            (hsPkgs."crypton-x509-validation" or (errorHandler.buildDepError "crypton-x509-validation"))
            (hsPkgs."data-default-class" or (errorHandler.buildDepError "data-default-class"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."gauge" or (errorHandler.buildDepError "gauge"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."hourglass" or (errorHandler.buildDepError "hourglass"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tls-1.9.0.tar.gz";
      sha256 = "5605b9cbe0903b100e9de72800641453f74bf5dade6176dbe10b34ac9353433e";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\r\nname:               tls\r\nversion:            1.9.0\r\nx-revision: 1\r\nlicense:            BSD3\r\nlicense-file:       LICENSE\r\ncopyright:          Vincent Hanquez <vincent@snarc.org>\r\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\r\nauthor:             Vincent Hanquez <vincent@snarc.org>\r\nstability:          experimental\r\nhomepage:           https://github.com/haskell-tls/hs-tls\r\nsynopsis:           TLS/SSL protocol native implementation (Server and Client)\r\ndescription:\r\n    Native Haskell TLS and SSL protocol implementation for server and client.\r\n    .\r\n    This provides a high-level implementation of a sensitive security protocol,\r\n    eliminating a common set of security issues through the use of the advanced\r\n    type system, high level constructions and common Haskell features.\r\n    .\r\n    Currently implement the TLS1.0, TLS1.1, TLS1.2 and TLS 1.3 protocol,\r\n    and support RSA and Ephemeral (Elliptic curve and regular) Diffie Hellman key exchanges,\r\n    and many extensions.\r\n    .\r\n    Some debug tools linked with tls, are available through the\r\n    <http://hackage.haskell.org/package/tls-debug/>.\r\n\r\ncategory:           Network\r\nbuild-type:         Simple\r\nextra-source-files:\r\n    Tests/*.hs\r\n    CHANGELOG.md\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/haskell-tls/hs-tls\r\n    subdir:   core\r\n\r\nflag compat\r\n    description:\r\n        Accept SSLv2 client hello for beginning SSLv3 / TLS handshake\r\n\r\nflag network\r\n    description: Use the base network library\r\n\r\nflag hans\r\n    description: Use the Haskell Network Stack (HaNS)\r\n    default:     False\r\n\r\nlibrary\r\n    exposed-modules:\r\n        Network.TLS\r\n        Network.TLS.Cipher\r\n        Network.TLS.Compression\r\n        Network.TLS.Internal\r\n        Network.TLS.Extra\r\n        Network.TLS.Extra.Cipher\r\n        Network.TLS.Extra.FFDHE\r\n        Network.TLS.QUIC\r\n\r\n    other-modules:\r\n        Network.TLS.Cap\r\n        Network.TLS.Struct\r\n        Network.TLS.Struct13\r\n        Network.TLS.Core\r\n        Network.TLS.Context\r\n        Network.TLS.Context.Internal\r\n        Network.TLS.Credentials\r\n        Network.TLS.Backend\r\n        Network.TLS.Crypto\r\n        Network.TLS.Crypto.DH\r\n        Network.TLS.Crypto.IES\r\n        Network.TLS.Crypto.Types\r\n        Network.TLS.ErrT\r\n        Network.TLS.Extension\r\n        Network.TLS.Handshake\r\n        Network.TLS.Handshake.Certificate\r\n        Network.TLS.Handshake.Client\r\n        Network.TLS.Handshake.Common\r\n        Network.TLS.Handshake.Common13\r\n        Network.TLS.Handshake.Control\r\n        Network.TLS.Handshake.Key\r\n        Network.TLS.Handshake.Process\r\n        Network.TLS.Handshake.Random\r\n        Network.TLS.Handshake.Server\r\n        Network.TLS.Handshake.Signature\r\n        Network.TLS.Handshake.State\r\n        Network.TLS.Handshake.State13\r\n        Network.TLS.Hooks\r\n        Network.TLS.IO\r\n        Network.TLS.Imports\r\n        Network.TLS.KeySchedule\r\n        Network.TLS.MAC\r\n        Network.TLS.Measurement\r\n        Network.TLS.Packet\r\n        Network.TLS.Packet13\r\n        Network.TLS.Parameters\r\n        Network.TLS.PostHandshake\r\n        Network.TLS.Record\r\n        Network.TLS.Record.Disengage\r\n        Network.TLS.Record.Engage\r\n        Network.TLS.Record.Layer\r\n        Network.TLS.Record.Reading\r\n        Network.TLS.Record.Writing\r\n        Network.TLS.Record.State\r\n        Network.TLS.Record.Types\r\n        Network.TLS.RNG\r\n        Network.TLS.State\r\n        Network.TLS.Session\r\n        Network.TLS.Sending\r\n        Network.TLS.Receiving\r\n        Network.TLS.Util\r\n        Network.TLS.Util.ASN1\r\n        Network.TLS.Util.Serialization\r\n        Network.TLS.Types\r\n        Network.TLS.Wire\r\n        Network.TLS.X509\r\n\r\n    default-language: Haskell2010\r\n    ghc-options:      -Wall\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        mtl >=2.2.1,\r\n        transformers,\r\n        cereal >=0.5.3,\r\n        bytestring,\r\n        data-default-class,\r\n        memory >=0.14.6,\r\n        crypton <1.1,\r\n        asn1-types >=0.2.0,\r\n        asn1-encoding,\r\n        crypton-x509 >=1.7.5 && <1.8,\r\n        crypton-x509-store >=1.6,\r\n        crypton-x509-validation >=1.6.5,\r\n        async >=2.0,\r\n        unix-time\r\n\r\n    if flag(network)\r\n        cpp-options:   -DINCLUDE_NETWORK\r\n        build-depends: network >=2.4.0.0\r\n\r\n    if flag(hans)\r\n        cpp-options:   -DINCLUDE_HANS\r\n        build-depends: hans\r\n\r\n    if flag(compat)\r\n        cpp-options: -DSSLV2_COMPATIBLE\r\n\r\ntest-suite test-tls\r\n    type:             exitcode-stdio-1.0\r\n    main-is:          Tests.hs\r\n    hs-source-dirs:   Tests\r\n    other-modules:\r\n        Certificate\r\n        Ciphers\r\n        Connection\r\n        Marshalling\r\n        PipeChan\r\n        PubKey\r\n\r\n    default-language: Haskell2010\r\n    ghc-options:      -Wall -fno-warn-unused-imports\r\n    build-depends:\r\n        base >=3 && <5,\r\n        async >=2.0,\r\n        data-default-class,\r\n        tasty,\r\n        tasty-quickcheck,\r\n        tls,\r\n        QuickCheck,\r\n        crypton,\r\n        bytestring,\r\n        asn1-types,\r\n        crypton-x509,\r\n        crypton-x509-validation,\r\n        hourglass\r\n\r\nbenchmark bench-tls\r\n    type:             exitcode-stdio-1.0\r\n    main-is:          Benchmarks.hs\r\n    hs-source-dirs:   Benchmarks Tests\r\n    other-modules:\r\n        Certificate\r\n        Connection\r\n        PipeChan\r\n        PubKey\r\n\r\n    default-language: Haskell2010\r\n    ghc-options:      -Wall -fno-warn-unused-imports\r\n    build-depends:\r\n        base >=4 && <5,\r\n        tls,\r\n        crypton-x509,\r\n        crypton-x509-validation,\r\n        data-default-class,\r\n        crypton,\r\n        gauge,\r\n        bytestring,\r\n        asn1-types,\r\n        async >=2.0,\r\n        hourglass,\r\n        QuickCheck >=2,\r\n        tasty-quickcheck,\r\n        tls\r\n";
  }