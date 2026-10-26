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
      specVersion = "3.0";
      identifier = { name = "granite"; version = "0.7.4.0"; };
      license = "MIT";
      copyright = "(c) 2024-2025 Michael Chavinda";
      maintainer = "mschavinda@gmail.com";
      author = "Michael Chavinda";
      homepage = "";
      url = "";
      synopsis = "Easy terminal plotting.";
      description = "A terminal plotting library for quick and easy visualisation.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      exes = {
        "granite" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."granite" or (errorHandler.buildDepError "granite"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
      tests = {
        "granite-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."granite" or (errorHandler.buildDepError "granite"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
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
      url = "http://hackage.haskell.org/package/granite-0.7.4.0.tar.gz";
      sha256 = "1f814359b21cd670e4974eb7b18cc105009f111edc1c6d7feb9c7115bd93e1a5";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\nname:               granite\nversion:            0.7.4.0\nsynopsis:           Easy terminal plotting.\ndescription:        A terminal plotting library for quick and easy visualisation.\nlicense:            MIT\nlicense-file:       LICENSE\nauthor:             Michael Chavinda\ntested-with:        GHC ==9.4.8\n                     || ==9.6.7\n                     || ==9.8.4\n                     || ==9.10.3\n                     || ==9.12.4\n                     || ==9.14.1\n\nmaintainer:         mschavinda@gmail.com\ncopyright:          (c) 2024-2025 Michael Chavinda\nbug-reports:        https://github.com/mchav/granite/issues\ncategory:           Graphics\nbuild-type:         Simple\nextra-doc-files:    CHANGELOG.md README.md\nextra-source-files: test/golden/*.txt\n                    test/golden/*.svg\n\nsource-repository head\n  type:     git\n  location: https://github.com/mchav/granite\n\ncommon ghc-options\n    ghc-options:\n        -Wall\n        -Wcompat\n        -Widentities\n        -Wincomplete-record-updates\n        -Wincomplete-uni-patterns\n        -Winvalid-haddock\n        -Wno-unticked-promoted-constructors\n        -Wno-unused-do-bind\n        -Wpartial-fields\n        -Wredundant-constraints\n        -Wunused-packages\n        -fhide-source-paths\n        -funbox-strict-fields\n\nlibrary\n    import:           ghc-options\n    exposed-modules:  Granite,\n                      Granite.Chart,\n                      Granite.Color,\n                      Granite.Data.Frame,\n                      Granite.Flame,\n                      Granite.Format,\n                      Granite.Position,\n                      Granite.Render.Chrome,\n                      Granite.Render.Pipeline,\n                      Granite.Render.Scene,\n                      Granite.Render.Svg,\n                      Granite.Render.Terminal,\n                      Granite.Scale,\n                      Granite.Spec,\n                      Granite.Stat,\n                      Granite.String,\n                      Granite.Svg\n    other-modules:    Granite.Internal.LegacyChart,\n                      Granite.Internal.Util\n    build-depends:\n        base >=4 && <5,\n        text >= 1 && < 3\n    hs-source-dirs:   src\n    default-language: GHC2021\n\nexecutable granite\n    main-is:          Main.hs\n    build-depends:\n        base >=4 && <5,\n        granite ^>= 0.7,\n        text >= 1 && < 3\n    hs-source-dirs:   app\n    default-language: GHC2021\n\ntest-suite granite-test\n    import: ghc-options\n    type: exitcode-stdio-1.0\n    default-language: GHC2021\n    main-is: Spec.hs\n\n    other-modules:\n        FlameSpec\n        Golden\n        GoldenSpec\n        GraniteSpec\n        PipelineSpec\n        PlotlySpec\n        PositionSpec\n        RenderSpec\n        ScaleSpec\n        SpecPropSpec\n        StatSpec\n\n    build-depends:\n        base >= 4.14 && < 5\n        , granite ^>= 0.7\n        , text >= 1.2 && < 3\n        , hspec >= 2.7 && < 2.12\n        , QuickCheck >= 2.14 && < 3\n\n    hs-source-dirs: test\n\n    build-tool-depends:\n        hspec-discover:hspec-discover >= 2.7\n";
  }