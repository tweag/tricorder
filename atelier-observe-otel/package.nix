let
  inherit (import ../nix/package/dependencies.nix) depList constraints;
  common = import ../nix/package/common.nix;
in
{
  name = "atelier-observe-otel";
  version = "0.1.0.0";
  synopsis = "OpenTelemetry exporter for atelier-observe";
  description = "Fold an atelier-observe Moment stream into OpenTelemetry spans: a Consumer that turns instrumented runs into traces, with signals as attributes, failures as error status, and links between traces. Part of the atelier toolkit.";
  github = "atelier-hub/tricorder";
  homepage = "https://github.com/atelier-hub/tricorder/tree/main/atelier-observe-otel";
  category = "Control";

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
      "atelier-prelude"
      "atelier-observe"
      "containers"
      "effectful"
      "hs-opentelemetry-api"
      "hs-opentelemetry-exporter-otlp"
      "hs-opentelemetry-sdk"
      "text"
      "unordered-containers"
    ];
  };

  tests = {
    atelier-observe-otel-test = {
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
      ++ depList [
        "atelier-prelude"
        "atelier-observe"
        "atelier-observe-otel"
        "async"
        "effectful"
        "hs-opentelemetry-api"
        "hspec"
        "tasty"
        "tasty-discover"
        "tasty-hspec"
        "text"
        "unordered-containers"
      ];
    };
  };
}
