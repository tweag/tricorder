{
  perSystem =
    { pkgs, config, ... }:
    let
      common = import ./package/common.nix;
    in
    {
      devShells.default = config.legacyPackages.project.shellFor {
        name = "tricorder-shell";

        # Include local packages. All first-party packages must be listed so the
        # shell prebuilds the union of their dependency closures into the package db.
        # Listing only tricorder leaves out deps unique to atelier-db (rel8,
        # tmp-postgres) and atelier-testing (hedgehog, hspec-hedgehog), forcing
        # `cabal build all` to compile them from source.
        packages = ps: map (p: ps.${p}) common.packageNames;

        # Enable Hoogle documentation
        withHoogle = true;

        inputsFrom = [ config.pre-commit.devShell ];

        buildInputs = [
          config.packages.nix-hpack
          pkgs.nixfmt
          pkgs.tagref
        ];

        tools = {
          cabal = "latest";
          fourmolu = "latest";
          ghcid = "latest";
          haskell-language-server = "latest";
          hlint = "latest";
          tasty-discover = "latest";
          weeder = "latest";
        };

        shellHook = ''
          # Git hooks integration
          ${config.pre-commit.devShell.shellHook}
        '';
      };
    };
}
