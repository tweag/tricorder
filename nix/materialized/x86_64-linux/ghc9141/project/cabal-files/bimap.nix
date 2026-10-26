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
      identifier = { name = "bimap"; version = "0.5.0"; };
      license = "BSD-3-Clause";
      copyright = "Stuart Cook and contributors 2008, Joel Williamson 2015";
      maintainer = "Joel Williamson <joel@joelwilliamson.ca>";
      author = "Stuart Cook and contributors 2008, Joel Williamson 2015";
      homepage = "https://github.com/joelwilliamson/bimap";
      url = "";
      synopsis = "Bidirectional mapping between two key types";
      description = "A data structure representing a bidirectional mapping between two\nkey types. Each value in the bimap is associated with exactly one\nvalue of the opposite type.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "7.6.1") (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "7.6.1") (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/bimap-0.5.0.tar.gz";
      sha256 = "b0b44b0f2eaceb83f46dfa3d1747e080c45204c64d18bb9e63747299266f0c95";
    });
  }) // {
    package-description-override = "cabal-version:       >= 1.10\nname:                bimap\nversion:             0.5.0\nsynopsis:            Bidirectional mapping between two key types\ndescription:\n  A data structure representing a bidirectional mapping between two\n  key types. Each value in the bimap is associated with exactly one\n  value of the opposite type.\ncategory:            Data\nlicense:             BSD3\nlicense-file:        LICENSE\ncopyright:           Stuart Cook and contributors 2008, Joel Williamson 2015\nauthor:              Stuart Cook and contributors 2008, Joel Williamson 2015\nmaintainer:          Joel Williamson <joel@joelwilliamson.ca>\nhomepage:            https://github.com/joelwilliamson/bimap\nbuild-type:          Simple\ntested-with:         GHC <= 8.6.4 && >= 7.0\nextra-source-files:\n    HISTORY\n\nLibrary\n  build-depends:       base >= 4 && <5, containers, deepseq, exceptions\n  if impl(ghc < 7.6.1)\n    build-depends: ghc-prim\n    default-extensions:  CPP\n                         DeriveGeneric\n                         TypeFamilies\n  else\n    default-extensions: CPP\n                        TypeFamilies\n  default-language:    Haskell98   \n  ghc-options:         -Wall\n  exposed-modules:\n      Data.Bimap\n\n  if impl(ghc >= 7.8)\n    other-modules:\n      Data.BimapExt\n\ntest-suite tests\n    type:            exitcode-stdio-1.0\n    main-is:         Test/RunTests.hs\n    other-modules:   Test.Tests\n                     Test.Util\n    build-depends:   base >= 4 && < 5,\n                     containers,\n                     deepseq,\n                     exceptions,\n                     QuickCheck >= 2 && < 3,\n                     template-haskell >= 2 && < 3\n    if impl(ghc < 7.6.1)\n      build-depends: ghc-prim\n  default-extensions:  TemplateHaskell\n  default-language:    Haskell98   \n\nsource-repository head\n    type:         git\n    location:     https://github.com/joelwilliamson/bimap.git\n";
  }