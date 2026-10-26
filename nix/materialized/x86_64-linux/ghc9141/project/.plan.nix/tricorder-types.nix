{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  {
    flags = {};
    package = {
      specVersion = "2.0";
      identifier = { name = "tricorder-types"; version = "0.6.0.0"; };
      license = "MIT";
      copyright = "";
      maintainer = "victor.bakke@tweag.io";
      author = "Christian Georgii";
      homepage = "https://github.com/tweag/tricorder#readme";
      url = "";
      synopsis = "Shared domain types for various Tricorder components";
      description = "Shared domain types for various Tricorder components like\n[Tricorder itself](https://hackage.haskell.org/package/tricorder) and\n[tricorder-mcp](https://hackage.haskell.org/package/tricorder-mcp).";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [ "LICENSE" ];
      dataDir = ".";
      dataFiles = [];
      extraSrcFiles = [];
      extraTmpFiles = [];
      extraDocFiles = [ "README.md" "CHANGELOG.md" ];
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."atelier-core" or (errorHandler.buildDepError "atelier-core"))
          (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."effectful" or (errorHandler.buildDepError "effectful"))
          (hsPkgs."megaparsec" or (errorHandler.buildDepError "megaparsec"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."yaml" or (errorHandler.buildDepError "yaml"))
        ];
        buildable = true;
        modules = [
          "Paths_tricorder_types"
          "Tricorder/API/Args/Deprecated"
          "Tricorder/API/Command"
          "Tricorder/API/Command/Args"
          "Tricorder/API/Daemon/Args"
          "Tricorder/API/Daemon/Command"
          "Tricorder/API/FieldMask"
          "Tricorder/API/FieldMask/Args"
          "Tricorder/API/FieldMask/Projection"
          "Tricorder/API/FieldMask/Schema"
          "Tricorder/API/IfBuildIsPending"
          "Tricorder/API/IfBuildIsPending/Args"
          "Tricorder/API/IfDaemonIsStopped"
          "Tricorder/API/IfDaemonIsStopped/Args"
          "Tricorder/API/IfThereArePendingQueries"
          "Tricorder/API/IfThereArePendingQueries/Args"
          "Tricorder/API/OutputFormat"
          "Tricorder/API/OutputFormat/Args"
          "Tricorder/API/Test"
          "Tricorder/API/Test/Args"
          "Tricorder/API/Test/SuiteView"
          "Tricorder/API/Test/SuiteView/Schema"
          "Tricorder/API/TestFilter"
          "Tricorder/API/TestFilter/Args"
          "Tricorder/SourceLookup/ModuleSourceResult"
          "Tricorder/SourceLookup/PackageId"
          "Tricorder/SourceLookup/ReexportLimits"
          "Tricorder/SourceLookup/SourceQuery"
        ];
        hsSourceDirs = [ "src" ];
      };
      tests = {
        "tricorder-types-test" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."atelier-core" or (errorHandler.buildDepError "atelier-core"))
            (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-discover" or (errorHandler.buildDepError "tasty-discover"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."tricorder-types" or (errorHandler.buildDepError "tricorder-types"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.tasty-discover.components.exes.tasty-discover or (pkgs.pkgsBuildBuild.tasty-discover or (errorHandler.buildToolDepError "tasty-discover:tasty-discover")))
          ];
          buildable = true;
          modules = [
            "Unit/Tricorder/API/FieldMask/ArgsSpec"
            "Unit/Tricorder/API/FieldMask/ProjectionSpec"
            "Unit/Tricorder/API/FieldMask/SchemaSpec"
            "Unit/Tricorder/API/SuiteView/SchemaSpec"
            "Paths_tricorder_types"
          ];
          hsSourceDirs = [ "test" ];
          mainPath = [ "Driver.hs" ];
        };
      };
    };
  } // rec { src = pkgs.lib.mkDefault ../packages/tricorder-types; }