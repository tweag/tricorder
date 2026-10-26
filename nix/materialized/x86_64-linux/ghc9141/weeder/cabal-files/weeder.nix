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
      identifier = { name = "weeder"; version = "2.11.0"; };
      license = "BSD-3-Clause";
      copyright = "Neil Mitchell 2017-2020, Oliver Charles 2020-2025";
      maintainer = "Ollie Charles <ollie@ocharles.org.uk>";
      author = "Ollie Charles <ollie@ocharles.org.uk>";
      homepage = "https://github.com/ocharles/weeder#readme";
      url = "";
      synopsis = "Detect dead code";
      description = "Find declarations.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."algebraic-graphs" or (errorHandler.buildDepError "algebraic-graphs"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."generic-lens" or (errorHandler.buildDepError "generic-lens"))
          (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
          (hsPkgs."Glob" or (errorHandler.buildDepError "Glob"))
          (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."parallel" or (errorHandler.buildDepError "parallel"))
          (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."toml-reader" or (errorHandler.buildDepError "toml-reader"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
      exes = {
        "weeder" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."weeder" or (errorHandler.buildDepError "weeder"))
          ];
          buildable = true;
        };
      };
      tests = {
        "weeder-test" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."algebraic-graphs" or (errorHandler.buildDepError "algebraic-graphs"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit-compat" or (errorHandler.buildDepError "tasty-hunit-compat"))
            (hsPkgs."tasty-golden" or (errorHandler.buildDepError "tasty-golden"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."toml-reader" or (errorHandler.buildDepError "toml-reader"))
            (hsPkgs."weeder" or (errorHandler.buildDepError "weeder"))
            (hsPkgs."hspec-expectations" or (errorHandler.buildDepError "hspec-expectations"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
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
      url = "http://hackage.haskell.org/package/weeder-2.11.0.tar.gz";
      sha256 = "fb1fb8a7352a5e5717acda5c88542927fe4a4893c1f2ec274dc1282f52061f3b";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nlicense:       BSD-3-Clause\nlicense-file:  LICENSE\nname:          weeder\nauthor:        Ollie Charles <ollie@ocharles.org.uk>\nmaintainer:    Ollie Charles <ollie@ocharles.org.uk>\nbuild-type:    Simple\nversion:       2.11.0\ncopyright:     Neil Mitchell 2017-2020, Oliver Charles 2020-2025\nsynopsis:      Detect dead code\ndescription:   Find declarations.\nhomepage:      https://github.com/ocharles/weeder#readme\nbug-reports:   https://github.com/ocharles/weeder/issues\ncategory:      Development\nextra-doc-files:\n    README.md\n    CHANGELOG.md\nextra-source-files:\n    test/Spec/*.toml\n    test/Spec/*.stdout\n    test/Spec/*.failing\n\nsource-repository head\n   type:     git\n   location: https://github.com/ocharles/weeder.git\n\nlibrary\n  build-depends:\n    , algebraic-graphs     >= 0.7 && <0.9\n    , async                ^>= 2.2.0\n    , base                 >= 4.17 && < 4.23\n    , bytestring           >= 0.10.9 && < 0.13\n    , containers           >= 0.6.2.1 && < 0.9\n    , directory            ^>= 1.3.3.2\n    , filepath             ^>= 1.4.2.1 || ^>= 1.5\n    , generic-lens         >= 2.2 && <2.4\n    , ghc                  >= 9.4 && < 9.16\n    , Glob                 ^>= 0.9 || ^>= 0.10\n    , lens                 >= 5.1 && < 5.4\n    , mtl                  ^>= 2.2.2 || ^>= 2.3\n    , optparse-applicative >= 0.14.3 && < 0.20\n    , parallel             >= 3.2 && <3.4\n    , regex-tdfa           ^>= 1.2.0.0 || ^>= 1.3.1.0\n    , text                 ^>= 2.0.1 || ^>= 2.1\n    , toml-reader          >= 0.2.0.0 && < 0.3.1\n    , transformers         ^>= 0.5.6.2 || ^>= 0.6\n  hs-source-dirs: src\n  exposed-modules:\n    Weeder\n    Weeder.Config\n    Weeder.Run\n    Weeder.Main\n  autogen-modules:\n    Paths_weeder\n  other-modules:\n    Paths_weeder\n  ghc-options: -Wall -fwarn-incomplete-uni-patterns -threaded\n  default-language: Haskell2010\n\nexecutable weeder\n  build-depends:\n    , base\n    , weeder\n  main-is: Main.hs\n  hs-source-dirs: exe-weeder\n  ghc-options: -Wall -fwarn-incomplete-uni-patterns -threaded -no-rtsopts-suggestions -with-rtsopts=-N -rtsopts\n  default-language: Haskell2010\n\ntest-suite weeder-test\n  build-tool-depends:\n    hspec-discover:hspec-discover\n  build-depends:\n    , aeson\n    , algebraic-graphs\n    , base\n    , containers\n    , directory\n    , filepath\n    , ghc\n    , process\n    , tasty\n    , tasty-hunit-compat\n    , tasty-golden\n    , text\n    , toml-reader\n    , weeder\n    , hspec-expectations\n    , text\n    , bytestring\n  type: exitcode-stdio-1.0\n  main-is: Main.hs\n  hs-source-dirs: test\n  autogen-modules:\n    Paths_weeder\n  other-modules:\n    Paths_weeder\n    -- Tests\n    Spec.ApplicativeDo.ApplicativeDo\n    Spec.BasicExample.BasicExample\n    Spec.ConfigInstanceModules.Module1\n    Spec.ConfigInstanceModules.Module2\n    Spec.ConfigInstanceModules.Module3\n    Spec.DefaultsNotReported.DefaultsNotReported\n    Spec.DeriveGeneric.DeriveGeneric\n    Spec.InstanceRootConstraint.InstanceRootConstraint\n    Spec.InstanceTypeclass.InstanceTypeclass\n    Spec.ModuleRoot.InstanceNotRoot\n    Spec.ModuleRoot.M\n    Spec.Monads.Monads\n    Spec.NumInstance.NumInstance\n    Spec.NumInstanceLiteral.NumInstanceLiteral\n    Spec.OverloadedLabels.OverloadedLabels\n    Spec.OverloadedLists.OverloadedLists\n    Spec.OverloadedStrings.OverloadedStrings\n    Spec.RangeEnum.RangeEnum\n    Spec.RootClasses.RootClasses\n    Spec.SelfWeeding.SelfWeeding\n    Spec.StandaloneDeriving.StandaloneDeriving\n    Spec.TypeAliasGADT.TypeAliasGADT\n    Spec.TypeDataDecl.TypeDataDecl\n    Spec.Types.Types\n    Spec.Types.Usages\n    Spec.TypeFamilies.TypeFamilies\n    Spec.TypeFamilies.TypeFamilyUsage\n    Spec.TypesUnused.TypesUnused\n    UnitTests.Weeder.ConfigSpec\n  ghc-options: -Wall -fwarn-incomplete-uni-patterns -fwrite-ide-info -hiedir ./test\n  default-language: Haskell2010\n";
  }