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
    flags = { use-text-show = false; };
    package = {
      specVersion = "1.12";
      identifier = { name = "http-api-data"; version = "0.7"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Nickolay Kudasov <nickolay.kudasov@gmail.com>";
      author = "Nickolay Kudasov <nickolay.kudasov@gmail.com>";
      homepage = "http://github.com/fizruk/http-api-data";
      url = "";
      synopsis = "Converting to/from HTTP API data like URL pieces, headers and query parameters.";
      description = "This package defines typeclasses used for converting Haskell data types to and from HTTP API data.\n\nPlease see README.md";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."cookie" or (errorHandler.buildDepError "cookie"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."text-iso8601" or (errorHandler.buildDepError "text-iso8601"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
          (hsPkgs."uuid-types" or (errorHandler.buildDepError "uuid-types"))
        ] ++ pkgs.lib.optional (flags.use-text-show) (hsPkgs."text-show" or (errorHandler.buildDepError "text-show"));
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."cookie" or (errorHandler.buildDepError "cookie"))
            (hsPkgs."http-api-data" or (errorHandler.buildDepError "http-api-data"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."uuid-types" or (errorHandler.buildDepError "uuid-types"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/http-api-data-0.7.tar.gz";
      sha256 = "09460678340e65cc9fe27d3018395a0ee14c64ea65486322b8f5dd2d995b818e";
    });
  }) // {
    package-description-override = "cabal-version:   1.12\r\nname:            http-api-data\r\nversion:         0.7\r\nx-revision: 1\r\n\r\nsynopsis:        Converting to/from HTTP API data like URL pieces, headers and query parameters.\r\ncategory:        Web\r\ndescription:\r\n  This package defines typeclasses used for converting Haskell data types to and from HTTP API data.\r\n  .\r\n  Please see README.md\r\n\r\nlicense:         BSD3\r\nlicense-file:    LICENSE\r\nauthor:          Nickolay Kudasov <nickolay.kudasov@gmail.com>\r\nmaintainer:      Nickolay Kudasov <nickolay.kudasov@gmail.com>\r\nhomepage:        http://github.com/fizruk/http-api-data\r\nstability:       unstable\r\nbuild-type:      Simple\r\n\r\nextra-source-files:\r\n  test/*.hs\r\n  CHANGELOG.md\r\n  README.md\r\n\r\ntested-with:\r\n  GHC==8.6.5,\r\n  GHC==8.8.4,\r\n  GHC==8.10.7,\r\n  GHC==9.0.2,\r\n  GHC==9.2.8,\r\n  GHC==9.4.8,\r\n  GHC==9.6.7,\r\n  GHC==9.8.4,\r\n  GHC==9.10.1,\r\n  GHC==9.12.2\r\n\r\nflag use-text-show\r\n  description: Use text-show library for efficient ToHttpApiData implementations.\r\n  default: False\r\n  manual: True\r\n\r\nlibrary\r\n    hs-source-dirs: src/\r\n\r\n    -- GHC bundled\r\n    build-depends:   base                  >= 4.12.0.0 && < 4.23\r\n                   , bytestring            >= 0.10.8.2 && < 0.13\r\n                   , containers            >= 0.6.0.1  && < 0.9\r\n                   , text                  >= 1.2.3.0  && < 1.3 || >=2.0 && <2.2\r\n\r\n    -- other-dependencies\r\n    build-depends:\r\n                     cookie                >= 0.5.1    && < 0.6\r\n                   , hashable              >= 1.4.4.0  && < 1.6\r\n                   , http-types            >= 0.12.4   && < 0.13\r\n                   , text-iso8601          >= 0.1.1    && < 0.2\r\n                   , tagged                >= 0.8.8    && < 0.9\r\n                   , time-compat           >= 1.9.5    && < 1.10\r\n                   , uuid-types            >= 1.0.6    && < 1.1\r\n\r\n    if flag(use-text-show)\r\n      cpp-options: -DUSE_TEXT_SHOW\r\n      build-depends: text-show        >= 3.10.5 && <3.12\r\n\r\n    exposed-modules:\r\n      Web.HttpApiData\r\n      Web.FormUrlEncoded\r\n      Web.Internal.FormUrlEncoded\r\n      Web.Internal.HttpApiData\r\n    ghc-options:     -Wall\r\n    default-language: Haskell2010\r\n\r\ntest-suite spec\r\n    type:          exitcode-stdio-1.0\r\n    main-is:       Spec.hs\r\n    other-modules:\r\n      Web.Internal.FormUrlEncodedSpec\r\n      Web.Internal.HttpApiDataSpec\r\n      Web.Internal.TestInstances\r\n    hs-source-dirs: test\r\n    ghc-options:   -Wall\r\n    default-language: Haskell2010\r\n    build-tool-depends: hspec-discover:hspec-discover >= 2.7.1 && <2.12\r\n    -- inherited  depndencies\r\n    build-depends:\r\n                     base\r\n                   , bytestring\r\n                   , cookie\r\n                   , http-api-data\r\n                   , text\r\n                   , time-compat\r\n                   , containers\r\n                   , uuid-types\r\n\r\n    build-depends:   hspec                >= 2.7.1    && <2.12\r\n                   , QuickCheck           >= 2.13.1   && <2.16\r\n                   , quickcheck-instances >= 0.3.25.2 && <0.4\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/fizruk/http-api-data\r\n";
  }