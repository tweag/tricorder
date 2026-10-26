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
      identifier = { name = "fuzzy"; version = "0.1.1.0"; };
      license = "MIT";
      copyright = "";
      maintainer = "joomy@cattheory.com";
      author = "Joomy Korkut";
      homepage = "http://github.com/joom/fuzzy";
      url = "";
      synopsis = "Filters a list based on a fuzzy string search.";
      description = "";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."monoid-subclasses" or (errorHandler.buildDepError "monoid-subclasses"))
        ];
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."fuzzy" or (errorHandler.buildDepError "fuzzy"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/fuzzy-0.1.1.0.tar.gz";
      sha256 = "3b0396f1549155431b3db656d2285f8bc4c6a5faa6b3d9f3ea7fbd5757fb8665";
    });
  }) // {
    package-description-override = "name:                fuzzy\nversion:             0.1.1.0\nsynopsis:            Filters a list based on a fuzzy string search.\nhomepage:            http://github.com/joom/fuzzy\nlicense:             MIT\nlicense-file:        LICENSE\nauthor:              Joomy Korkut\nmaintainer:          joomy@cattheory.com\ncategory:            Text\nbuild-type:          Simple\ncabal-version:       >=1.10\n\nlibrary\n  exposed-modules:     Text.Fuzzy\n  build-depends:       base >=4.8 && <5,\n                       monoid-subclasses > 0.4\n  hs-source-dirs:      src\n  default-language:    Haskell2010\n\ntest-suite tests\n  type:                exitcode-stdio-1.0\n  hs-source-dirs:      tests\n  main-is:             tests.hs\n  build-depends:       base,\n                       fuzzy,\n                       HUnit >= 1.2.5.0\n  default-language:    Haskell2010\n";
  }