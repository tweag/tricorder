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
    flags = { template_haskell = true; };
    package = {
      specVersion = "1.12";
      identifier = { name = "monad-logger"; version = "0.3.42"; };
      license = "MIT";
      copyright = "";
      maintainer = "michael@snoyman.com";
      author = "Michael Snoyman";
      homepage = "https://github.com/snoyberg/monad-logger#readme";
      url = "";
      synopsis = "A class of monads which can log messages.";
      description = "See README and Haddocks at <https://www.stackage.org/package/monad-logger>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
          (hsPkgs."conduit-extra" or (errorHandler.buildDepError "conduit-extra"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."fast-logger" or (errorHandler.buildDepError "fast-logger"))
          (hsPkgs."lifted-base" or (errorHandler.buildDepError "lifted-base"))
          (hsPkgs."monad-control" or (errorHandler.buildDepError "monad-control"))
          (hsPkgs."monad-loops" or (errorHandler.buildDepError "monad-loops"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."stm-chans" or (errorHandler.buildDepError "stm-chans"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."transformers-base" or (errorHandler.buildDepError "transformers-base"))
          (hsPkgs."transformers-compat" or (errorHandler.buildDepError "transformers-compat"))
          (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
        ] ++ pkgs.lib.optional (flags.template_haskell) (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/monad-logger-0.3.42.tar.gz";
      sha256 = "6623446cd42aa1f58a9e21f4abc18cfff13b8991d6ac852d9352d0ffea125010";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.37.0.\n--\n-- see: https://github.com/sol/hpack\n\nname:           monad-logger\nversion:        0.3.42\nsynopsis:       A class of monads which can log messages.\ndescription:    See README and Haddocks at <https://www.stackage.org/package/monad-logger>\ncategory:       System\nhomepage:       https://github.com/snoyberg/monad-logger#readme\nbug-reports:    https://github.com/snoyberg/monad-logger/issues\nauthor:         Michael Snoyman\nmaintainer:     michael@snoyman.com\nlicense:        MIT\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    ChangeLog.md\n    README.md\n\nsource-repository head\n  type: git\n  location: https://github.com/snoyberg/monad-logger\n\nflag template_haskell\n  description: Enable Template Haskell support\n  manual: True\n  default: True\n\nlibrary\n  exposed-modules:\n      Control.Monad.Logger\n  other-modules:\n      Paths_monad_logger\n  build-depends:\n      base >=4.11 && <5\n    , bytestring >=0.10.2\n    , conduit >=1.0 && <1.4\n    , conduit-extra >=1.1 && <1.4\n    , exceptions >=0.6 && <0.11\n    , fast-logger >=2.1 && <3.3\n    , lifted-base\n    , monad-control >=1.0\n    , monad-loops\n    , mtl\n    , resourcet >=1.1 && <1.4\n    , stm\n    , stm-chans\n    , text\n    , transformers\n    , transformers-base\n    , transformers-compat >=0.3\n    , unliftio-core\n  default-language: Haskell2010\n  if impl(ghc >=8.0.1)\n    exposed-modules:\n        Control.Monad.Logger.CallStack\n    cpp-options: -DWITH_CALLSTACK\n  if flag(template_haskell)\n    build-depends:\n        template-haskell\n  if flag(template_haskell)\n    cpp-options: -DWITH_TEMPLATE_HASKELL\n";
  }