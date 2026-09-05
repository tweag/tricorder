let
  inherit (import ../../nix/package/dependencies.nix) constraints depList;
  common = import ../../nix/package/common.nix;
in
{
  name = "tricorder-mcp";
  version = "0.1.1.0";
  synopsis = "MCP server for Tricorder";
  description = ''
    Model Context Protocol server for Tricorder.
  '';
  github = "tweag/tricorder";
  category = [
    "AI"
    "Development"
  ];
  extra-doc-files = [
    "README.md"
    "CHANGELOG.md"
  ];

  inherit (common)
    author
    maintainer
    license
    license-file
    language
    default-extensions
    ;

  inherit (common.options)
    ghc-options
    when
    ;

  dependencies = depList [
    "effectful-core"
    "effectful-plugin"
  ];
  internal-libraries = {
    tricorder-mcp-internal = {
      source-dirs = "src";
      dependencies = [
        {
          name = "base";
          version = constraints.base;
          mixin = [ "hiding (Prelude)" ];
        }
      ]
      ++ depList [
        "atelier-core"
        "atelier-prelude"
        "bytestring"
        "directory"
        "mcp-server"
        "process"
        "tricorder-types"
        "typed-process"
        "unix"
      ];
    };
  };
  executables = {
    tricorder-mcp = {
      main = "Main.hs";
      source-dirs = "app";
      ghc-options = [ "\"-with-rtsopts=-N -T\"" ];
      dependencies = [
        {
          name = "base";
          version = constraints.base;
          mixin = [ "hiding (Prelude)" ];
        }
      ]
      ++ [ "tricorder-mcp-internal" ]
      ++ depList [ "atelier-prelude" ];
    };
  };
  tests = {
    tricorder-mcp-test = {
      main = "Driver.hs";
      source-dirs = "test";
      ghc-options = [ "-Wno-prepositive-qualified-module" ];
      build-tools = [ "tasty-discover:tasty-discover" ];
      dependencies = [
        {
          name = "base";
          version = constraints.base;
          mixin = [ "hiding (Prelude)" ];
        }
      ]
      ++ [ "tricorder-mcp-internal" ]
      ++ depList [
        "atelier-core"
        "atelier-prelude"
        "hspec"
        "tasty"
        "tasty-hspec"
      ];
    };
  };
}
