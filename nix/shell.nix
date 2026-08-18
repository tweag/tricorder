{
  pkgs,
  project,
  gitHooks,
  tools,
}:
let
  inherit (project.args) compiler-nix-name;
  common = import ./package/common.nix;

  # System tools not tied to GHC version
  systemTools =
    builtins.attrValues tools
    ++ (with pkgs; [
      nixfmt
      postgresql
      pre-commit
      tagref
    ]);
in
project.shellFor {
  name = "tricorder-shell-${compiler-nix-name}";

  # Include local packages. All first-party packages must be listed so the
  # shell prebuilds the union of their dependency closures into the package db.
  # Listing only tricorder leaves out deps unique to atelier-db (rel8,
  # tmp-postgres) and atelier-testing (hedgehog, hspec-hedgehog), forcing
  # `cabal build all` to compile them from source.
  packages = ps: map (p: ps.${p}) common.packageNames;

  # Enable Hoogle documentation
  withHoogle = true;

  buildInputs = systemTools;

  tools = {
    cabal = "latest";
    haskell-language-server = "latest";
    ghcid = "latest";
    tasty-discover = "latest";
    weeder = "latest";
  };

  shellHook = ''
    # Git hooks integration
    ${gitHooks.shellHook}
  '';
}
