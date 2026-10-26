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
      specVersion = "2.2";
      identifier = { name = "resolv"; version = "0.2.0.3"; };
      license = "GPL-2.0-or-later";
      copyright = "";
      maintainer = "Alexey Radkov, Andreas Abel";
      author = "Herbert Valerio Riedel";
      homepage = "";
      url = "";
      synopsis = "Domain Name Service (DNS) lookup via the libresolv standard library routines";
      description = "This package implements an API for accessing\nthe [Domain Name Service (DNS)](https://tools.ietf.org/html/rfc1035)\nresolver service via the standard @libresolv@ system library (whose\nAPI is often available directly via the standard @libc@ C library) on\nUnix systems.\n\nThis package also includes support for decoding message record types\nas defined in the following RFCs:\n\n- [RFC 1035](https://tools.ietf.org/html/rfc1035): Domain Names - Implementation And Specification\n- [RFC 1183](https://tools.ietf.org/html/rfc1183): New DNS RR Definitions\n- [RFC 2782](https://tools.ietf.org/html/rfc2782): A DNS RR for specifying the location of services (DNS SRV)\n- [RFC 2915](https://tools.ietf.org/html/rfc2915): The Naming Authority Pointer (NAPTR) DNS Resource Record\n- [RFC 3596](https://tools.ietf.org/html/rfc3596): DNS Extensions to Support IP Version 6\n- [RFC 4034](https://tools.ietf.org/html/rfc4034): Resource Records for the DNS Security Extensions\n- [RFC 4255](https://tools.ietf.org/html/rfc4255): Using DNS to Securely Publish Secure Shell (SSH) Key Fingerprints\n- [RFC 4408](https://tools.ietf.org/html/rfc4408): Sender Policy Framework (SPF) for Authorizing Use of Domains in E-Mail, Version 1\n- [RFC 5155](https://tools.ietf.org/html/rfc5155): DNS Security (DNSSEC) Hashed Authenticated Denial of Existence\n- [RFC 6844](https://tools.ietf.org/html/rfc6844): DNS Certification Authority Authorization (CAA) Resource Record\n- [RFC 6891](https://tools.ietf.org/html/rfc6891): Extension Mechanisms for DNS (EDNS(0))\n- [RFC 7553](https://tools.ietf.org/html/rfc7553): The Uniform Resource Identifier (URI) DNS Resource Record\n\nFor Windows, the package [windns](https://hackage.haskell.org/package/windns)\nprovides a compatible subset of this package's API.";
      buildType = "Configure";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
        ];
        buildable = true;
      };
      tests = {
        "resolv." = {
          depends = [
            (hsPkgs."resolv" or (errorHandler.buildDepError "resolv"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/resolv-0.2.0.3.tar.gz";
      sha256 = "7702a48ab88b2ccbb78d4c4748f70a0bca2347b603daa2eb8ab014439d577103";
    });
  }) // {
    package-description-override = "cabal-version:       2.2\n\nname:                resolv\nversion:             0.2.0.3\n\nsynopsis:            Domain Name Service (DNS) lookup via the libresolv standard library routines\ndescription: {\n\nThis package implements an API for accessing\nthe [Domain Name Service (DNS)](https://tools.ietf.org/html/rfc1035)\nresolver service via the standard @libresolv@ system library (whose\nAPI is often available directly via the standard @libc@ C library) on\nUnix systems.\n.\nThis package also includes support for decoding message record types\nas defined in the following RFCs:\n.\n- [RFC 1035](https://tools.ietf.org/html/rfc1035): Domain Names - Implementation And Specification\n- [RFC 1183](https://tools.ietf.org/html/rfc1183): New DNS RR Definitions\n- [RFC 2782](https://tools.ietf.org/html/rfc2782): A DNS RR for specifying the location of services (DNS SRV)\n- [RFC 2915](https://tools.ietf.org/html/rfc2915): The Naming Authority Pointer (NAPTR) DNS Resource Record\n- [RFC 3596](https://tools.ietf.org/html/rfc3596): DNS Extensions to Support IP Version 6\n- [RFC 4034](https://tools.ietf.org/html/rfc4034): Resource Records for the DNS Security Extensions\n- [RFC 4255](https://tools.ietf.org/html/rfc4255): Using DNS to Securely Publish Secure Shell (SSH) Key Fingerprints\n- [RFC 4408](https://tools.ietf.org/html/rfc4408): Sender Policy Framework (SPF) for Authorizing Use of Domains in E-Mail, Version 1\n- [RFC 5155](https://tools.ietf.org/html/rfc5155): DNS Security (DNSSEC) Hashed Authenticated Denial of Existence\n- [RFC 6844](https://tools.ietf.org/html/rfc6844): DNS Certification Authority Authorization (CAA) Resource Record\n- [RFC 6891](https://tools.ietf.org/html/rfc6891): Extension Mechanisms for DNS (EDNS(0))\n- [RFC 7553](https://tools.ietf.org/html/rfc7553): The Uniform Resource Identifier (URI) DNS Resource Record\n.\nFor Windows, the package [windns](https://hackage.haskell.org/package/windns)\nprovides a compatible subset of this package's API.\n}\n\nlicense:             GPL-2.0-or-later\nlicense-files:       LICENSE LICENSE.GPLv2 LICENSE.GPLv3\nauthor:              Herbert Valerio Riedel\nmaintainer:          Alexey Radkov, Andreas Abel\ncategory:            Network\nbuild-type:          Configure\nbug-reports:         https://github.com/haskell-hvr/resolv/issues\nextra-doc-files:     ChangeLog.md\n\nextra-source-files:  cbits/hs_resolv.h\n                     cbits/hs_resolv_config.h.in\n                     testdata/msg/*.bin\n                     testdata/msg/*.show\n                     resolv.buildinfo.in\n                     configure\n\nextra-tmp-files:     autom4te.cache\n                     config.log\n                     config.status\n                     resolv.buildinfo\n                     cbits/hs_resolv_config.h\n\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.2\n  GHC == 9.10.2\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nsource-repository head\n  type:              git\n  location:          https://github.com/haskell-hvr/resolv.git\n\nlibrary\n  default-language:  Haskell2010\n  other-extensions:  BangPatterns\n                     CApiFFI\n                     CPP\n                     DeriveDataTypeable\n                     DeriveFoldable\n                     DeriveFunctor\n                     DeriveTraversable\n                     GeneralizedNewtypeDeriving\n                     OverloadedStrings\n                     RecordWildCards\n                     Trustworthy\n\n  hs-source-dirs:    src\n  include-dirs:      cbits\n\n  exposed-modules:   Network.DNS\n  other-modules:     Network.DNS.Message\n                     Network.DNS.FFI\n                     Compat\n\n  -- Lower bounds take from GHC 8.0 shipped libraries and Stackage LTS 7.0\n  build-depends:     base               >= 4.9      && < 5\n                   , base16-bytestring  >= 0.1.1.6  && < 1.1\n                   , binary             >= 0.8.3    && < 0.9\n                   , bytestring         >= 0.10.8.0 && < 0.13\n                   , containers         >= 0.5.7.1  && < 0.9\n\n  ghc-options:\n    -Wall\n    -Wcompat\n    -Wunused-packages\n    -Wincomplete-patterns\n\ntest-suite resolv.\n  default-language:    Haskell2010\n  hs-source-dirs:      src-test\n  main-is:             Tests1.hs\n  type:                exitcode-stdio-1.0\n\n  -- dependencies whose version constraints are inherited via lib:resolv component\n  build-depends: resolv\n               , base\n               , bytestring\n\n  -- additional dependencies not inherited\n  build-depends: tasty         >= 1.2.3    && < 1.6\n               , tasty-hunit  ^>= 0.10.0\n               , directory     >= 1.2.6.2  && < 1.4\n               , filepath      >= 1.4.1.0  && < 1.6\n";
  }