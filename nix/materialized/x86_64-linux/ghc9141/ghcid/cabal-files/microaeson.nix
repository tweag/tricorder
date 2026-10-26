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
      specVersion = "2.0";
      identifier = { name = "microaeson"; version = "0.1.0.3"; };
      license = "GPL-3.0-only";
      copyright = "";
      maintainer = "Andreas Abel";
      author = "Herbert Valerio Riedel";
      homepage = "";
      url = "";
      synopsis = "A tiny JSON library with light dependency footprint";
      description = "@microaeson@ aims to provide a [RFC 8259](https://tools.ietf.org/html/rfc8259) compliant JavaScript Object Notation (JSON) implementation.\nThe [microaeson](https://hackage.haskell.org/package/microaeson) package provides a smaller subset of the [aeson](https://hackage.haskell.org/package/aeson) API with less dependencies and a simpler implementation.\n\nThe API is designed in such a way to allow to easily convert client code written against @microaeson@'s API to use the full [aeson](https://hackage.haskell.org/package/aeson) API.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        build-tools = [
          (hsPkgs.pkgsBuildBuild.alex.components.exes.alex or (pkgs.pkgsBuildBuild.alex or (errorHandler.buildToolDepError "alex:alex")))
        ];
        buildable = true;
      };
      tests = {
        "microaeson" = {
          depends = [
            (hsPkgs."microaeson" or (errorHandler.buildDepError "microaeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/microaeson-0.1.0.3.tar.gz";
      sha256 = "c63ca8f8f292d72bb90503fa526c858a4ab67d706485238866ff186f257d5613";
    });
  }) // {
    package-description-override = "cabal-version:       2.0\r\nname:                microaeson\r\nversion:             0.1.0.3\r\nx-revision: 2\r\n\r\nsynopsis:            A tiny JSON library with light dependency footprint\r\nlicense:             GPL-3\r\nlicense-file:        LICENSE\r\nauthor:              Herbert Valerio Riedel\r\nmaintainer:          Andreas Abel\r\ncategory:            Text, Web, JSON\r\nbuild-type:          Simple\r\ndescription: {\r\n\r\n@microaeson@ aims to provide a [RFC 8259](https://tools.ietf.org/html/rfc8259) compliant JavaScript Object Notation (JSON) implementation.\r\n\r\nThe [microaeson](https://hackage.haskell.org/package/microaeson) package provides a smaller subset of the [aeson](https://hackage.haskell.org/package/aeson) API with less dependencies and a simpler implementation.\r\n.\r\nThe API is designed in such a way to allow to easily convert client code written against @microaeson@'s API to use the full [aeson](https://hackage.haskell.org/package/aeson) API.\r\n\r\n}\r\n\r\ntested-with:\r\n  GHC == 9.14.1\r\n  GHC == 9.12.2\r\n  GHC == 9.10.2\r\n  GHC == 9.8.4\r\n  GHC == 9.6.7\r\n  GHC == 9.4.8\r\n  GHC == 9.2.8\r\n  GHC == 9.0.2\r\n  GHC == 8.10.7\r\n  GHC == 8.8.4\r\n  GHC == 8.6.5\r\n  GHC == 8.4.4\r\n  GHC == 8.2.2\r\n  GHC == 8.0.2\r\n\r\nextra-doc-files:\r\n  CHANGELOG.md\r\n  README.md\r\n\r\nsource-repository head\r\n  type:              git\r\n  location:          https://github.com/haskell-hvr/microaeson.git\r\n\r\nlibrary\r\n  default-language:  Haskell2010\r\n  other-extensions:  CPP\r\n                     DeriveDataTypeable\r\n                     DeriveGeneric\r\n                     FlexibleInstances\r\n                     GeneralizedNewtypeDeriving\r\n                     MagicHash\r\n                     OverloadedStrings\r\n\r\n  hs-source-dirs:    src\r\n\r\n  exposed-modules:   Data.Aeson.Micro\r\n  other-modules:     Data.Aeson.Micro.Parser\r\n                     Data.Aeson.Micro.Scanner\r\n\r\n  build-depends:     array      ^>= 0.5.1.1\r\n                   , base        >= 4.9.0.0  && < 5\r\n                   , bytestring  >= 0.10.8.0 && < 0.13\r\n                   , containers  >= 0.5.7.1  && < 1\r\n                   , deepseq     >= 1.4.2.0  && < 1.6\r\n                   , text        >= 1.2.2.2 && < 1.3 || >= 2.0 && < 3\r\n\r\n  build-tool-depends: alex:alex  >= 3.2.0\r\n\r\n  ghc-options:\r\n      -Wall\r\n      -Wcompat\r\n      -Wnoncanonical-monad-instances\r\n\r\n  if impl(ghc < 8.8)\r\n    ghc-options:\r\n      -Wnoncanonical-monadfail-instances\r\n\r\ntest-suite microaeson\r\n  default-language:  Haskell2010\r\n\r\n  hs-source-dirs:    src-tests\r\n  main-is:           tests.hs\r\n\r\n  type:              exitcode-stdio-1.0\r\n\r\n  -- internal dependency\r\n  build-depends:     microaeson\r\n\r\n  -- constraints inherited via lib:microaeson component\r\n  build-depends:     base\r\n                   , containers\r\n\r\n  -- dependencies requiring constraints\r\n  build-depends:     aeson                 >= 2.0.3.0 && < 2.4\r\n                   , quickcheck-instances ^>= 0.3.16\r\n                                       || ^>= 0.4\r\n                   , tasty                 >= 1.0.1.1 && < 1.6\r\n                   , tasty-quickcheck      >= 0.10    && < 1\r\n                   , vector               ^>= 0.12.0.1\r\n                                       || ^>= 0.13.0.0\r\n\r\n\r\n  ghc-options:\r\n      -Wall\r\n      -Wcompat\r\n      -Wnoncanonical-monad-instances\r\n\r\n  if impl(ghc < 8.8)\r\n    ghc-options:\r\n      -Wnoncanonical-monadfail-instances\r\n";
  }