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
      identifier = { name = "colour"; version = "2.3.7"; };
      license = "MIT";
      copyright = "";
      maintainer = "Russell O'Connor <roconnor@theorem.ca>";
      author = "Russell O'Connor";
      homepage = "http://www.haskell.org/haskellwiki/Colour";
      url = "";
      synopsis = "A model for human colour/color perception";
      description = "This package provides a data type for colours and transparency.\nColours can be blended and composed.\nVarious colour spaces are supported.\nA module of colour names (\"Data.Colour.Names\") is provided.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
      tests = {
        "test-colour" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."colour" or (errorHandler.buildDepError "colour"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."test-framework" or (errorHandler.buildDepError "test-framework"))
            (hsPkgs."test-framework-quickcheck2" or (errorHandler.buildDepError "test-framework-quickcheck2"))
            (hsPkgs."test-framework-hunit" or (errorHandler.buildDepError "test-framework-hunit"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/colour-2.3.7.tar.gz";
      sha256 = "1f3b1055675abe4e3362800cc9bf7ab9b92dfdf21a1f6c82b252611270be9680";
    });
  }) // {
    package-description-override = "Name:                colour\nVersion:             2.3.7\nCabal-Version:       >= 1.10\nLicense:             MIT\nLicense-file:        LICENSE\nAuthor:              Russell O'Connor\nMaintainer:          Russell O'Connor <roconnor@theorem.ca>\nHomepage:            http://www.haskell.org/haskellwiki/Colour\nBuild-Type:          Simple\nCategory:            data, graphics\nSynopsis:            A model for human colour/color perception\nDescription:         This package provides a data type for colours and transparency.\n                     Colours can be blended and composed.\n                     Various colour spaces are supported.\n                     A module of colour names (\"Data.Colour.Names\") is provided.\nTested-with:         GHC == 9.10.3\ndata-files:          README CHANGELOG\n\nLibrary\n  default-language:  Haskell98\n  Build-Depends:     base >= 4.13 && < 5\n  Exposed-Modules:   Data.Colour\n                     Data.Colour.SRGB\n                     Data.Colour.SRGB.Linear\n                     Data.Colour.CIE\n                     Data.Colour.CIE.Illuminant\n                     Data.Colour.RGBSpace\n                     Data.Colour.RGBSpace.HSL\n                     Data.Colour.RGBSpace.HSV\n                     Data.Colour.Names\n                     Data.Colour.Ok\n  Other-Modules:     Data.Colour.Internal\n                     Data.Colour.Chan\n                     Data.Colour.RGB\n                     Data.Colour.Matrix\n                     Data.Colour.CIE.Chromaticity\ntest-suite test-colour\n  default-language:  Haskell98\n  type:              exitcode-stdio-1.0\n  main-is:           Tests.hs\n  build-depends: base >= 4.13 && < 5,\n                 colour,\n                 QuickCheck >= 2.5 && < 2.16,\n                 random >= 1.0 && < 1.3,\n                 test-framework >= 0.8 && < 0.9,\n                 test-framework-quickcheck2 >= 0.3 && < 0.4,\n                 test-framework-hunit >= 0.3 && < 0.4,\n                 HUnit >= 1.4 && <1.7\n  Other-Modules:   Data.Colour\n                   Data.Colour.SRGB\n                   Data.Colour.SRGB.Linear\n                   Data.Colour.CIE\n                   Data.Colour.CIE.Illuminant\n                   Data.Colour.Ok\n                   Data.Colour.RGBSpace\n                   Data.Colour.RGBSpace.HSL\n                   Data.Colour.RGBSpace.HSV\n                   Data.Colour.Names\n                   Data.Colour.Internal\n                   Data.Colour.Chan\n                   Data.Colour.RGB\n                   Data.Colour.Matrix\n                   Data.Colour.CIE.Chromaticity\n";
  }