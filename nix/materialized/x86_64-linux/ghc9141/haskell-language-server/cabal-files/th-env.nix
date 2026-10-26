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
      specVersion = "1.12";
      identifier = { name = "th-env"; version = "0.1.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "dima@dzhus.org";
      author = "Dmitry Dzhus";
      homepage = "https://github.com/dzhus/th-env#readme";
      url = "";
      synopsis = "Template Haskell splices that expand to an environment variable";
      description = "TH splices that expand to an environment variable value. Can be used to embed build-time parameters in your application.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."th-compat" or (errorHandler.buildDepError "th-compat"))
        ];
        buildable = true;
      };
      tests = {
        "readme" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."markdown-unlit" or (errorHandler.buildDepError "markdown-unlit"))
            (hsPkgs."th-env" or (errorHandler.buildDepError "th-env"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/th-env-0.1.1.tar.gz";
      sha256 = "fc01b166df6ba45f6ce157165eb786da208dbab41252fd81134f8ba02cf3f505";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.34.4.\n--\n-- see: https://github.com/sol/hpack\n--\n-- hash: 95226380269cc2dc702ac016f5a227875b5724dd211f6548ebc31dbe2a112191\n\nname:           th-env\nversion:        0.1.1\nsynopsis:       Template Haskell splices that expand to an environment variable\ndescription:    TH splices that expand to an environment variable value. Can be used to embed build-time parameters in your application.\ncategory:       Template Haskell\nhomepage:       https://github.com/dzhus/th-env#readme\nbug-reports:    https://github.com/dzhus/th-env/issues\nauthor:         Dmitry Dzhus\nmaintainer:     dima@dzhus.org\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    CHANGELOG.md\n    README.md\n\nsource-repository head\n  type: git\n  location: https://github.com/dzhus/th-env\n\nlibrary\n  exposed-modules:\n      Language.Haskell.TH.Env\n  other-modules:\n      Paths_th_env\n  hs-source-dirs:\n      src\n  ghc-options: -Wall -Wcompat\n  build-depends:\n      base <5\n    , template-haskell\n    , th-compat\n  default-language: Haskell2010\n\ntest-suite readme\n  type: exitcode-stdio-1.0\n  main-is: README.lhs\n  other-modules:\n      Paths_th_env\n  ghc-options: -Wall -Wcompat -pgmL markdown-unlit\n  build-depends:\n      base <5\n    , markdown-unlit\n    , th-env\n  default-language: Haskell2010\n";
  }