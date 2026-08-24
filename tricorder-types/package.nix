let
  inherit (import ../nix/package/dependencies.nix) depList constraints;
  common = import ../nix/package/common.nix;
in
{
  name = "tricorder-types";
  version = "0.0.0.0";
  synopsis = "Shared domain types for various Tricorder components";
  description = ''
    Shared domain types for various Tricorder components
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
      "atelier-prelude"
      "text"
    ];
  };
}
