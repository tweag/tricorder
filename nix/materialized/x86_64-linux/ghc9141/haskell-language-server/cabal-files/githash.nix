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
      specVersion = "1.12";
      identifier = { name = "githash"; version = "0.1.7.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "michael@snoyman.com";
      author = "Michael Snoyman, Adam C. Foltzer";
      homepage = "https://github.com/snoyberg/githash#readme";
      url = "";
      synopsis = "Compile git revision info into Haskell projects";
      description = "Please see the README and documentation at <https://www.stackage.org/package/githash>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."th-compat" or (errorHandler.buildDepError "th-compat"))
        ];
        buildable = true;
      };
      tests = {
        "githash-spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."githash" or (errorHandler.buildDepError "githash"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."th-compat" or (errorHandler.buildDepError "th-compat"))
            (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/githash-0.1.7.0.tar.gz";
      sha256 = "1ad5e7c26bd9c9c4e4c3232206694b153845fe11f227e39d214eef0d95f330d4";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.35.1.\n--\n-- see: https://github.com/sol/hpack\n\nname:           githash\nversion:        0.1.7.0\nsynopsis:       Compile git revision info into Haskell projects\ndescription:    Please see the README and documentation at <https://www.stackage.org/package/githash>\ncategory:       Development\nhomepage:       https://github.com/snoyberg/githash#readme\nbug-reports:    https://github.com/snoyberg/githash/issues\nauthor:         Michael Snoyman, Adam C. Foltzer\nmaintainer:     michael@snoyman.com\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/snoyberg/githash\n\nlibrary\n  exposed-modules:\n      GitHash\n  other-modules:\n      Paths_githash\n  hs-source-dirs:\n      src\n  build-depends:\n      base >=4.9.1 && <5\n    , bytestring\n    , directory\n    , filepath\n    , process\n    , template-haskell\n    , th-compat\n  default-language: Haskell2010\n\ntest-suite githash-spec\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      GitHashSpec\n      NormalRepoSpec\n      RepoWithASubmoduleSpec\n      WorktreeRepoSpec\n      Paths_githash\n  hs-source-dirs:\n      test\n  build-depends:\n      base >=4.9.1 && <5\n    , bytestring\n    , directory\n    , filepath\n    , githash\n    , hspec\n    , process\n    , template-haskell\n    , temporary\n    , th-compat\n    , unliftio\n  default-language: Haskell2010\n";
  }