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
      identifier = { name = "toml-reader"; version = "0.3.0.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Brandon Chinn <brandonchinn178@gmail.com>";
      author = "Brandon Chinn <brandonchinn178@gmail.com>";
      homepage = "https://github.com/brandonchinn178/toml-reader#readme";
      url = "";
      synopsis = "TOML format parser compliant with v1.0.0.";
      description = "TOML format parser compliant with v1.0.0. See README.md for more details.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."megaparsec" or (errorHandler.buildDepError "megaparsec"))
          (hsPkgs."parser-combinators" or (errorHandler.buildDepError "parser-combinators"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
        ];
        buildable = true;
      };
      tests = {
        "parser-validator" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."toml-reader" or (errorHandler.buildDepError "toml-reader"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = true;
        };
        "toml-reader-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."skeletest" or (errorHandler.buildDepError "skeletest"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."toml-reader" or (errorHandler.buildDepError "toml-reader"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.skeletest.components.exes.skeletest-preprocessor or (pkgs.pkgsBuildBuild.skeletest-preprocessor or (errorHandler.buildToolDepError "skeletest:skeletest-preprocessor")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/toml-reader-0.3.0.0.tar.gz";
      sha256 = "90705463d96835fcea3487a3a753d3b3ead3dfe036b07e2d5c861a9e1ec4dc96";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.37.0.\n--\n-- see: https://github.com/sol/hpack\n\nname:           toml-reader\nversion:        0.3.0.0\nsynopsis:       TOML format parser compliant with v1.0.0.\ndescription:    TOML format parser compliant with v1.0.0. See README.md for more details.\ncategory:       TOML, Text, Configuration\nhomepage:       https://github.com/brandonchinn178/toml-reader#readme\nbug-reports:    https://github.com/brandonchinn178/toml-reader/issues\nauthor:         Brandon Chinn <brandonchinn178@gmail.com>\nmaintainer:     Brandon Chinn <brandonchinn178@gmail.com>\nlicense:        BSD3\nlicense-file:   LICENSE.md\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    CHANGELOG.md\n    test/specs/TOML/__snapshots__/ErrorSpec.snap.md\n\nsource-repository head\n  type: git\n  location: https://github.com/brandonchinn178/toml-reader\n\nlibrary\n  exposed-modules:\n      TOML\n      TOML.Decode\n      TOML.Error\n      TOML.Parser\n      TOML.Utils.Map\n      TOML.Utils.NonEmpty\n      TOML.Value\n  other-modules:\n      Paths_toml_reader\n  hs-source-dirs:\n      src\n  ghc-options: -Wall -Wcompat -Wincomplete-record-updates -Wincomplete-uni-patterns -Wnoncanonical-monad-instances -Wunused-packages\n  build-depends:\n      base >=4.15 && <5\n    , containers\n    , megaparsec\n    , parser-combinators\n    , text\n    , time\n  default-language: GHC2021\n\ntest-suite parser-validator\n  type: exitcode-stdio-1.0\n  main-is: ValidateParser.hs\n  other-modules:\n      Paths_toml_reader\n  hs-source-dirs:\n      test/toml-test\n  ghc-options: -Wall -Wcompat -Wincomplete-record-updates -Wincomplete-uni-patterns -Wnoncanonical-monad-instances -Wunused-packages\n  build-depends:\n      aeson\n    , base\n    , bytestring\n    , containers\n    , directory\n    , process\n    , text\n    , time\n    , toml-reader\n    , unordered-containers\n    , vector\n  default-language: GHC2021\n\ntest-suite toml-reader-tests\n  type: exitcode-stdio-1.0\n  main-is: Main.hs\n  other-modules:\n      TOML.DecodeSpec\n      TOML.ErrorSpec\n      TOML.ParserSpec\n      TOML.Utils.MapSpec\n      TOML.Utils.NonEmptySpec\n      Paths_toml_reader\n  hs-source-dirs:\n      test/specs\n  ghc-options: -Wall -Wcompat -Wincomplete-record-updates -Wincomplete-uni-patterns -Wnoncanonical-monad-instances -Wunused-packages -F -pgmF skeletest-preprocessor\n  build-tool-depends:\n      skeletest:skeletest-preprocessor\n  build-depends:\n      base\n    , containers\n    , skeletest\n    , text\n    , time\n    , toml-reader\n  default-language: GHC2021\n";
  }