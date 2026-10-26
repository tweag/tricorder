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
      identifier = { name = "cookie"; version = "0.5.1"; };
      license = "MIT";
      copyright = "";
      maintainer = "Michael Snoyman <michael@snoyman.com>";
      author = "Michael Snoyman <michael@snoyman.com>";
      homepage = "https://github.com/snoyberg/cookie";
      url = "";
      synopsis = "HTTP cookie parsing and rendering";
      description = "Hackage documentation generation is not reliable. For up to date documentation, please see: <https://www.stackage.org/package/cookie>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."data-default-class" or (errorHandler.buildDepError "data-default-class"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."cookie" or (errorHandler.buildDepError "cookie"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/cookie-0.5.1.tar.gz";
      sha256 = "1adde62726e3a3bbe147c02514fe0c4f5f2c5a2ff63842deac10c451a2a6f7a0";
    });
  }) // {
    package-description-override = "cabal-version:   >= 1.10\nname:            cookie\nversion:         0.5.1\nlicense:         MIT\nlicense-file:    LICENSE\nauthor:          Michael Snoyman <michael@snoyman.com>\nmaintainer:      Michael Snoyman <michael@snoyman.com>\nsynopsis:        HTTP cookie parsing and rendering\ndescription:     Hackage documentation generation is not reliable. For up to date documentation, please see: <https://www.stackage.org/package/cookie>.\ncategory:        Web, Yesod\nstability:       Stable\nbuild-type:      Simple\nhomepage:        https://github.com/snoyberg/cookie\nextra-source-files: README.md ChangeLog.md\n\nlibrary\n    default-language: Haskell2010\n    build-depends:   base                      >= 4        && < 5\n                   , bytestring                >= 0.10.2\n                   , time                      >= 1.5\n                   , text                      >= 1.1\n                   , data-default-class\n                   , deepseq\n    exposed-modules: Web.Cookie\n    ghc-options:     -Wall\n\ntest-suite test\n    default-language: Haskell2010\n    hs-source-dirs: test\n    main-is: Spec.hs\n    type: exitcode-stdio-1.0\n    build-depends: base\n                 , HUnit\n                 , QuickCheck\n                 , bytestring >= 0.10.2\n                 , cookie\n                 , tasty\n                 , tasty-hunit\n                 , tasty-quickcheck\n                 , text >= 1.1\n                 , time >= 1.5\n\nsource-repository head\n  type:     git\n  location: https://github.com/snoyberg/cookie.git\n";
  }