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
    flags = { pedantic = false; };
    package = {
      specVersion = "2.4";
      identifier = { name = "hls-test-utils"; version = "2.15.0.0"; };
      license = "Apache-2.0";
      copyright = "The Haskell IDE Team";
      maintainer = "alan.zimm@gmail.com";
      author = "The Haskell IDE Team";
      homepage = "https://github.com/haskell/haskell-language-server#readme";
      url = "";
      synopsis = "Utilities used in the tests of Haskell Language Server";
      description = "Please see the README on GitHub at <https://github.com/haskell/haskell-language-server#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
          (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
          (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
          (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
          (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
          (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
          (hsPkgs."string-interpolate" or (errorHandler.buildDepError "string-interpolate"))
          (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
          (hsPkgs."tasty-expected-failure" or (errorHandler.buildDepError "tasty-expected-failure"))
          (hsPkgs."tasty-golden" or (errorHandler.buildDepError "tasty-golden"))
          (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          (hsPkgs."tasty-rerun" or (errorHandler.buildDepError "tasty-rerun"))
          (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hls-test-utils-2.15.0.0.tar.gz";
      sha256 = "b2ba501898957ee959f7a631accc5d2b59fbc46c95f657fbcfcf63aebe07eed5";
    });
  }) // {
    package-description-override = "cabal-version: 2.4\nname:          hls-test-utils\nversion:       2.15.0.0\nsynopsis:      Utilities used in the tests of Haskell Language Server\ndescription:\n  Please see the README on GitHub at <https://github.com/haskell/haskell-language-server#readme>\n\nhomepage:      https://github.com/haskell/haskell-language-server#readme\nbug-reports:   https://github.com/haskell/haskell-language-server/issues\nlicense:       Apache-2.0\nlicense-file:  LICENSE\nauthor:        The Haskell IDE Team\nmaintainer:    alan.zimm@gmail.com\ncopyright:     The Haskell IDE Team\ncategory:      Development\nbuild-type:    Simple\n\nflag pedantic\n  description: Enable -Werror\n  default:     False\n  manual:      True\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell/haskell-language-server\n\nlibrary\n  exposed-modules:\n    Test.Hls\n    Test.Hls.FileSystem\n    Test.Hls.TestEnv\n    Test.Hls.Util\n    Development.IDE.Test\n    Development.IDE.Test.Diagnostic\n\n  hs-source-dirs:   src\n  build-depends:\n    , aeson\n    , async\n    , base                    >=4.12 && <5\n    , bytestring\n    , containers\n    , data-default\n    , directory\n    , extra\n    , filepath\n    , ghcide                  == 2.15.0.0\n    , hls-plugin-api          == 2.15.0.0\n    , lens\n    , lsp\n    , lsp-test                ^>=0.18\n    , lsp-types               ^>=2.4\n    , primitive\n    , safe-exceptions\n    , string-interpolate      >= 0.3.1\n    , tasty\n    , tasty-expected-failure\n    , tasty-golden\n    , tasty-hunit\n    , tasty-rerun\n    , temporary\n    , text\n    , text-rope\n\n  ghc-options:\n    -Wall\n    -Wunused-packages\n    -Wno-name-shadowing\n    -Wno-unticked-promoted-constructors\n\n  if flag(pedantic)\n    ghc-options: -Werror\n\n  default-language: GHC2021\n";
  }