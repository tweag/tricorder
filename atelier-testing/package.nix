let
  inherit (import ../nix/package/dependencies.nix) constraints depList;
  common = import ../nix/package/common.nix;
in
{
  name = "atelier-testing";
  version = "0.2.0.0";
  synopsis = "Database-backed test utilities for atelier";
  description = "Test utilities for database-backed tests using tmp-postgres — part of the atelier toolkit.";
  github = "tweag/tricorder";
  category = "Testing";
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
      "atelier-prelude"
      "atelier-core"
      "atelier-db"
      "hasql"
      "hasql-pool"
      "hspec"
      "postgres-options"
      "text"
      "tmp-postgres"
      "unix"
      "uuid"
    ];
  };
}
