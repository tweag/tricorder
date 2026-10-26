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
    flags = { dev = false; };
    package = {
      specVersion = "3.0";
      identifier = { name = "tasty-discover"; version = "5.2.0"; };
      license = "MIT";
      copyright = "2016 Luke Murphy\n2020-2025 John Ky";
      maintainer = "John Ky <newhoggy@gmail.com>";
      author = "Luke Murphy";
      homepage = "https://github.com/haskell-works/tasty-discover";
      url = "";
      synopsis = "Test discovery for the tasty framework.";
      description = "Automatic test discovery and runner for the tasty framework.\n\nPrefix your test case names and tasty-discover will discover, collect and run them.\n\nAll popular test libraries are covered. Configure once and then just write your tests.\nAvoid forgetting to add test modules to your Cabal/Hpack files.\n\nTasty ingredients are included along with various configuration options for different\nuse cases.\n\nPlease see the `README.md` below for how to get started.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."Glob" or (errorHandler.buildDepError "Glob"))
          (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
        ];
        buildable = true;
      };
      exes = {
        "tasty-discover" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."tasty-discover" or (errorHandler.buildDepError "tasty-discover"))
          ];
          buildable = true;
        };
      };
      tests = {
        "tasty-discover-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-core" or (errorHandler.buildDepError "hspec-core"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-expected-failure" or (errorHandler.buildDepError "tasty-expected-failure"))
            (hsPkgs."tasty-golden" or (errorHandler.buildDepError "tasty-golden"))
            (hsPkgs."tasty-hedgehog" or (errorHandler.buildDepError "tasty-hedgehog"))
            (hsPkgs."tasty-hspec" or (errorHandler.buildDepError "tasty-hspec"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty-smallcheck" or (errorHandler.buildDepError "tasty-smallcheck"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."tasty-discover" or (errorHandler.buildDepError "tasty-discover"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.tasty-discover.components.exes.tasty-discover or (pkgs.pkgsBuildBuild.tasty-discover or (errorHandler.buildToolDepError "tasty-discover:tasty-discover")))
          ];
          buildable = true;
        };
        "no-main-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty-discover" or (errorHandler.buildDepError "tasty-discover"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.tasty-discover.components.exes.tasty-discover or (pkgs.pkgsBuildBuild.tasty-discover or (errorHandler.buildToolDepError "tasty-discover:tasty-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tasty-discover-5.2.0.tar.gz";
      sha256 = "a3477e4241ff3f40a3faab62db818f83b26a9a72bed1ab99c2240166e8a7cbf2";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\n\nname:                   tasty-discover\nversion:                5.2.0\nsynopsis:               Test discovery for the tasty framework.\ndescription:            Automatic test discovery and runner for the tasty framework.\n                      \n                        Prefix your test case names and tasty-discover will discover, collect and run them.\n                      \n                        All popular test libraries are covered. Configure once and then just write your tests.\n                        Avoid forgetting to add test modules to your Cabal/Hpack files.\n                      \n                        Tasty ingredients are included along with various configuration options for different\n                        use cases.\n                      \n                        Please see the `README.md` below for how to get started.\ncategory:               Testing\nstability:              Experimental\nhomepage:               https://github.com/haskell-works/tasty-discover\nbug-reports:            https://github.com/haskell-works/tasty-discover/issues\nauthor:                 Luke Murphy\nmaintainer:             John Ky <newhoggy@gmail.com>\ncopyright:              2016 Luke Murphy\n                        2020-2025 John Ky\nlicense:                MIT\nlicense-file:           LICENSE\ntested-with:            GHC == 9.12.2, GHC == 9.10.2, GHC == 9.8.4, GHC == 9.6.7\nbuild-type:             Simple\nextra-source-files:     CHANGELOG.md\n                        README.md\n\nsource-repository head\n  type: git\n  location: https://github.com/haskell-works/tasty-discover\n\nflag dev\n  description: Enable development mode\n  manual: True\n  default: False\n\ncommon base                       { build-depends: base                       >= 4.11       && < 5      }\n\ncommon ansi-terminal              { build-depends: ansi-terminal              >= 1.0      && < 2.0      }\ncommon bytestring                 { build-depends: bytestring                 >= 0.9      && < 1.0      }\ncommon containers                 { build-depends: containers                 >= 0.4      && < 1.0      }\ncommon directory                  { build-depends: directory                  >= 1.1      && < 2.0      }\ncommon filepath                   { build-depends: filepath                   >= 1.3      && < 2.0      }\ncommon Glob                       { build-depends: Glob                       >= 0.8      && < 1.0      }\ncommon hedgehog                   { build-depends: hedgehog                   >= 1.0      && < 2.0      }\ncommon hspec                      { build-depends: hspec                      >= 2.7      && < 2.12     }\ncommon hspec-core                 { build-depends: hspec-core                 >= 2.7.10   && < 2.12     }\ncommon tasty                      { build-depends: tasty                      >= 1.3      && < 2.0      }\ncommon tasty-golden               { build-depends: tasty-golden               >= 2.0      && < 3.0      }\ncommon tasty-hedgehog             { build-depends: tasty-hedgehog             >= 1.2      && < 2.0      }\ncommon tasty-hspec                { build-depends: tasty-hspec                >= 1.1      && < 1.3      }\ncommon tasty-hunit                { build-depends: tasty-hunit                >= 0.10     && < 0.11     }\ncommon tasty-quickcheck           { build-depends: tasty-quickcheck           >= 0.10     && < 0.11     }\ncommon tasty-smallcheck           { build-depends: tasty-smallcheck           >= 0.8      && < 1.0      }\ncommon tasty-expected-failure     { build-depends: tasty-expected-failure     >= 0.12     && < 0.13     }\ncommon process                    { build-depends: process                    >= 1.6      && < 2.0      }\ncommon temporary                  { build-depends: temporary                  >= 1.3      && < 1.4      }\n\ncommon project-config\n  default-extensions:   DeriveGeneric\n                        DerivingStrategies\n  if (impl(ghc >= 9.2.1))\n    default-extensions: OverloadedRecordDot\n  ghc-options:          -Wall\n                        -Widentities\n                        -Wincomplete-uni-patterns\n                        -Wmissing-deriving-strategies\n                        -Wredundant-constraints\n                        -Wunused-packages\n  default-language:     Haskell2010\n  if (flag(dev))\n    ghc-options:        -Werror\n\ncommon tasty-discover\n  build-depends: tasty-discover\n\nlibrary\n  import:               base, project-config\n                      , ansi-terminal\n                      , containers\n                      , directory\n                      , filepath\n                      , Glob\n                      , tasty\n  exposed-modules:      Test.Tasty.Discover\n                        Test.Tasty.Discover.Internal.Config\n                        Test.Tasty.Discover.Internal.Driver\n                        Test.Tasty.Discover.Internal.Generator\n                        Test.Tasty.Discover.Internal.Unsafe\n                        Test.Tasty.Discover.TastyInfo\n                        Test.Tasty.Discover.Version\n  other-modules:        Paths_tasty_discover\n  autogen-modules:      Paths_tasty_discover\n  hs-source-dirs:       src\n  default-language:     Haskell2010\n\nexecutable tasty-discover\n  import:               base, project-config\n                      , filepath\n  main-is:              app/Main.hs\n  autogen-modules:      Paths_tasty_discover\n  other-modules:        Paths_tasty_discover\n  build-depends:        tasty-discover\n  default-language:     Haskell2010\n\ntest-suite tasty-discover-test\n  import:               base, project-config\n                      , ansi-terminal\n                      , bytestring\n                      , containers\n                      , directory\n                      , filepath\n                      , hedgehog\n                      , hspec\n                      , hspec-core\n                      , process\n                      , tasty\n                      , tasty-expected-failure\n                      , tasty-golden\n                      , tasty-hedgehog\n                      , tasty-hspec\n                      , tasty-hunit\n                      , tasty-quickcheck\n                      , tasty-smallcheck\n                      , temporary\n  type:                 exitcode-stdio-1.0\n  main-is:              Driver.hs\n  ghc-options:          -threaded -rtsopts -with-rtsopts=-N\n  other-modules:        BackupFiles.ValidTest\n                        ConfigTest\n                        DiscoverTest\n                        ModulesGlob.Sub.OneTest\n                        ModulesGlob.TwoTest\n                        SubMod.FooBaz\n                        SubMod.PropTest\n                        SubMod.SubSubMod.PropTest\n  other-modules:        Paths_tasty_discover\n  autogen-modules:      Paths_tasty_discover\n  hs-source-dirs:       test\n  build-depends:        tasty-discover\n  default-language:     Haskell2010\n  build-tool-depends:   tasty-discover:tasty-discover\n\ntest-suite no-main-test\n  import:               base, project-config\n                      , tasty\n                      , tasty-hunit\n                      , tasty-quickcheck\n  type:                 exitcode-stdio-1.0\n  main-is:              Main.hs\n  ghc-options:          -threaded -rtsopts -with-rtsopts=-N\n  other-modules:        Tests\n                        Tests.Simple\n  other-modules:        Paths_tasty_discover\n  autogen-modules:      Paths_tasty_discover\n  hs-source-dirs:       test-no-main\n  build-depends:        tasty-discover\n  default-language:     Haskell2010\n  build-tool-depends:   tasty-discover:tasty-discover\n";
  }