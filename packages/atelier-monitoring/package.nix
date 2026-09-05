let
  inherit (import ../../nix/package/dependencies.nix) depList constraints;
  common = import ../../nix/package/common.nix;
in
{
  name = "atelier-monitoring";
  version = "0.1.0.0";
  synopsis = "Effectful-based monitoring suite";
  description = ''
    Moitoring, metrics, and tracing effects and utilities for Effectful-based
    applications —  part of the atelier toolkit.
  '';
  github = "tweag/tricorder";
  category = [
    "OpenTelemetry"
    "Observability"
    "Monitoring"
    "Tracing"
  ];

  extra-doc-files = [
    "CHANGELOG.md"
    "README.md"
  ];

  inherit (common)
    author
    maintainer
    license
    license-file
    language
    default-extensions
    tested-with
    ;

  inherit (common.options)
    ghc-options
    when
    ;

  dependencies = depList [
    "effectful-core"
    "effectful-plugin"
  ];

  library = {
    source-dirs = "src";
    dependencies = [
      {
        name = "base";
        version = constraints.base;
        mixin = [ "hiding (Prelude)" ];
      }
    ]
    ++ depList [
      "aeson"
      "atelier-core"
      "atelier-prelude"
      "base64-bytestring"
      "bytestring"
      "casing"
      "containers"
      "daemons"
      "data-default"
      "directory"
      "effectful"
      "effectful-th"
      "filepath"
      "fsnotify"
      "hs-opentelemetry-api"
      "hs-opentelemetry-sdk"
      "http-api-data"
      "http-types"
      "ki"
      "list-t"
      "optparse-applicative"
      "process"
      "prometheus-client"
      "prometheus-metrics-ghc"
      "stm"
      "stm-containers"
      "text"
      "time"
      "time-units"
      "typed-process"
      "unagi-chan"
      "unix"
      "unordered-containers"
      "uuid"
      "wai"
      "warp"
    ];
  };

  tests = {
    atelier-monitoring-test = {
      main = "Driver.hs";
      source-dirs = "test";
      ghc-options = [ "-Wno-prepositive-qualified-module" ];
      build-tools = [ "tasty-discover:tasty-discover" ];
      dependencies = [
        {
          name = "base";
          version = constraints.base;
          mixin = [
            "hiding (Prelude)"
          ];
        }
      ]
      ++ depList [
        "aeson"
        "atelier-monitoring"
        "atelier-prelude"
        "bytestring"
        "containers"
        "data-default"
        "effectful"
        "hedgehog"
        "hs-opentelemetry-api"
        "hspec"
        "hspec-hedgehog"
        "stm"
        "stm-containers"
        "tasty"
        "tasty-hspec"
        "time"
      ];
    };
  };
}
