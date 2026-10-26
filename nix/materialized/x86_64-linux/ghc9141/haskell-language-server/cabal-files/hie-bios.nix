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
      specVersion = "2.2";
      identifier = { name = "hie-bios"; version = "0.21.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Hannes Siebenhandl <fendor.haskell@gmail.com>";
      author = "Matthew Pickering <matthewtpickering@gmail.com>, Hannes Siebenhandl <fendor.haskell@gmail.com>";
      homepage = "https://github.com/haskell/hie-bios";
      url = "";
      synopsis = "Set up a GHC API session";
      description = "Set up a GHC API session and obtain flags required to compile a source file";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."co-log-core" or (errorHandler.buildDepError "co-log-core"))
          (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
          (hsPkgs."conduit-extra" or (errorHandler.buildDepError "conduit-extra"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."cryptohash-sha1" or (errorHandler.buildDepError "cryptohash-sha1"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."file-embed" or (errorHandler.buildDepError "file-embed"))
          (hsPkgs."filelock" or (errorHandler.buildDepError "filelock"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
          (hsPkgs."prettyprinter" or (errorHandler.buildDepError "prettyprinter"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unix-compat" or (errorHandler.buildDepError "unix-compat"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."yaml" or (errorHandler.buildDepError "yaml"))
        ];
        buildable = true;
      };
      exes = {
        "hie-bios" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."co-log-core" or (errorHandler.buildDepError "co-log-core"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hie-bios" or (errorHandler.buildDepError "hie-bios"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."prettyprinter" or (errorHandler.buildDepError "prettyprinter"))
          ];
          buildable = true;
        };
      };
      tests = {
        "parser-tests" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hie-bios" or (errorHandler.buildDepError "hie-bios"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."yaml" or (errorHandler.buildDepError "yaml"))
          ];
          buildable = true;
        };
        "bios-tests" = {
          depends = [
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."co-log-core" or (errorHandler.buildDepError "co-log-core"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."hie-bios" or (errorHandler.buildDepError "hie-bios"))
            (hsPkgs."prettyprinter" or (errorHandler.buildDepError "prettyprinter"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-expected-failure" or (errorHandler.buildDepError "tasty-expected-failure"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hie-bios-0.21.0.tar.gz";
      sha256 = "2fa861aed7797ba3b6df5651cebcae449ed6058b750302ea94f9ae08b6220bcb";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\nname: hie-bios\nversion: 0.21.0\nauthor: Matthew Pickering <matthewtpickering@gmail.com>, Hannes Siebenhandl <fendor.haskell@gmail.com>\nmaintainer: Hannes Siebenhandl <fendor.haskell@gmail.com>\nlicense: BSD-3-Clause\nlicense-file: LICENSE\nhomepage: https://github.com/haskell/hie-bios\nsynopsis: Set up a GHC API session\ndescription: Set up a GHC API session and obtain flags required to compile a source file\ncategory: Development\nbuild-type: Simple\nextra-doc-files:\n  ChangeLog.md\n  README.md\nextra-source-files:\n  tests/configs/*.yaml\n  tests/projects/cabal-with-custom-setup-old/a-with-custom/a-with-custom.cabal\n  tests/projects/cabal-with-custom-setup-old/a-with-custom/Setup.hs\n  tests/projects/cabal-with-custom-setup-old/a-with-custom/src/MyLib.hs\n  tests/projects/cabal-with-custom-setup-old/b/b.cabal\n  tests/projects/cabal-with-custom-setup-old/b/src/B.hs\n  tests/projects/cabal-with-custom-setup-old/b/tests/Main.hs\n  tests/projects/cabal-with-custom-setup-old/cabal.project\n  tests/projects/cabal-with-custom-setup/a-with-custom/a-with-custom.cabal\n  tests/projects/cabal-with-custom-setup/a-with-custom/Setup.hs\n  tests/projects/cabal-with-custom-setup/a-with-custom/src/MyLib.hs\n  tests/projects/cabal-with-custom-setup/b/b.cabal\n  tests/projects/cabal-with-custom-setup/b/src/B.hs\n  tests/projects/cabal-with-custom-setup/cabal.project\n  tests/projects/cabal-with-ghc-and-project/cabal-with-ghc.cabal\n  tests/projects/cabal-with-ghc-and-project/cabal.project.extra\n  tests/projects/cabal-with-ghc-and-project/hie.yaml\n  tests/projects/cabal-with-ghc-and-project/src/MyLib.hs\n  tests/projects/cabal-with-ghc/cabal-with-ghc.cabal\n  tests/projects/cabal-with-ghc/cabal.project\n  tests/projects/cabal-with-ghc/hie.yaml\n  tests/projects/cabal-with-ghc/src/MyLib.hs\n  tests/projects/cabal-with-project/cabal-with-project.cabal\n  tests/projects/cabal-with-project/cabal.project.extra\n  tests/projects/cabal-with-project/hie.yaml\n  tests/projects/cabal-with-project/src/MyLib.hs\n  tests/projects/deps-bios-new/A.hs\n  tests/projects/deps-bios-new/B.hs\n  tests/projects/deps-bios-new/hie-bios.sh\n  tests/projects/deps-bios-new/hie.yaml\n  tests/projects/failing-bios-ghc/A.hs\n  tests/projects/failing-bios-ghc/B.hs\n  tests/projects/failing-bios-ghc/hie.yaml\n  tests/projects/failing-bios/A.hs\n  tests/projects/failing-bios/B.hs\n  tests/projects/failing-bios/hie.yaml\n  tests/projects/failing-cabal/failing-cabal.cabal\n  tests/projects/failing-cabal/hie.yaml\n  tests/projects/failing-cabal/MyLib.hs\n  tests/projects/failing-multi-repl-cabal-project/multi-repl-cabal-fail/app/Main.hs\n  tests/projects/failing-multi-repl-cabal-project/multi-repl-cabal-fail/multi-repl-cabal-fail.cabal\n  tests/projects/failing-multi-repl-cabal-project/multi-repl-cabal-fail/src/Fail.hs\n  tests/projects/failing-multi-repl-cabal-project/multi-repl-cabal-fail/src/Lib.hs\n  tests/projects/failing-multi-repl-cabal-project/NotInPath.hs\n  tests/projects/failing-stack/failing-stack.cabal\n  tests/projects/failing-stack/hie.yaml\n  tests/projects/failing-stack/src/Lib.hs\n  tests/projects/implicit-cabal-deep-project/cabal.project\n  tests/projects/implicit-cabal-deep-project/foo/foo.cabal\n  tests/projects/implicit-cabal-deep-project/foo/Main.hs\n  tests/projects/implicit-cabal-deep-project/implicit-cabal-deep-project.cabal\n  tests/projects/implicit-cabal-deep-project/Main.hs\n  tests/projects/implicit-cabal-deep-project/README\n  tests/projects/implicit-cabal-no-project/implicit-cabal-no-project.cabal\n  tests/projects/implicit-cabal-no-project/Main.hs\n  tests/projects/implicit-cabal/cabal.project\n  tests/projects/implicit-cabal/implicit-cabal.cabal\n  tests/projects/implicit-cabal/Main.hs\n  tests/projects/implicit-stack-multi/implicit-stack-multi.cabal\n  tests/projects/implicit-stack-multi/Main.hs\n  tests/projects/implicit-stack-multi/other-package/Main.hs\n  tests/projects/implicit-stack-multi/other-package/other-package.cabal\n  tests/projects/implicit-stack/implicit-stack.cabal\n  tests/projects/implicit-stack/Main.hs\n  tests/projects/monorepo-cabal/A/A.cabal\n  tests/projects/monorepo-cabal/A/Main.hs\n  tests/projects/monorepo-cabal/B/B.cabal\n  tests/projects/monorepo-cabal/B/MyLib.hs\n  tests/projects/monorepo-cabal/cabal.project\n  tests/projects/monorepo-cabal/hie.yaml\n  tests/projects/multi-cabal-with-project/appA/appA.cabal\n  tests/projects/multi-cabal-with-project/appA/src/Lib.hs\n  tests/projects/multi-cabal-with-project/appB/appB.cabal\n  tests/projects/multi-cabal-with-project/appB/src/Lib.hs\n  tests/projects/multi-cabal-with-project/cabal.project.extra\n  tests/projects/multi-cabal-with-project/hie.yaml\n  tests/projects/multi-cabal/app/Main.hs\n  tests/projects/multi-cabal/cabal.project\n  tests/projects/multi-cabal/hie.yaml\n  tests/projects/multi-cabal/multi-cabal.cabal\n  tests/projects/multi-cabal/src/Lib.hs\n  tests/projects/multi-direct/A.hs\n  tests/projects/multi-direct/B.hs\n  tests/projects/multi-direct/hie.yaml\n  tests/projects/multi-stack-with-yaml/appA/appA.cabal\n  tests/projects/multi-stack-with-yaml/appA/src/Lib.hs\n  tests/projects/multi-stack-with-yaml/appB/appB.cabal\n  tests/projects/multi-stack-with-yaml/appB/src/Lib.hs\n  tests/projects/multi-stack-with-yaml/hie.yaml\n  tests/projects/multi-stack/app/Main.hs\n  tests/projects/multi-stack/cabal.project\n  tests/projects/multi-stack/hie.yaml\n  tests/projects/multi-stack/multi-stack.cabal\n  tests/projects/multi-stack/src/Lib.hs\n  tests/projects/nested-cabal/cabal.project\n  tests/projects/nested-cabal/hie.yaml\n  tests/projects/nested-cabal/MyLib.hs\n  tests/projects/nested-cabal/nested-cabal.cabal\n  tests/projects/nested-cabal/sub-comp/Lib.hs\n  tests/projects/nested-cabal/sub-comp/sub-comp.cabal\n  tests/projects/nested-stack/hie.yaml\n  tests/projects/nested-stack/MyLib.hs\n  tests/projects/nested-stack/nested-stack.cabal\n  tests/projects/nested-stack/sub-comp/Lib.hs\n  tests/projects/nested-stack/sub-comp/sub-comp.cabal\n  tests/projects/simple-bios-ghc/A.hs\n  tests/projects/simple-bios-ghc/B.hs\n  tests/projects/simple-bios-ghc/hie-bios.sh\n  tests/projects/simple-bios-ghc/hie.yaml\n  tests/projects/simple-bios-shell/A.hs\n  tests/projects/simple-bios-shell/B.hs\n  tests/projects/simple-bios-shell/hie.yaml\n  tests/projects/simple-bios/A.hs\n  tests/projects/simple-bios/B.hs\n  tests/projects/simple-bios/hie-bios-deps.sh\n  tests/projects/simple-bios/hie-bios.sh\n  tests/projects/simple-bios/hie.yaml\n  tests/projects/simple-cabal/A.hs\n  tests/projects/simple-cabal/B.hs\n  tests/projects/simple-cabal/cabal.project\n  tests/projects/simple-cabal/hie.yaml\n  tests/projects/simple-cabal/simple-cabal.cabal\n  tests/projects/simple-direct/A.hs\n  tests/projects/simple-direct/B.hs\n  tests/projects/simple-direct/hie.yaml\n  tests/projects/simple-stack/A.hs\n  tests/projects/simple-stack/B.hs\n  tests/projects/simple-stack/cabal.project\n  tests/projects/simple-stack/hie.yaml\n  tests/projects/simple-stack/simple-stack.cabal\n  \"tests/projects/space stack/A.hs\"\n  \"tests/projects/space stack/B.hs\"\n  \"tests/projects/space stack/hie.yaml\"\n  \"tests/projects/space stack/stackproj.cabal\"\n  tests/projects/stack-with-yaml/app/Main.hs\n  tests/projects/stack-with-yaml/hie.yaml\n  tests/projects/stack-with-yaml/src/Lib.hs\n  tests/projects/stack-with-yaml/stack-with-yaml.cabal\n  tests/projects/symlink-test/a/A.hs\n  tests/projects/symlink-test/hie.yaml\n  wrappers/cabal\n  wrappers/cabal-with-repl\n  wrappers/cabal-with-repl.hs\n  wrappers/cabal.hs\n\ntested-with: ghc ==9.6.7 || ==9.8.4 || ==9.10.1 || ==9.12.2 || ==9.14.1\n\nlibrary\n  default-language: Haskell2010\n  ghc-options: -Wall\n  hs-source-dirs: src\n  exposed-modules:\n    HIE.Bios\n    HIE.Bios.Config\n    HIE.Bios.Config.YAML\n    HIE.Bios.Cradle\n    HIE.Bios.Cradle.Cabal\n    HIE.Bios.Cradle.ProgramVersions\n    HIE.Bios.Cradle.ProjectConfig\n    HIE.Bios.Cradle.Resolved\n    HIE.Bios.Cradle.Utils\n    HIE.Bios.Environment\n    HIE.Bios.Flags\n    HIE.Bios.Ghc.Api\n    HIE.Bios.Ghc.Check\n    HIE.Bios.Ghc.Doc\n    HIE.Bios.Ghc.Gap\n    HIE.Bios.Ghc.Load\n    HIE.Bios.Ghc.Logger\n    HIE.Bios.Internal.Debug\n    HIE.Bios.Process\n    HIE.Bios.Types\n    HIE.Bios.Wrappers\n\n  other-modules: Paths_hie_bios\n  autogen-modules: Paths_hie_bios\n  build-depends:\n    aeson >=1.4.4 && <2.4,\n    base >=4.16 && <5,\n    base16-bytestring >=0.1.1 && <1.1,\n    bytestring >=0.10.8 && <0.13,\n    co-log-core ^>=0.3.0,\n    conduit >=1.3 && <2,\n    conduit-extra >=1.3 && <2,\n    containers >=0.6.2 && <0.9,\n    cryptohash-sha1 >=0.11.100 && <0.12,\n    deepseq >=1.4.3 && <1.6,\n    directory >=1.3.0 && <1.4,\n    exceptions ^>=0.10,\n    extra >=1.6.14 && <1.9,\n    file-embed >=0.0.11 && <1,\n    filelock >=0.1.1 && <0.2,\n    filepath >=1.4.1 && <1.6,\n    ghc >=9.2.1 && <10.2,\n    prettyprinter ^>=1.6 || ^>=1.7.0,\n    template-haskell >=2.18 && <2.25,\n    temporary >=1.2 && <1.4,\n    text >=1.2.3 && <2.2,\n    time >=1.8.0 && <1.17,\n    transformers >=0.5.2 && <0.7,\n    unix-compat >=0.5.1 && <0.8,\n    unordered-containers >=0.2.9 && <0.3,\n    yaml >=0.10.0 && <0.12,\n\nexecutable hie-bios\n  default-language: Haskell2010\n  main-is: Main.hs\n  other-modules: Paths_hie_bios\n  autogen-modules: Paths_hie_bios\n  ghc-options: -Wall\n  hs-source-dirs: exe\n  build-depends:\n    base >=4.16 && <5,\n    co-log-core,\n    directory,\n    filepath,\n    hie-bios,\n    optparse-applicative >=0.17.1 && <0.20,\n    prettyprinter,\n\ntest-suite parser-tests\n  type: exitcode-stdio-1.0\n  default-language: Haskell2010\n  build-depends:\n    aeson,\n    base,\n    filepath,\n    hie-bios,\n    tasty,\n    tasty-hunit,\n    yaml,\n\n  hs-source-dirs: tests/\n  ghc-options:\n    -threaded\n    -Wall\n\n  main-is: ParserTests.hs\n\ntest-suite bios-tests\n  type: exitcode-stdio-1.0\n  default-language: Haskell2010\n  build-depends:\n    async,\n    base,\n    co-log-core,\n    directory,\n    extra,\n    filepath,\n    ghc,\n    hie-bios,\n    prettyprinter,\n    process,\n    tasty,\n    tasty-expected-failure,\n    tasty-hunit,\n    temporary,\n    text,\n    transformers,\n\n  hs-source-dirs: tests/\n  main-is: BiosTests.hs\n  other-modules: Utils\n  ghc-options:\n    -threaded\n    -Wall\n\n  -- There seems to be a race condition on windows\n  if !os(windows)\n    ghc-options:\n      -rtsopts\n      -with-rtsopts=-N\n\nsource-repository head\n  type: git\n  location: https://github.com/haskell/hie-bios.git\n";
  }