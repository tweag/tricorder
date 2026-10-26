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
    flags = { executable = true; };
    package = {
      specVersion = "2.0";
      identifier = { name = "implicit-hie"; version = "0.1.4.0"; };
      license = "BSD-3-Clause";
      copyright = "2020";
      maintainer = "avi.the.coder@gmail.com";
      author = "Avi Dessauer";
      homepage = "https://github.com/Avi-D-coder/implicit-hie#readme";
      url = "";
      synopsis = "Auto generate hie-bios cradles & hie.yaml";
      description = "Auto generate a stack or cabal multi component hie.yaml file";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."filepattern" or (errorHandler.buildDepError "filepattern"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."yaml" or (errorHandler.buildDepError "yaml"))
        ];
        buildable = true;
      };
      exes = {
        "gen-hie" = {
          depends = [
            (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."filepattern" or (errorHandler.buildDepError "filepattern"))
            (hsPkgs."implicit-hie" or (errorHandler.buildDepError "implicit-hie"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."yaml" or (errorHandler.buildDepError "yaml"))
          ];
          buildable = if !flags.executable then false else true;
        };
      };
      tests = {
        "implicit-hie-test" = {
          depends = [
            (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."filepattern" or (errorHandler.buildDepError "filepattern"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-attoparsec" or (errorHandler.buildDepError "hspec-attoparsec"))
            (hsPkgs."implicit-hie" or (errorHandler.buildDepError "implicit-hie"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."yaml" or (errorHandler.buildDepError "yaml"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/implicit-hie-0.1.4.0.tar.gz";
      sha256 = "931814d6c1bb9f8f6d57161783eacb7b95e66398e1b20d652eca0759206def21";
    });
  }) // {
    package-description-override = "cabal-version:      2.0\n\n-- This file has been generated from package.yaml by hpack version 0.33.0.\n--\n-- see: https://github.com/sol/hpack\n--\n-- hash: b2b829a658e33ea328c725dea732391089d03ffd2a216d413a75d88aefa7c181\n\nname:               implicit-hie\nversion:            0.1.4.0\ndescription:\n  Auto generate a stack or cabal multi component hie.yaml file\n\ncategory:           Development, Tools, Hie, HLS\nsynopsis:           Auto generate hie-bios cradles & hie.yaml\nhomepage:           https://github.com/Avi-D-coder/implicit-hie#readme\nbug-reports:        https://github.com/Avi-D-coder/implicit-hie/issues\nauthor:             Avi Dessauer\nmaintainer:         avi.the.coder@gmail.com\ncopyright:          2020\nlicense:            BSD3\nlicense-file:       LICENSE\ntested-with:        GHC ==8.8.3 || ==8.10.1\nbuild-type:         Simple\nextra-source-files:\n  ChangeLog.md\n  README.md\n  test/benchSection\n  test/cabal.project\n  test/haskell-language-server-cabal\n  test/hie.yaml.cbl\n  test/stackHie.yaml\n\nsource-repository head\n  type:     git\n  location: https://github.com/Avi-D-coder/implicit-hie\n\nlibrary\n  exposed-modules:\n    Hie.Cabal.Parser\n    Hie.Locate\n    Hie.Yaml\n\n  other-modules:    Paths_implicit_hie\n  autogen-modules:  Paths_implicit_hie\n  hs-source-dirs:   src\n  ghc-options:\n    -Wall -Wincomplete-record-updates -Wincomplete-uni-patterns\n    -fno-warn-unused-imports -fno-warn-unused-binds\n    -fno-warn-name-shadowing -fwarn-redundant-constraints\n\n  build-depends:\n      attoparsec    >=0.13\n    , base          >=4.7  && <5\n    , directory     >=1.3\n    , filepath      >=1.4\n    , filepattern   >=0.1\n    , text          >=1.2\n    , transformers  >=0.5\n    , yaml          >=0.5\n\n  default-language: Haskell2010\n\nflag executable\n  description: Build the gen-hie executable\n  default: True\n\nexecutable gen-hie\n  main-is:          Main.hs\n  other-modules:    Paths_implicit_hie\n  autogen-modules:  Paths_implicit_hie\n  hs-source-dirs:   app\n  ghc-options:\n    -Wall -Wincomplete-record-updates -Wincomplete-uni-patterns\n    -fno-warn-unused-imports -fno-warn-unused-binds\n    -fno-warn-name-shadowing -fwarn-redundant-constraints -threaded\n    -rtsopts -with-rtsopts=-N\n\n  build-depends:\n      attoparsec\n    , base          >=4.7 && <5\n    , directory\n    , filepath\n    , filepattern\n    , implicit-hie\n    , text\n    , transformers\n    , yaml\n\n  default-language: Haskell2010\n  \n  if !flag(executable)\n    buildable: False\n\ntest-suite implicit-hie-test\n  type:             exitcode-stdio-1.0\n  main-is:          Spec.hs\n  other-modules:    Paths_implicit_hie\n  autogen-modules:  Paths_implicit_hie\n  hs-source-dirs:   test\n  ghc-options:\n    -Wall -Wincomplete-record-updates -Wincomplete-uni-patterns\n    -fno-warn-unused-imports -fno-warn-unused-binds\n    -fno-warn-name-shadowing -fwarn-redundant-constraints -threaded\n    -rtsopts -with-rtsopts=-N\n\n  build-depends:\n      attoparsec\n    , base              >=4.7 && <5\n    , directory\n    , filepath\n    , filepattern\n    , hspec\n    , hspec-attoparsec\n    , implicit-hie\n    , text\n    , transformers\n    , yaml\n\n  default-language: Haskell2010\n";
  }