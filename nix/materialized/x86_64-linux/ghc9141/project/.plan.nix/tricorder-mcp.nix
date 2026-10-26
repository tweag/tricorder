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
      identifier = { name = "tricorder-mcp"; version = "0.2.0.0"; };
      license = "MIT";
      copyright = "";
      maintainer = "victor.bakke@tweag.io";
      author = "Christian Georgii";
      homepage = "https://github.com/tweag/tricorder#readme";
      url = "";
      synopsis = "MCP server for Tricorder";
      description = "Model Context Protocol server for Tricorder.";
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
      sublibs = {
        "tricorder-mcp-internal" = {
          depends = [
            (hsPkgs."atelier-core" or (errorHandler.buildDepError "atelier-core"))
            (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
            (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
            (hsPkgs."mcp-server" or (errorHandler.buildDepError "mcp-server"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."tricorder-types" or (errorHandler.buildDepError "tricorder-types"))
            (hsPkgs."typed-process" or (errorHandler.buildDepError "typed-process"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ];
          buildable = true;
          modules = [
            "Paths_tricorder_mcp"
            "Tricorder/MCP/Derive"
            "Tricorder/MCP/Main"
            "Tricorder/MCP/Tools"
          ];
          hsSourceDirs = [ "src" ];
        };
      };
      exes = {
        "tricorder-mcp" = {
          depends = [
            (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
            (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
            (hsPkgs."tricorder-mcp".components.sublibs.tricorder-mcp-internal or (errorHandler.buildDepError "tricorder-mcp:tricorder-mcp-internal"))
          ];
          buildable = true;
          modules = [ "Paths_tricorder_mcp" ];
          hsSourceDirs = [ "app" ];
          mainPath = [
            "Main.hs"
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "9.8") "";
        };
      };
      tests = {
        "tricorder-mcp-test" = {
          depends = [
            (hsPkgs."atelier-core" or (errorHandler.buildDepError "atelier-core"))
            (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
            (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tricorder-mcp".components.sublibs.tricorder-mcp-internal or (errorHandler.buildDepError "tricorder-mcp:tricorder-mcp-internal"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.tasty-discover.components.exes.tasty-discover or (pkgs.pkgsBuildBuild.tasty-discover or (errorHandler.buildToolDepError "tasty-discover:tasty-discover")))
          ];
          buildable = true;
          modules = [ "Unit/Tricorder/MCP/ToolsSpec" "Paths_tricorder_mcp" ];
          hsSourceDirs = [ "test" ];
          mainPath = [ "Driver.hs" ];
        };
      };
    };
  } // rec { src = pkgs.lib.mkDefault ../packages/tricorder-mcp; }