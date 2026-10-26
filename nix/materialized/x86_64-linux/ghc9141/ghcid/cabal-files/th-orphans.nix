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
      identifier = { name = "th-orphans"; version = "0.13.17"; };
      license = "BSD-3-Clause";
      copyright = "(c) Matt Morrow, Michael Sloan, Ryan Scott";
      maintainer = "Ryan Scott <ryan.gl.scott@gmail.com>";
      author = "Matt Morrow, Michael Sloan, Ryan Scott";
      homepage = "";
      url = "";
      synopsis = "Orphan instances for TH datatypes";
      description = "Orphan instances for TH datatypes.  In particular, instances\nfor Ord and Lift, as well as a few missing Show / Eq.  These\ninstances used to live in haskell-src-meta, and that's where\nthe version number started.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."th-compat" or (errorHandler.buildDepError "th-compat"))
          (hsPkgs."th-lift" or (errorHandler.buildDepError "th-lift"))
          (hsPkgs."th-reify-many" or (errorHandler.buildDepError "th-reify-many"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."th-lift" or (errorHandler.buildDepError "th-lift"))
            (hsPkgs."th-orphans" or (errorHandler.buildDepError "th-orphans"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/th-orphans-0.13.17.tar.gz";
      sha256 = "9c67fb484c9f1e7f761ed7de453f73c087c4c46123d9bf41a9038156aa5e9062";
    });
  }) // {
    package-description-override = "name:               th-orphans\nversion:            0.13.17\ncabal-version:      >= 1.10\nbuild-type:         Simple\nlicense:            BSD3\nlicense-file:       LICENSE\ncategory:           Template Haskell\nauthor:             Matt Morrow, Michael Sloan, Ryan Scott\ncopyright:          (c) Matt Morrow, Michael Sloan, Ryan Scott\nmaintainer:         Ryan Scott <ryan.gl.scott@gmail.com>\nbug-reports:        https://github.com/mgsloan/th-orphans/issues\nstability:          experimental\ntested-with:        GHC == 8.0.2\n                  , GHC == 8.2.2\n                  , GHC == 8.4.4\n                  , GHC == 8.6.5\n                  , GHC == 8.8.4\n                  , GHC == 8.10.7\n                  , GHC == 9.0.2\n                  , GHC == 9.2.8\n                  , GHC == 9.4.8\n                  , GHC == 9.6.7\n                  , GHC == 9.8.4\n                  , GHC == 9.10.3\n                  , GHC == 9.12.2\n                  , GHC == 9.14.1\nsynopsis:           Orphan instances for TH datatypes\ndescription:        Orphan instances for TH datatypes.  In particular, instances\n                    for Ord and Lift, as well as a few missing Show / Eq.  These\n                    instances used to live in haskell-src-meta, and that's where\n                    the version number started.\nextra-source-files: CHANGELOG.md, README.md\n\nlibrary\n  build-depends:      base >= 4.9 && < 5,\n                      template-haskell >= 2.11 && < 2.25,\n                      th-compat >= 0.1 && < 0.2,\n                      -- https://github.com/mboes/th-lift/issues/14\n                      th-lift >= 0.7.1,\n                      th-reify-many >= 0.1.9 && < 0.2,\n                      mtl >= 2\n  hs-source-dirs:     src\n  ghc-options:        -Wall\n  if impl(ghc >= 8.6)\n    ghc-options:      -Wno-star-is-type\n  exposed-modules:    Language.Haskell.TH.Instances\n  other-modules:      Language.Haskell.TH.Instances.Internal\n  default-language:   Haskell2010\n\ntest-suite test\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     test\n  main-is:            Spec.hs\n  other-modules:      TestUtil\n  build-depends:      base,\n                      bytestring,\n                      hspec,\n                      template-haskell,\n                      th-lift,\n                      th-orphans\n  build-tool-depends: hspec-discover:hspec-discover\n  default-language:   Haskell2010\n\nsource-repository head\n  type:     git\n  location: https://github.com/mgsloan/th-orphans\n";
  }