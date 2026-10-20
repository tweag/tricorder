let
  inherit (import ../../nix/package/dependencies.nix) depList constraints;
  common = import ../../nix/package/common.nix;
in
{
  name = "tricorder-types";
  version = "0.5.0.0";
  synopsis = "Shared domain types for various Tricorder components";
  description = ''
    Shared domain types for various Tricorder components like
    [Tricorder itself](https://hackage.haskell.org/package/tricorder) and
    [tricorder-mcp](https://hackage.haskell.org/package/tricorder-mcp).
  '';
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
    tested-with
    ;

  inherit (common.options)
    when
    ;
  ghc-options = common.options.warnings;

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
      "atelier-prelude"
      "megaparsec"
      "optparse-applicative"
      "text"
      "yaml"
    ];
  };
  tests.tricorder-types-test = {
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
    ++ [ "tricorder-types" ]
    ++ depList [
      "aeson"
      "atelier-core"
      "atelier-prelude"
      "tasty"
      "tasty-discover"
      "tasty-hunit"
      "text"
    ];
  };
}
