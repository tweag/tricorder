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
      identifier = { name = "http-client-tls"; version = "0.3.6.4"; };
      license = "MIT";
      copyright = "";
      maintainer = "michael@snoyman.com";
      author = "Michael Snoyman";
      homepage = "https://github.com/snoyberg/http-client";
      url = "";
      synopsis = "http-client backend using the connection package and tls library";
      description = "Hackage documentation generation is not reliable. For up to date documentation, please see: <https://www.stackage.org/package/http-client-tls>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
          (hsPkgs."crypton-connection" or (errorHandler.buildDepError "crypton-connection"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
            (hsPkgs."http-client-tls" or (errorHandler.buildDepError "http-client-tls"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."crypton-connection" or (errorHandler.buildDepError "crypton-connection"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "benchmark" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."gauge" or (errorHandler.buildDepError "gauge"))
            (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
            (hsPkgs."http-client-tls" or (errorHandler.buildDepError "http-client-tls"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/http-client-tls-0.3.6.4.tar.gz";
      sha256 = "7756006fee8ab924c521372e0f9d6705579016b9fab0b0312d1b9a335cfc18a3";
    });
  }) // {
    package-description-override = "name:                http-client-tls\r\nversion:             0.3.6.4\r\nx-revision: 3\r\nsynopsis:            http-client backend using the connection package and tls library\r\ndescription:         Hackage documentation generation is not reliable. For up to date documentation, please see: <https://www.stackage.org/package/http-client-tls>.\r\nhomepage:            https://github.com/snoyberg/http-client\r\nlicense:             MIT\r\nlicense-file:        LICENSE\r\nauthor:              Michael Snoyman\r\nmaintainer:          michael@snoyman.com\r\ncategory:            Network\r\nbuild-type:          Simple\r\ncabal-version:       >=1.10\r\nextra-source-files:  README.md\r\n                     ChangeLog.md\r\n\r\nlibrary\r\n  exposed-modules:     Network.HTTP.Client.TLS\r\n  other-extensions:    ScopedTypeVariables\r\n  build-depends:       base >= 4.10 && < 5\r\n                     , data-default\r\n                     , http-client >= 0.7.11\r\n                     , crypton-connection\r\n                     , network\r\n                     , tls (>=1.2 && < 2.1) || >= 2.1.2\r\n                     , bytestring\r\n                     , case-insensitive\r\n                     , transformers\r\n                     , http-types\r\n                     , crypton < 1.1\r\n                     , memory\r\n                     , exceptions\r\n                     , containers\r\n                     , text\r\n                     , network-uri\r\n  default-language:    Haskell2010\r\n  ghc-options:         -Wall\r\n\r\ntest-suite spec\r\n  main-is:             Spec.hs\r\n  type:                exitcode-stdio-1.0\r\n  hs-source-dirs:      test\r\n  default-language:    Haskell2010\r\n  build-depends:       base\r\n                     , hspec\r\n                     , http-client\r\n                     , http-client-tls\r\n                     , http-types\r\n                     , crypton-connection\r\n\r\nbenchmark benchmark\r\n  main-is:             Bench.hs\r\n  type:                exitcode-stdio-1.0\r\n  hs-source-dirs:      bench\r\n  default-language:    Haskell2010\r\n  build-depends:       base\r\n                     , gauge\r\n                     , http-client\r\n                     , http-client-tls\r\n";
  }