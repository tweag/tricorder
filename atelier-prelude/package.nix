let
  inherit (import ../nix/package/dependencies.nix) depList;
  common = import ../nix/package/common.nix;
in
{
  name = "atelier-prelude";
  version = "0.2.0.0";
  synopsis = "Custom relude-based prelude with Effectful conventions";
  description = "A custom prelude based on relude, adapted for Effectful — part of the atelier toolkit.";
  github = "tweag/tricorder";
  homepage = "https://github.com/tweag/tricorder/tree/main/atelier-prelude";
  category = "Prelude";
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

  ghc-options = common.options.warnings;
  inherit (common.options) when;

  library = {
    source-dirs = "src";
    dependencies = depList [
      "base"
      "effectful-core"
      "relude"
    ];
  };
}
