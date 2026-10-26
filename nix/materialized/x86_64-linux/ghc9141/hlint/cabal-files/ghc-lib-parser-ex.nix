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
    flags = { auto = false; no-ghc-lib = false; };
    package = {
      specVersion = "3.4";
      identifier = { name = "ghc-lib-parser-ex"; version = "9.12.0.0"; };
      license = "BSD-3-Clause";
      copyright = "Copyright © 2020-2024 Shayne Fletcher. All rights reserved.";
      maintainer = "shayne@shaynefletcher.org";
      author = "Shayne Fletcher";
      homepage = "https://github.com/shayne-fletcher/ghc-lib-parser-ex#readme";
      url = "";
      synopsis = "Programming with GHC parse trees";
      description = "Please see the README on GitHub at <https://github.com/shayne-fletcher/ghc-lib-parser-ex#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."uniplate" or (errorHandler.buildDepError "uniplate"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
        ] ++ (if flags.auto && (compiler.isGhc && compiler.version.ge "9.12.0") && (compiler.isGhc && compiler.version.lt "9.13.0")
          then [
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
            (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
          ]
          else if flags.auto
            then [
              (hsPkgs."ghc-lib-parser" or (errorHandler.buildDepError "ghc-lib-parser"))
            ]
            else if flags.no-ghc-lib
              then [
                (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
                (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
                (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
              ]
              else [
                (hsPkgs."ghc-lib-parser" or (errorHandler.buildDepError "ghc-lib-parser"))
              ]);
        buildable = true;
      };
      exes = {
        "ghc-lib-parser-ex-build-tool" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          ];
          buildable = true;
        };
      };
      tests = {
        "ghc-lib-parser-ex-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."uniplate" or (errorHandler.buildDepError "uniplate"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."uniplate" or (errorHandler.buildDepError "uniplate"))
            (hsPkgs."ghc-lib-parser-ex" or (errorHandler.buildDepError "ghc-lib-parser-ex"))
          ] ++ (if flags.auto && (compiler.isGhc && compiler.version.ge "9.12.0") && (compiler.isGhc && compiler.version.lt "9.13.0")
            then [
              (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
              (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
              (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
            ]
            else if flags.auto
              then [
                (hsPkgs."ghc-lib-parser" or (errorHandler.buildDepError "ghc-lib-parser"))
              ]
              else if flags.no-ghc-lib
                then [
                  (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
                  (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
                  (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
                ]
                else [
                  (hsPkgs."ghc-lib-parser" or (errorHandler.buildDepError "ghc-lib-parser"))
                ]);
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/ghc-lib-parser-ex-9.12.0.0.tar.gz";
      sha256 = "624995f08a60b1a8ebf34314a2be3951ebfc42646fd2ae7d89a596f280721571";
    });
  }) // {
    package-description-override = "cabal-version: 3.4\nname: ghc-lib-parser-ex\nversion: 9.12.0.0\ndescription: Please see the README on GitHub at <https://github.com/shayne-fletcher/ghc-lib-parser-ex#readme>\nhomepage: https://github.com/shayne-fletcher/ghc-lib-parser-ex#readme\nbug-reports: https://github.com/shayne-fletcher/ghc-lib-parser-ex/issues\nauthor: Shayne Fletcher\nmaintainer: shayne@shaynefletcher.org\ncopyright: Copyright © 2020-2024 Shayne Fletcher. All rights reserved.\nlicense: BSD-3-Clause\nlicense-file:   LICENSE\ncategory: Development\nsynopsis: Programming with GHC parse trees\nbuild-type: Simple\nextra-source-files:\n    README.md ChangeLog.md cbits/ghclib_api.h\n\nsource-repository head\n  type: git\n  location: https://github.com/shayne-fletcher/ghc-lib-parser-ex\n\nflag auto\n  default: False\n  manual: True\n  description: Use default configuration\n\nflag no-ghc-lib\n  default: False\n  manual: True\n  description: Do not link ghc-lib. Use the native GHC libs\n\ncommon base\n  default-language: Haskell2010\n  ghc-options:\n    -Wall -Wincomplete-record-updates -Wredundant-constraints -Widentities\n    -Wunused-imports -Wno-name-shadowing\n  build-depends:\n      base >=4.7 && <5\n\ncommon ghc_libs\n  include-dirs: cbits\n  default-extensions: CPP\n  if flag(auto) && impl(ghc >= 9.12.0) && impl(ghc < 9.13.0)\n    build-depends:\n      ghc == 9.12.*,\n      ghc-boot-th,\n      ghc-boot\n  else\n    if flag(auto)\n      build-depends:\n        ghc-lib-parser == 9.12.*\n    else\n      if flag(no-ghc-lib)\n        build-depends:\n          ghc == 9.12.*,\n          ghc-boot-th,\n          ghc-boot\n      else\n        build-depends:\n          ghc-lib-parser == 9.12.*\n\ncommon lib\n  import: base, ghc_libs\n  build-depends:\n      uniplate >= 1.5,\n      bytestring >= 0.10.8.2,\n      containers >= 0.5.8.1\n\nlibrary\n  import: lib\n  exposed-modules:\n      Language.Haskell.GhclibParserEx.Dump\n      Language.Haskell.GhclibParserEx.Fixity\n      Language.Haskell.GhclibParserEx.GHC.Settings.Config\n      Language.Haskell.GhclibParserEx.GHC.Driver.Flags\n      Language.Haskell.GhclibParserEx.GHC.Driver.Session\n      Language.Haskell.GhclibParserEx.GHC.Hs\n      Language.Haskell.GhclibParserEx.GHC.Hs.Dump\n      Language.Haskell.GhclibParserEx.GHC.Hs.Expr\n      Language.Haskell.GhclibParserEx.GHC.Hs.Pat\n      Language.Haskell.GhclibParserEx.GHC.Hs.Type\n      Language.Haskell.GhclibParserEx.GHC.Hs.Types\n      Language.Haskell.GhclibParserEx.GHC.Hs.Decls\n      Language.Haskell.GhclibParserEx.GHC.Hs.Binds\n      Language.Haskell.GhclibParserEx.GHC.Hs.ImpExp\n      Language.Haskell.GhclibParserEx.GHC.Hs.ExtendInstances\n      Language.Haskell.GhclibParserEx.GHC.Parser\n      Language.Haskell.GhclibParserEx.GHC.Types.Name.Reader\n      Language.Haskell.GhclibParserEx.GHC.Utils.Outputable\n  autogen-modules: Paths_ghc_lib_parser_ex\n  other-modules: Paths_ghc_lib_parser_ex\n  hs-source-dirs: src\n\ncommon test\n  import: lib\n  build-depends:\n    tasty >= 1.2, tasty-hunit >= 0.10.0, directory >= 1.3.1,\n    filepath >= 1.4.2, extra >=1.6, uniplate >= 1.6.12,\n    ghc-lib-parser-ex\n\ntest-suite ghc-lib-parser-ex-test\n  import: test\n  type: exitcode-stdio-1.0\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  main-is: Test.hs\n  hs-source-dirs: test\n\nexecutable ghc-lib-parser-ex-build-tool\n  import: base\n  build-depends: directory, filepath, time, extra, optparse-applicative\n  main-is: CI.hs\n";
  }