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
      specVersion = "2.4";
      identifier = { name = "text-conversions"; version = "0.3.1.1"; };
      license = "ISC";
      copyright = "";
      maintainer = "Alexis King <lexi.lambda@gmail.com>";
      author = "Alexis King";
      homepage = "https://github.com/cjdev/text-conversions";
      url = "";
      synopsis = "Safe conversions between textual types";
      description = "Safe conversions between textual types";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
          (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "text-conversions-test-suite" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-conversions" or (errorHandler.buildDepError "text-conversions"))
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
      url = "http://hackage.haskell.org/package/text-conversions-0.3.1.1.tar.gz";
      sha256 = "c8770fba789ce80334cae628285103c49abec0fa074773cbb5a88e26f5a7725d";
    });
  }) // {
    package-description-override = "cabal-version: 2.4\nname: text-conversions\nversion: 0.3.1.1\ncategory: Data\nbuild-type: Simple\nsynopsis: Safe conversions between textual types\ndescription: Safe conversions between textual types\n\nauthor: Alexis King\nmaintainer: Alexis King <lexi.lambda@gmail.com>\nlicense: ISC\nlicense-file: LICENSE\nextra-source-files:\n  README.md\n  CHANGELOG.md\n  LICENSE\n\nhomepage: https://github.com/cjdev/text-conversions\nbug-reports: https://github.com/cjdev/text-conversions/issues\n\nsource-repository head\n  type: git\n  location: https://github.com/cjdev/text-conversions\n\ncommon common\n  default-language: Haskell2010\n  default-extensions: FlexibleInstances MultiParamTypeClasses OverloadedStrings\n  ghc-options: -Wall\n  if impl(ghc >= 8.0.1)\n    ghc-options: -Wcompat -Wincomplete-record-updates -Wincomplete-uni-patterns -Wredundant-constraints\n\nlibrary\n  import: common\n\n  hs-source-dirs: src\n  exposed-modules:\n    Data.Text.Conversions\n\n  build-depends:\n    , base >=4.7 && <5\n    , base16-bytestring <2\n    , base64-bytestring <2\n    , bytestring <1\n    , text <3\n\ntest-suite text-conversions-test-suite\n  import: common\n  type: exitcode-stdio-1.0\n\n  hs-source-dirs: test\n  main-is: Main.hs\n  other-modules:\n    Data.Text.ConversionsSpec\n\n  ghc-options: -rtsopts -threaded -with-rtsopts=-N\n\n  build-depends:\n    , base\n    , bytestring\n    , hspec\n    , text\n    , text-conversions\n  build-tool-depends:\n    hspec-discover:hspec-discover\n";
  }