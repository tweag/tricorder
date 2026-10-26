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
    flags = { dev = false; };
    package = {
      specVersion = "2.4";
      identifier = { name = "req"; version = "3.13.4"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Mark Karpov <markkarpov92@gmail.com>";
      author = "Mark Karpov <markkarpov92@gmail.com>";
      homepage = "https://github.com/mrkkrp/req";
      url = "";
      synopsis = "HTTP client library";
      description = "HTTP client library.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."authenticate-oauth" or (errorHandler.buildDepError "authenticate-oauth"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."crypton-connection" or (errorHandler.buildDepError "crypton-connection"))
          (hsPkgs."data-default-class" or (errorHandler.buildDepError "data-default-class"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."http-api-data" or (errorHandler.buildDepError "http-api-data"))
          (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
          (hsPkgs."http-client-tls" or (errorHandler.buildDepError "http-client-tls"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."modern-uri" or (errorHandler.buildDepError "modern-uri"))
          (hsPkgs."monad-control" or (errorHandler.buildDepError "monad-control"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."retry" or (errorHandler.buildDepError "retry"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."transformers-base" or (errorHandler.buildDepError "transformers-base"))
          (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
        ];
        buildable = true;
      };
      tests = {
        "pure-tests" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-core" or (errorHandler.buildDepError "hspec-core"))
            (hsPkgs."http-api-data" or (errorHandler.buildDepError "http-api-data"))
            (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."modern-uri" or (errorHandler.buildDepError "modern-uri"))
            (hsPkgs."req" or (errorHandler.buildDepError "req"))
            (hsPkgs."retry" or (errorHandler.buildDepError "retry"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
        "httpbin-tests" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."monad-control" or (errorHandler.buildDepError "monad-control"))
            (hsPkgs."req" or (errorHandler.buildDepError "req"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = if flags.dev then true else false;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/req-3.13.4.tar.gz";
      sha256 = "f37fc48d15fb63a6edc546403eaa261310258d72737b42c02ea39d95049d0069";
    });
  }) // {
    package-description-override = "cabal-version:   2.4\r\nname:            req\r\nversion:         3.13.4\r\nx-revision: 10\r\nlicense:         BSD-3-Clause\r\nlicense-file:    LICENSE.md\r\nmaintainer:      Mark Karpov <markkarpov92@gmail.com>\r\nauthor:          Mark Karpov <markkarpov92@gmail.com>\r\ntested-with:     ghc ==9.6.3 ghc ==9.8.2 ghc ==9.10.1\r\nhomepage:        https://github.com/mrkkrp/req\r\nbug-reports:     https://github.com/mrkkrp/req/issues\r\nsynopsis:        HTTP client library\r\ndescription:     HTTP client library.\r\ncategory:        Network, Web\r\nbuild-type:      Simple\r\ndata-files:\r\n    httpbin-data/utf8.html\r\n    httpbin-data/robots.txt\r\n\r\nextra-doc-files:\r\n    CHANGELOG.md\r\n    README.md\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/mrkkrp/req.git\r\n\r\nflag dev\r\n    description: Turn on development settings.\r\n    default:     False\r\n    manual:      True\r\n\r\nlibrary\r\n    exposed-modules:  Network.HTTP.Req\r\n    default-language: GHC2021\r\n    build-depends:\r\n        aeson >=0.9 && <3,\r\n        authenticate-oauth >=1.5 && <1.8,\r\n        base >=4.15 && <5,\r\n        blaze-builder >=0.3 && <0.5,\r\n        bytestring >=0.10.8 && <0.13,\r\n        case-insensitive >=0.2 && <1.3,\r\n        containers >=0.5 && <0.9,\r\n        crypton-connection >=0.4.2 && <0.5,\r\n        data-default-class >= 0.2.0.0,\r\n        exceptions >=0.6 && <0.11,\r\n        http-api-data >=0.2 && <0.8,\r\n        http-client >=0.7.13.1 && <0.8,\r\n        http-client-tls >=0.3.2 && <0.5,\r\n        http-types >=0.8 && <1,\r\n        modern-uri >=0.3 && <0.4,\r\n        monad-control >=1.0 && <1.1,\r\n        mtl >=2.0 && <3.0,\r\n        retry >=0.8 && <0.10,\r\n        template-haskell >=2.19 && <2.25,\r\n        text >=0.2 && <2.2,\r\n        transformers >=0.5.3.0 && <0.7,\r\n        transformers-base,\r\n        unliftio-core >=0.1.1 && <0.3\r\n\r\n    if flag(dev)\r\n        ghc-options:\r\n            -Wall -Werror -Wpartial-fields -Wunused-packages\r\n            -Wno-unused-imports\r\n\r\n    else\r\n        ghc-options: -O2 -Wall\r\n\r\ntest-suite pure-tests\r\n    type:               exitcode-stdio-1.0\r\n    main-is:            Spec.hs\r\n    build-tool-depends: hspec-discover:hspec-discover >=2 && <3\r\n    hs-source-dirs:     pure-tests\r\n    other-modules:      Network.HTTP.ReqSpec\r\n    default-language:   GHC2021\r\n    build-depends:\r\n        QuickCheck >=2.7 && <3,\r\n        aeson >=0.9 && <3,\r\n        base >=4.15 && <5.0,\r\n        blaze-builder >=0.3 && <0.5,\r\n        bytestring >=0.10.8 && <0.13,\r\n        case-insensitive >=0.2 && <1.3,\r\n        hspec >=2.0 && <3,\r\n        hspec-core >=2.0 && <3,\r\n        http-api-data >=0.2 && <0.8,\r\n        http-client >=0.7 && <0.8,\r\n        http-types >=0.8 && <1,\r\n        modern-uri >=0.3 && <0.4,\r\n        req,\r\n        retry >=0.8 && <0.10,\r\n        template-haskell >=2.19 && <2.25,\r\n        text >=0.2 && <2.2,\r\n        time >=1.2 && <1.16\r\n\r\n    if flag(dev)\r\n        ghc-options:\r\n            -Wall -Werror -Wredundant-constraints -Wpartial-fields\r\n            -Wunused-packages\r\n\r\n    else\r\n        ghc-options: -O2 -Wall\r\n\r\ntest-suite httpbin-tests\r\n    type:               exitcode-stdio-1.0\r\n    main-is:            Spec.hs\r\n    build-tool-depends: hspec-discover:hspec-discover >=2 && <3\r\n    hs-source-dirs:     httpbin-tests\r\n    other-modules:      Network.HTTP.ReqSpec\r\n    default-language:   GHC2021\r\n    build-depends:\r\n        QuickCheck >=2.7 && <3,\r\n        aeson >=2 && <3,\r\n        base >=4.15 && <5,\r\n        bytestring >=0.10.8 && <0.13,\r\n        hspec >=2.0 && <3.0,\r\n        http-client >=0.7 && <0.8,\r\n        http-types >=0.8 && <1,\r\n        monad-control >=1.0 && <1.1,\r\n        req,\r\n        text >=0.2 && <2.2\r\n\r\n    if flag(dev)\r\n        ghc-options:\r\n            -Wall -Werror -Wredundant-constraints -Wpartial-fields\r\n            -Wunused-packages\r\n\r\n    else\r\n        buildable: False\r\n";
  }