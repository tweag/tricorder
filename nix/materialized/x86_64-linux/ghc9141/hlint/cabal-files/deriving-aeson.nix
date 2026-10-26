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
      identifier = { name = "deriving-aeson"; version = "0.2.10"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (c) 2020 Fumiaki Kinoshita";
      maintainer = "fumiexcel@gmail.com";
      author = "Fumiaki Kinoshita";
      homepage = "";
      url = "";
      synopsis = "Type driven generic aeson instance customisation";
      description = "This package provides a newtype wrapper with\nFromJSON/ToJSON instances customisable via a phantom type parameter.\nThe instances can be rendered to the original type using DerivingVia.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."deriving-aeson" or (errorHandler.buildDepError "deriving-aeson"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/deriving-aeson-0.2.10.tar.gz";
      sha256 = "3afb52ac0a82f543783cdd683b6e1aa9ea7ab018ca0a020ccdd269f74ff03677";
    });
  }) // {
    package-description-override = "cabal-version:       2.4\nname:                deriving-aeson\nversion:             0.2.10\nsynopsis:            Type driven generic aeson instance customisation\ndescription:         This package provides a newtype wrapper with\n  FromJSON/ToJSON instances customisable via a phantom type parameter.\n  The instances can be rendered to the original type using DerivingVia.\nbug-reports:         https://github.com/fumieval/deriving-aeson\nlicense:             BSD-3-Clause\nlicense-file:        LICENSE\nauthor:              Fumiaki Kinoshita\nmaintainer:          fumiexcel@gmail.com\ncopyright:           Copyright (c) 2020 Fumiaki Kinoshita\ncategory:            JSON, Generics\nextra-source-files:  CHANGELOG.md, README.md\ntested-with:         GHC == 8.6.5, GHC == 8.8.3, GHC == 8.10.7, GHC == 9.2.5, GHC == 9.4.4\n\nsource-repository head\n  type: git\n  location: https://github.com/fumieval/deriving-aeson.git\n\nlibrary\n  exposed-modules:\n    Deriving.Aeson\n    Deriving.Aeson.Stock\n  build-depends:       base >= 4.12 && <5, aeson >= 1.4.7.0 && <2.3\n  hs-source-dirs: src\n  default-language:    Haskell2010\n  ghc-options: -Wall -Wcompat\n\ntest-suite test\n  type: exitcode-stdio-1.0\n  main-is: test.hs\n  build-depends: base, aeson, deriving-aeson, bytestring\n  hs-source-dirs: tests\n  default-language:    Haskell2010\n";
  }