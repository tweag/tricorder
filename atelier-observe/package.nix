let
  inherit (import ../nix/package/dependencies.nix) depList constraints;
  common = import ../nix/package/common.nix;
in
{
  name = "atelier-observe";
  version = "0.1.0.0";
  synopsis = "Side-channel observation of oblivious Effectful programs";
  description = "Instrument an oblivious Effectful program with Taps, discharge it into a Moment stream, and fold that stream with a Consumer — separating program-side instrumentation from the summary policy. Part of the atelier toolkit.";
  github = "atelier-hub/tricorder";
  homepage = "https://github.com/atelier-hub/tricorder/tree/main/atelier-observe";
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
      "comonad"
      "effectful"
      "effectful-th"
      "foldl"
      "monoidal-containers"
    ];
  };

  tests = {
    atelier-observe-test = {
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
        "containers"
        "effectful"
        "hspec"
        "monoidal-containers"
        "tasty"
        "tasty-discover"
        "tasty-hspec"
        "text"
      ];
    };
  };
}
