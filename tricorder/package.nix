let
  inherit (import ../nix/package/dependencies.nix) constraints depList;
  common = import ../nix/package/common.nix;
in
{
  name = "tricorder";
  version = "0.2.2.0";
  synopsis = "Continuous Haskell build status, diagnostics, and tests via a shared daemon";
  description = "tricorder rebuilds your Haskell project continuously and surfaces build status, diagnostics, test results, and documentation - for developers and LLM coding agents. Like ghcid and ghciwatch it reloads on every change, but builds run in a background daemon so multiple clients (an interactive TUI, a status CLI, an agent skill) share a single build state without triggering redundant rebuilds. It discovers components across multi-package cabal.project workspaces automatically and ships context-friendly output for agentic use via the CLI.";
  github = "tweag/tricorder";
  category = "Development";
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
    tricorder-internal = {
      source-dirs = "src";
      dependencies = [
        {
          name = "base";
          version = constraints.base;
          mixin = [ "hiding (Prelude)" ];
        }
      ]
      ++ depList [
        "Cabal"
        "Cabal-syntax"
        "aeson"
        "atelier-core"
        "atelier-prelude"
        "brick"
        "bytestring"
        "casing"
        "containers"
        "data-default"
        "directory"
        "effectful"
        "effectful-th"
        "filepath"
        "hashable"
        "megaparsec"
        "mtl"
        "network"
        "optparse-applicative"
        "process"
        "regex-tdfa"
        "relude"
        "req"
        "stm"
        "tar"
        "template-haskell"
        "text"
        "time"
        "time-units"
        "tricorder-types"
        "vty"
        "vty-crossplatform"
        "yaml"
        "zlib"
      ];
    };
  };
  executables = {
    tricorder = {
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
      ++ [ "tricorder-internal" ]
      ++ depList [ "atelier-prelude" ];
    };
    tricorder-daemon = {
      main = "Main.hs";
      source-dirs = "daemon";
      ghc-options = [ "\"-with-rtsopts=-N -T\"" ];
      dependencies = [
        {
          name = "base";
          version = constraints.base;
          mixin = [ "hiding (Prelude)" ];
        }
      ]
      ++ [ "tricorder-internal" ]
      ++ depList [ "atelier-prelude" ];
    };
  };
  tests = {
    tricorder-test = {
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
      ++ [ "tricorder-internal" ]
      ++ depList [
        "Cabal-syntax"
        "aeson"
        "atelier-core"
        "atelier-prelude"
        "bytestring"
        "containers"
        "data-default"
        "effectful"
        "filepath"
        "hspec"
        "megaparsec"
        "process"
        "regex-tdfa"
        "stm"
        "tar"
        "tasty"
        "tasty-discover"
        "tasty-hspec"
        "text"
        "time"
        "time-units"
        "tricorder-types"
        "typed-process"
        "unagi-chan"
        "unix"
        "zlib"
      ];
    };
  };
}
