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
    flags = { roundtrip = false; dev = false; };
    package = {
      specVersion = "2.4";
      identifier = { name = "ghc-exactprint"; version = "1.14.3.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "alan.zimm@gmail.com";
      author = "Alan Zimmerman, Matthew Pickering";
      homepage = "";
      url = "";
      synopsis = "ExactPrint for GHC";
      description = "Using the API Annotations available from GHC 9.2.1, this\nlibrary provides a means to round trip any code that can\nbe compiled by GHC, currently excluding lhs files.\n\nNote: requires GHC 9.14.*. For earlier GHC\nversions see lower version numbers.\n";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
          (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
        ];
        buildable = if compiler.isGhc && compiler.version.lt "9.12"
          then false
          else true;
      };
      exes = {
        "roundtrip" = {
          depends = pkgs.lib.optionals (compiler.isGhc && compiler.version.ge "9.14" && flags.roundtrip) [
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghc-exactprint" or (errorHandler.buildDepError "ghc-exactprint"))
            (hsPkgs."ghc-paths" or (errorHandler.buildDepError "ghc-paths"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
          ];
          buildable = if compiler.isGhc && compiler.version.ge "9.14" && flags.roundtrip
            then true
            else false;
        };
        "static" = {
          depends = pkgs.lib.optionals (flags.roundtrip) [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."Diff" or (errorHandler.buildDepError "Diff"))
          ];
          buildable = if flags.roundtrip then true else false;
        };
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."Diff" or (errorHandler.buildDepError "Diff"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghc-paths" or (errorHandler.buildDepError "ghc-paths"))
            (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
            (hsPkgs."silently" or (errorHandler.buildDepError "silently"))
            (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
          ] ++ (if flags.dev
            then [ (hsPkgs."mtl" or (errorHandler.buildDepError "mtl")) ]
            else [
              (hsPkgs."ghc-exactprint" or (errorHandler.buildDepError "ghc-exactprint"))
            ]);
          buildable = if compiler.isGhc && compiler.version.lt "9.14"
            then false
            else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/ghc-exactprint-1.14.3.0.tar.gz";
      sha256 = "e61a6ef3d23ae34fe7a5a32cbe9abbe15dc3a0a4ad43ab97f85d0d9da9ed7586";
    });
  }) // {
    package-description-override = "cabal-version:       2.4\nname:                ghc-exactprint\nversion:             1.14.3.0\nsynopsis:            ExactPrint for GHC\ndescription:         Using the API Annotations available from GHC 9.2.1, this\n                     library provides a means to round trip any code that can\n                     be compiled by GHC, currently excluding lhs files.\n                     .\n                     Note: requires GHC 9.14.*. For earlier GHC\n                     versions see lower version numbers.\n                     .\n\nlicense:             BSD-3-Clause\nlicense-file:        LICENSE\nauthor:              Alan Zimmerman, Matthew Pickering\nmaintainer:          alan.zimm@gmail.com\ncategory:            Development\nbuild-type:          Simple\ntested-with:         GHC == 9.14.1\nextra-doc-files:     ChangeLog\nextra-source-files:  tests/examples/failing/*.hs\n                     tests/examples/failing/*.hs.bad\n                     tests/examples/ghc910/*.hs\n                     tests/examples/ghc912/*.hs\n                     tests/examples/ghc914/*.hs\n                     tests/examples/pre-ghc910/*.hs\n                     tests/examples/pre-ghc910/*.hs-boot\n                     tests/examples/transform/*.hs\n                     tests/examples/transform/*.hs.expected\n\nsource-repository head\n  type:     git\n  location: https://github.com/alanz/ghc-exactprint.git\n\nFlag roundtrip {\n  Description: Build roundtripping executables\n  Default:     False\n}\n\nFlag dev {\n  Description: Development mode, do not use ghc-exactprint lib in the tests\n  Default:     False\n}\n\ncommon warnings\n  GHC-options: -Wall -Wredundant-constraints -Wunused-packages\n\nlibrary\n  import: warnings\n  exposed-modules:     Language.Haskell.GHC.ExactPrint\n                     , Language.Haskell.GHC.ExactPrint.ExactPrint\n                     , Language.Haskell.GHC.ExactPrint.Parsers\n                     , Language.Haskell.GHC.ExactPrint.Preprocess\n                     , Language.Haskell.GHC.ExactPrint.Transform\n                     , Language.Haskell.GHC.ExactPrint.Types\n                     , Language.Haskell.GHC.ExactPrint.Utils\n\n  hs-source-dirs:      src\n  build-depends:       base >=4.22 && <4.23\n                     , containers >= 0.5  && < 0.9\n                     , extra\n                     , ghc       >= 9.14 && < 9.15\n                     , ghc-boot  >= 9.14 && < 9.15\n                     , mtl       >= 2.3 && < 2.5\n                     , syb       >= 0.5 && < 0.8\n\n  default-language:    Haskell2010\n  if impl (ghc < 9.12)\n    buildable: False\n\nTest-Suite test\n  import: warnings\n  type:                exitcode-stdio-1.0\n  if flag (dev)\n    hs-source-dirs:      tests\n                         src\n  else\n    hs-source-dirs:      tests\n\n  main-is:             Test.hs\n  other-modules:       Test.Common\n                     , Test.CommonUtils\n                     , Test.NoAnnotations\n                     , Test.Transform\n  GHC-Options:         -threaded\n  Default-language:    Haskell2010\n  Build-depends:       base < 4.23\n                     , HUnit >= 1.2\n                     , containers >= 0.5\n                     , Diff\n                     , directory >= 1.2\n                     , filepath  >= 1.4\n                     , ghc       >= 9.14\n                     , ghc-paths  >= 0.1\n                     , syb        >= 0.5\n                     , silently   >= 1.2\n                     , ghc-boot\n  if flag (dev)\n      build-depends:\n                     mtl        >= 2.2.1\n  else\n      build-depends: ghc-exactprint\n  if impl (ghc < 9.14)\n      buildable: False\n\nexecutable roundtrip\n  import: warnings\n  main-is: Roundtrip.hs\n  hs-source-dirs: tests\n  other-modules: Test.Common\n                 Test.CommonUtils\n  default-language:    Haskell2010\n  if impl (ghc >= 9.14) && flag (roundtrip)\n    build-depends:\n                 HUnit      < 1.7\n               , base       < 4.23\n               , containers < 0.9\n               , directory  < 1.4\n               , extra      < 1.9\n               , filepath   < 1.6\n               , ghc        >= 9.14 && < 9.15\n               , ghc-exactprint\n               , ghc-paths  < 0.2\n               , time       < 1.16\n               , ghc-boot\n    buildable: True\n  else\n    buildable: False\n  GHC-Options: -threaded\n\nexecutable static\n  import: warnings\n  main-is: Static.hs\n  hs-source-dirs: tests\n  other-modules: Test.CommonUtils\n  default-language:    Haskell2010\n  if flag (roundtrip)\n    build-depends: base < 4.23\n                 , directory < 1.4\n                 , extra     < 1.9\n                 , filepath  < 1.6\n                 , ghc       >= 9.14 && < 9.15\n                 , Diff      < 1.1\n    buildable: True\n  else\n    buildable: False\n  GHC-Options: -threaded\n\n-- executable prepare-hackage\n--   import: warnings\n--   main-is: PrepareHackage.hs\n--   other-modules: Test.CommonUtils\n--   hs-source-dirs: tests\n--   default-language:    Haskell2010\n--   if flag (roundtrip)\n--     build-depends: base < 4.22\n--                  , containers\n--                  , directory\n--                  , extra\n--                  , filepath\n--                  , ghc       >= 9.12\n--                  , HUnit\n--                  , text   >= 1.2.2\n--                  , turtle >= 1.3.0\n--     buildable: True\n--   else\n--     buildable: False\n--   GHC-Options: -threaded\n";
  }