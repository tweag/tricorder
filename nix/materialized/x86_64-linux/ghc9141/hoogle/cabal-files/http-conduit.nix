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
    flags = { aeson = true; };
    package = {
      specVersion = "1.10";
      identifier = { name = "http-conduit"; version = "2.3.9.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Michael Snoyman <michael@snoyman.com>";
      author = "Michael Snoyman <michael@snoyman.com>";
      homepage = "https://github.com/snoyberg/http-client";
      url = "";
      synopsis = "HTTP client package with conduit interface and HTTPS support.";
      description = "Hackage documentation generation is not reliable. For up to date documentation, please see: <http://www.stackage.org/package/http-conduit>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
          (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
          (hsPkgs."conduit-extra" or (errorHandler.buildDepError "conduit-extra"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
          (hsPkgs."http-client-tls" or (errorHandler.buildDepError "http-client-tls"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
        ] ++ pkgs.lib.optionals (flags.aeson) [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."attoparsec-aeson" or (errorHandler.buildDepError "attoparsec-aeson"))
        ]) ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "7.9")) (hsPkgs."void" or (errorHandler.buildDepError "void"));
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."crypton-connection" or (errorHandler.buildDepError "crypton-connection"))
            (hsPkgs."warp-tls" or (errorHandler.buildDepError "warp-tls"))
            (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
            (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
            (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
            (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
            (hsPkgs."wai-conduit" or (errorHandler.buildDepError "wai-conduit"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."cookie" or (errorHandler.buildDepError "cookie"))
            (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
            (hsPkgs."http-conduit" or (errorHandler.buildDepError "http-conduit"))
            (hsPkgs."conduit-extra" or (errorHandler.buildDepError "conduit-extra"))
            (hsPkgs."streaming-commons" or (errorHandler.buildDepError "streaming-commons"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
          ] ++ pkgs.lib.optionals (flags.aeson) [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."attoparsec-aeson" or (errorHandler.buildDepError "attoparsec-aeson"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/http-conduit-2.3.9.1.tar.gz";
      sha256 = "13046d15ecd2332a5b80c8a34a6a1b6b8eecefce9d5c57e3413312b8c11641af";
    });
  }) // {
    package-description-override = "cabal-version:   >= 1.10\r\nname:            http-conduit\r\nversion:         2.3.9.1\r\nx-revision: 1\r\nlicense:         BSD3\r\nlicense-file:    LICENSE\r\nauthor:          Michael Snoyman <michael@snoyman.com>\r\nmaintainer:      Michael Snoyman <michael@snoyman.com>\r\nsynopsis:        HTTP client package with conduit interface and HTTPS support.\r\ndescription:         Hackage documentation generation is not reliable. For up to date documentation, please see: <http://www.stackage.org/package/http-conduit>.\r\ncategory:        Web, Conduit\r\nstability:       Stable\r\nbuild-type:      Simple\r\nhomepage:        https://github.com/snoyberg/http-client\r\nextra-source-files: test/main.hs\r\n                  , test/CookieTest.hs\r\n                  , multipart-example.bin\r\n                  , nyan.gif\r\n                  , certificate.pem\r\n                  , key.pem\r\n                  , README.md\r\n                  , ChangeLog.md\r\n\r\nflag aeson\r\n  manual: True\r\n  description: Enable the dependency on aeson\r\n  default: True\r\n\r\nlibrary\r\n    default-language: Haskell2010\r\n    build-depends: base                  >= 4.10    && < 5\r\n                 , attoparsec\r\n                 , bytestring            >= 0.9.1.4\r\n                 , transformers          >= 0.2\r\n                 , resourcet             >= 1.1\r\n                 , conduit               >= 1.2\r\n                 , conduit-extra         >= 1.1\r\n                 , http-types            >= 0.7\r\n                 , http-client           >= 0.5.13  && < 0.8\r\n                 , http-client-tls       >= 0.3     && < 0.5\r\n                 , mtl\r\n                 , unliftio-core\r\n\r\n    if flag(aeson)\r\n      build-depends: aeson                 >= 0.8\r\n                   , attoparsec-aeson      >= 2.1\r\n\r\n    if !impl(ghc>=7.9)\r\n      build-depends:   void >= 0.5.5\r\n    exposed-modules: Network.HTTP.Conduit\r\n                     Network.HTTP.Client.Conduit\r\n                     Network.HTTP.Simple\r\n    ghc-options:     -Wall\r\n\r\ntest-suite test\r\n    default-language: Haskell2010\r\n    main-is: main.hs\r\n    other-modules: CookieTest\r\n    type: exitcode-stdio-1.0\r\n    hs-source-dirs: test\r\n\r\n    ghc-options:   -Wall\r\n    cpp-options:   -DDEBUG\r\n    build-depends: base >= 4 && < 5\r\n                 , HUnit\r\n                 , hspec >= 1.3\r\n                 , data-default\r\n                 , crypton-connection\r\n                 , warp-tls\r\n                 , tls < 1.5 || >= 1.5.2\r\n                 , time\r\n                 , blaze-builder\r\n                 , bytestring\r\n                 , text\r\n                 , transformers\r\n                 , conduit >= 1.1\r\n                 , utf8-string\r\n                 , case-insensitive\r\n                 , unliftio\r\n                 , wai >= 3.0 && < 3.3\r\n                 , warp >= 3.0.0.2 && < 3.4\r\n                 , wai-conduit\r\n                 , http-types\r\n                 , cookie\r\n                 , http-client\r\n                 , http-conduit\r\n                 , conduit-extra\r\n                 , streaming-commons\r\n                 , temporary\r\n                 , resourcet\r\n                 , network\r\n\r\n    if flag(aeson)\r\n      build-depends: aeson\r\n                   , attoparsec-aeson      >= 2.1\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: git://github.com/snoyberg/http-client.git\r\n";
  }