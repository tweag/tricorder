let
  inherit (import ../nix/package/dependencies.nix) constraints depList;
  common = import ../nix/package/common.nix;
in
{
  name = "atelier-db";
  version = "0.3.0.0";
  synopsis = "Relational database effect for atelier (Hasql/Rel8)";
  description = "Relational database access via Hasql and Rel8, exposed as an Effectful effect — part of the atelier toolkit.";
  github = "tweag/tricorder";
  category = "Database";
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
      "atelier-monitoring"
      "atelier-prelude"
      "bytestring"
      "containers"
      "data-default"
      "effectful"
      "effectful-th"
      "hasql"
      "hasql-pool"
      "hasql-transaction"
      "rel8"
      "text"
      "time"
    ];
  };
}
