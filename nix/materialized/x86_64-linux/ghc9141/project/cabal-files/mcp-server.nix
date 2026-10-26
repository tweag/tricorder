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
      identifier = { name = "mcp-server"; version = "0.2.0.2"; };
      license = "BSD-3-Clause";
      copyright = "2025 Tom Wells";
      maintainer = "drshade@gmail.com";
      author = "Tom Wells";
      homepage = "https://github.com/drshade/haskell-mcp-server";
      url = "";
      synopsis = "Library for building Model Context Protocol (MCP) servers";
      description = "A fully featured library for building MCP (Model Context Protocol) servers.\nSupports both low-level fine-grained handling and high-level derived interfaces\nfor prompts, resources, and tools. Includes JSON-RPC transport\nand stdin/stdout communication.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
          (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
        ];
        buildable = true;
      };
      exes = {
        "simple-example" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."mcp-server" or (errorHandler.buildDepError "mcp-server"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
        "complete-example" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."mcp-server" or (errorHandler.buildDepError "mcp-server"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
        "http-simple-example" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."mcp-server" or (errorHandler.buildDepError "mcp-server"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
      tests = {
        "haskell-mcp-server-test" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."mcp-server" or (errorHandler.buildDepError "mcp-server"))
            (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/mcp-server-0.2.0.2.tar.gz";
      sha256 = "2b42f4161f4ad1feb076b1da15cdcaccca4d3fa2dc4257b2e0fc909d91a8e9c5";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\n-- The cabal-version field refers to the version of the .cabal specification,\n-- and can be different from the cabal-install (the tool) version and the\n-- Cabal (the library) version you are using. As such, the Cabal (the library)\n-- version used must be equal or greater than the version stated in this field.\n-- Starting from the specification version 2.2, the cabal-version field must be\n-- the first thing in the cabal file.\n--\n-- The name of the package.\nname: mcp-server\n-- The package version.\n-- See the Haskell package versioning policy (PVP) for standards\n-- guiding when and how versions should be incremented.\n-- https://pvp.haskell.org\n-- PVP summary:     +-+------- breaking API changes\n--                  | | +----- non-breaking API additions\n--                  | | | +--- code changes with no API change\nversion: 0.2.0.2\n-- A short (one-line) description of the package.\nsynopsis: Library for building Model Context Protocol (MCP) servers\n-- A longer description of the package.\ndescription:\n  A fully featured library for building MCP (Model Context Protocol) servers.\n  Supports both low-level fine-grained handling and high-level derived interfaces\n  for prompts, resources, and tools. Includes JSON-RPC transport\n  and stdin/stdout communication.\n\n-- The license under which the package is released.\nlicense: BSD-3-Clause\n-- The file containing the license text.\nlicense-file: LICENSE\n-- The package author(s).\nauthor: Tom Wells\n-- An email address to which users can send suggestions, bug reports, and patches.\nmaintainer: drshade@gmail.com\n-- A copyright notice.\ncopyright: 2025 Tom Wells\n-- URL for the project homepage or repository\nhomepage: https://github.com/drshade/haskell-mcp-server\nbug-reports: https://github.com/drshade/haskell-mcp-server/issues\n-- Package categories for Hackage browsing\ncategory: Network, Server, Service, MCP, JSON-RPC\nbuild-type: Simple\n-- Extra doc files to be distributed with the package, such as a CHANGELOG or a README.\nextra-doc-files:\n  CHANGELOG.md\n  README.md\ntested-with: GHC == 9.6.7\n              || == 9.8.4\n              || == 9.10.3\n              || == 9.12.2\n              || == 9.14.1\n\n-- Extra source files to be distributed with the package, such as examples, or a tutorial module.\nextra-source-files:\n  test/golden/README.md\n  test/golden/manifest.json\n  test/golden/legacy/*.json\n  test/golden/modern/*.json\n-- Source repository information\nsource-repository head\n  type: git\n  location: https://github.com/drshade/haskell-mcp-server.git\n\ncommon warnings\n  ghc-options: -Wall -Wunused-packages\n\nlibrary\n  -- Import common warning flags.\n  import: warnings\n  -- Modules exported by the library.\n  exposed-modules:\n    MCP.Server\n    MCP.Server.Derive\n    MCP.Server.Handlers\n    MCP.Server.JsonRpc\n    MCP.Server.Notifications\n    MCP.Server.Protocol\n    MCP.Server.Transport.Http\n    MCP.Server.Transport.Stdio\n    MCP.Server.Types\n\n  other-modules:\n    MCP.Server.Derive.Internal\n\n  -- Modules included in this library but not exported.\n  -- other-modules:\n  -- LANGUAGE extensions used by modules in this package.\n  -- other-extensions:\n  -- Other library packages from which modules are imported.\n  build-depends:\n    aeson >=2 && <3,\n    async >=2.2 && <2.3,\n    base >=4.18 && <4.23,\n    base64-bytestring >=1.0 && <1.3,\n    bytestring >=0.10 && <0.13,\n    containers >=0.6 && <0.9,\n    http-types >=0.12 && <1,\n    network-uri >=2.6 && <2.8,\n    scientific >=0.3 && <0.4,\n    stm >=2.5 && <2.6,\n    template-haskell >=2.16 && <2.25,\n    text >=1.2 && <3,\n    wai >=3.2 && <4,\n    warp >=3.3 && <4,\n\n  -- Directories containing source files.\n  hs-source-dirs: src\n  -- Base language which the package is written in.\n  default-language: GHC2021\n\nexecutable simple-example\n  -- Import common warning flags.\n  import: warnings\n  -- .hs or .lhs file containing the Main module.\n  main-is: Main.hs\n  -- Modules included in this executable, other than Main.\n  other-modules: Types\n  -- LANGUAGE extensions used by modules in this package.\n  -- other-extensions:\n  -- Other library packages from which modules are imported.\n  build-depends:\n    base,\n    mcp-server,\n    text,\n\n  -- Directories containing source files.\n  hs-source-dirs: examples/Simple\n  -- Base language which the package is written in.\n  default-language: GHC2021\n\nexecutable complete-example\n  -- Import common warning flags.\n  import: warnings\n  -- .hs or .lhs file containing the Main module.\n  main-is: Main.hs\n  -- Modules included in this executable, other than Main.\n  other-modules: Types\n  -- LANGUAGE extensions used by modules in this package.\n  -- other-extensions:\n  -- Other library packages from which modules are imported.\n  build-depends:\n    base,\n    containers,\n    mcp-server,\n    text,\n\n  -- Directories containing source files.\n  hs-source-dirs: examples/Complete\n  -- Base language which the package is written in.\n  default-language: GHC2021\n\nexecutable http-simple-example\n  -- Import common warning flags.\n  import: warnings\n  -- .hs or .lhs file containing the Main module.\n  main-is: Main.hs\n  -- Modules included in this executable, other than Main.\n  other-modules: Types\n  -- LANGUAGE extensions used by modules in this package.\n  -- other-extensions:\n  -- Other library packages from which modules are imported.\n  build-depends:\n    base,\n    mcp-server,\n    text,\n\n  -- Directories containing source files.\n  hs-source-dirs: examples/HttpSimple\n  -- Warp requires the threaded RTS (its timeout manager needs it).\n  ghc-options: -threaded\n  -- Base language which the package is written in.\n  default-language: GHC2021\n\ntest-suite haskell-mcp-server-test\n  -- Import common warning flags.\n  import: warnings\n  -- Base language which the package is written in.\n  default-language: GHC2021\n  -- Modules included in this executable, other than Main.\n  other-modules:\n    Spec.AdvancedDerivation\n    Spec.BasicDerivation\n    Spec.Cancellation\n    Spec.DefinitionMetadata\n    Spec.DerivedOutput\n    Spec.GoldenWire\n    Spec.HandlerExceptions\n    Spec.HttpTransport\n    Spec.JSONConversion\n    Spec.ModernEra\n    Spec.Progress\n    Spec.ProtocolVersionNegotiation\n    Spec.SchemaValidation\n    Spec.Subscriptions\n    Spec.TemplatesCompletions\n    Spec.ToolCallParsing\n    Spec.TypedArgs\n    Spec.UnicodeHandling\n    TestData\n    TestHelpers\n    TestTypes\n\n  -- LANGUAGE extensions used by modules in this package.\n  -- other-extensions:\n  -- The interface type and version of the test suite.\n  type: exitcode-stdio-1.0\n  -- Directories containing source files.\n  hs-source-dirs: test\n  -- The entrypoint to the test suite.\n  main-is: HspecMain.hs\n  -- Test dependencies.\n  build-depends:\n    QuickCheck,\n    aeson,\n    async,\n    base,\n    bytestring,\n    containers,\n    directory,\n    hspec,\n    http-types,\n    mcp-server,\n    network-uri,\n    stm,\n    text,\n    wai,\n";
  }