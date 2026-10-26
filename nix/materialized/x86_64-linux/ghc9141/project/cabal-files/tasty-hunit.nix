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
      identifier = { name = "tasty-hunit"; version = "0.10.2"; };
      license = "MIT";
      copyright = "";
      maintainer = "Roman Cheplyaka <roma@ro-che.info>";
      author = "Roman Cheplyaka <roma@ro-che.info>";
      homepage = "https://github.com/UnkindPartition/tasty";
      url = "";
      synopsis = "HUnit support for the Tasty test framework.";
      description = "HUnit support for the Tasty test framework.\n\nNote that this package does not depend on HUnit but\nimplements the relevant subset of its API. The name is a\nlegacy of the early versions of tasty-hunit and of\ntest-framework-hunit, which did depend on HUnit.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
          (hsPkgs."call-stack" or (errorHandler.buildDepError "call-stack"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tasty-hunit-0.10.2.tar.gz";
      sha256 = "5af01fa7c1ef98b324da062e36f79986a8b1b83ff0cf6fd53f95d976b41e03f6";
    });
  }) // {
    package-description-override = "name:                tasty-hunit\nversion:             0.10.2\nsynopsis:            HUnit support for the Tasty test framework.\ndescription:         HUnit support for the Tasty test framework.\n                     .\n                     Note that this package does not depend on HUnit but\n                     implements the relevant subset of its API. The name is a\n                     legacy of the early versions of tasty-hunit and of\n                     test-framework-hunit, which did depend on HUnit.\nlicense:             MIT\nlicense-file:        LICENSE\nauthor:              Roman Cheplyaka <roma@ro-che.info>\nmaintainer:          Roman Cheplyaka <roma@ro-che.info>\nhomepage:            https://github.com/UnkindPartition/tasty\nbug-reports:         https://github.com/UnkindPartition/tasty/issues\n-- copyright:           \ncategory:            Testing\nbuild-type:          Simple\nextra-source-files:  CHANGELOG.md\ncabal-version:       >=1.10\n\nSource-repository head\n  type:     git\n  location: https://github.com/UnkindPartition/tasty.git\n  subdir:   hunit\n\nlibrary\n  exposed-modules:     Test.Tasty.HUnit\n  other-modules:       Test.Tasty.HUnit.Orig\n                       Test.Tasty.HUnit.Steps\n  other-extensions:    TypeFamilies, DeriveDataTypeable\n  build-depends:       base >= 4.8 && < 5,\n                       tasty >= 1.2.2 && < 1.6,\n                       call-stack < 0.5\n  -- hs-source-dirs:      \n  default-language:    Haskell2010\n  ghc-options: -Wall\n";
  }