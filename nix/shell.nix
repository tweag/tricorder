{
  perSystem =
    { pkgs, config, ... }:
    let
      common = import ./package/common.nix;
    in
    {
      devShells.default = config.legacyPackages.project.shellFor {
        name = "tricorder-shell";

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
          haskell-language-server = {
            version = "latest";
            cabalProjectLocal = ''
              allow-newer:
                base,
                containers
            '';
          };
          hlint = {
            version = "latest";
            cabalProjectLocal = ''
              allow-newer: base
            '';
          };
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
