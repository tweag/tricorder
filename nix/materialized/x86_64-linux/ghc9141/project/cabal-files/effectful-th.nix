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
      specVersion = "3.8";
      identifier = { name = "effectful-th"; version = "1.0.0.4"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "andrzej@rybczak.net";
      author = "Andrzej Rybczak";
      homepage = "";
      url = "";
      synopsis = "Template Haskell utilities for the effectful library.";
      description = "Generate functions for performing operations of dynamically dispatched effects\nvia Template Haskell.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."th-abstraction" or (errorHandler.buildDepError "th-abstraction"))
        ];
        buildable = true;
      };
      tests = {
        "th-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
            (hsPkgs."effectful-th" or (errorHandler.buildDepError "effectful-th"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/effectful-th-1.0.0.4.tar.gz";
      sha256 = "bf844aee2fb148e4fe8b016684bf50775860f1bf3c7faf56286151a9ac557f5c";
    });
  }) // {
    package-description-override = "cabal-version:      3.8\nbuild-type:         Simple\nname:               effectful-th\nversion:            1.0.0.4\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\ncategory:           Control\nmaintainer:         andrzej@rybczak.net\nauthor:             Andrzej Rybczak\nsynopsis:           Template Haskell utilities for the effectful library.\n\ndescription:\n  Generate functions for performing operations of dynamically dispatched effects\n  via Template Haskell.\n\nextra-source-files:\n  CHANGELOG.md\n  README.md\n\ntested-with: GHC == { 9.6.7, 9.8.4, 9.10.3, 9.12.4, 9.14.1 }\n\nbug-reports:   https://github.com/haskell-effectful/effectful/issues\nsource-repository head\n  type:     git\n  location: https://github.com/haskell-effectful/effectful.git\n\ncommon language\n    ghc-options:        -Wall\n                        -Wcompat\n                        -Werror=missing-deriving-strategies\n                        -Werror=prepositive-qualified-module\n\n    default-language:   GHC2021\n\n    default-extensions: DataKinds\n                        DeepSubsumption\n                        DerivingStrategies\n                        DuplicateRecordFields\n                        LambdaCase\n                        NoFieldSelectors\n                        NoStarIsType\n                        OverloadedRecordDot\n                        RoleAnnotations\n                        TypeFamilies\n                        UndecidableInstances\n\nlibrary\n    import:         language\n\n    build-depends:    base                >= 4.18      && < 5\n                    , containers          >= 0.6\n                    , effectful-core      >= 1.0.0.0   && < 3.0.0.0\n                    , template-haskell    >= 2.20      && < 2.25\n                    , th-abstraction      >= 0.6       && < 0.8\n\n    hs-source-dirs:  src\n\n    exposed-modules: Effectful.TH\n\ntest-suite th-tests\n    import:         language\n\n    build-depends:    base\n                    , effectful-core\n                    , effectful-th\n                    , template-haskell\n\n    hs-source-dirs: tests\n\n    type:           exitcode-stdio-1.0\n    main-is:        ThTests.hs\n";
  }